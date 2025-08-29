import SwiftUI

// MARK: - Enums and Models defined for this View
enum DataSource: String, CaseIterable {
    case officialAPI = "Official API"
    case weebAPI = "AnimePahe API"
    case manualScraping = "Manual Scrape"
}

enum ContentType: String, CaseIterable, Codable {
    case anime = "Anime"
    case movies = "Movies"
}

struct ScrapedItem: Identifiable {
    let id = UUID()
    let title: String
    let imageURL: URL?
    var link: String? = nil
}

struct ContentView: View {
    // MARK: - State Properties
    @State private var animeItems: [AnimeItem] = []
    @State private var movieItems: [MovieItem] = []
    @State private var scrapedItems: [ScrapedItem] = []
    @State private var weebAPIResults: [WeebAPISearchResult] = []
    @State private var inputURL: String = ""
    @State private var searchText: String = ""
    @State private var showWebView = false
    @State private var activeURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Live Search State
    @State private var searchSuggestions: [String] = []
    @State private var debounceTask: Task<Void, Never>? = nil

    // View Models & Managers
    @StateObject private var recentManager = RecentURLsManager()
    @StateObject private var favoritesManager = FavoritesManager()
    private let apiService = APIService.shared
    
    // Toggles
    @State private var contentType: ContentType = .anime
    @State private var dataSource: DataSource = .officialAPI
    
    // MARK: - Main Body
    var body: some View {
        NavigationView {
            VStack {
                Picker("Data Source", selection: $dataSource) {
                    ForEach(DataSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: dataSource) { resetContent() }

                if dataSource == .officialAPI { apiUI }
                else if dataSource == .weebAPI { weebAPIUI }
                else { scrapingUI }
                
                if isLoading {
                    Spacer(); ProgressView(); Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        Text(error).multilineTextAlignment(.center).padding()
                    }
                    Spacer()
                } else {
                    contentList
                }
            }
            .navigationTitle("Media Browser")
            .sheet(isPresented: $showWebView) {
                if let url = activeURL { WebPlayerView(url: url) }
            }
        }
    }
    
    // MARK: - UI Components (ViewBuilders)
    @ViewBuilder
    private var apiUI: some View {
        VStack {
            Picker("Content Type", selection: $contentType) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal, .top])
            .onChange(of: contentType) { resetContent() }
            
            HStack {
                TextField("Search \(contentType.rawValue)...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit(searchOfficialAPI)
                    .onChange(of: searchText) { newValue in triggerDebouncedSearch(for: newValue) }
            }
            .padding(.horizontal)
            .overlay(alignment: .topLeading) {
                if !searchSuggestions.isEmpty {
                    suggestionList.padding(.horizontal).offset(y: 40)
                }
            }
            
            HStack {
                Button("Top \(contentType.rawValue)", action: loadTopContent)
                    .buttonStyle(.borderedProminent).disabled(isLoading)
                if contentType == .anime {
                    Button("This Season", action: loadSeasonalAnime)
                        .buttonStyle(.bordered).disabled(isLoading)
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var weebAPIUI: some View {
        VStack {
            HStack {
                TextField("Search anime on AnimePahe...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit(searchWeebAPI)
                    .onChange(of: searchText) { newValue in triggerDebouncedSearch(for: newValue) }
            }
            .padding([.horizontal, .top])
            .overlay(alignment: .topLeading) {
                if !searchSuggestions.isEmpty {
                    suggestionList.padding(.horizontal).offset(y: 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private var scrapingUI: some View {
        VStack {
            HStack {
                TextField("Enter URL to scrape...", text: $inputURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.URL).autocapitalization(.none)
                Button("Scrape", action: scrapeManualURL).disabled(inputURL.isEmpty || isLoading)
            }
            .padding([.horizontal, .top])
            Menu("Recent URLs") {
                if recentManager.recentURLs.isEmpty {
                    Text("No Recent URLs")
                } else {
                    ForEach(recentManager.recentURLs, id: \.self) { urlString in
                        Button(urlString) {
                            self.inputURL = urlString
                            scrapeManualURL()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        if dataSource == .officialAPI {
            List {
                if contentType == .anime {
                    ForEach(animeItems) { item in
                        NavigationLink(destination: DetailView(anime: item, movie: nil, favoritesManager: favoritesManager)) {
                            ListItemView(title: item.displayTitle, imageURL: item.imageURL)
                        }
                    }
                } else {
                    ForEach(movieItems) { item in
                        NavigationLink(destination: DetailView(anime: nil, movie: item, favoritesManager: favoritesManager)) {
                            ListItemView(title: item.title, imageURL: item.imageURL)
                        }
                    }
                }
            }
        } else if dataSource == .weebAPI {
            List(weebAPIResults) { item in
                NavigationLink(destination: WeebAPIDetailView(searchItem: item)) {
                    ListItemView(title: item.title, imageURL: item.imageURL)
                }
            }
        } else { // Manual Scraping
            List(scrapedItems) { item in
                Button(action: {
                    guard let linkString = item.link, let url = URL(string: linkString) else { return }
                    self.activeURL = url
                    self.showWebView = true
                }) {
                    ListItemView(title: item.title, imageURL: item.imageURL)
                }
            }
        }
    }
    
    @ViewBuilder
    private var suggestionList: some View {
        List(searchSuggestions, id: \.self) { suggestion in
            Button(action: {
                self.searchText = suggestion
                self.searchSuggestions = []
                if dataSource == .officialAPI { searchOfficialAPI() }
                else { searchWeebAPI() }
            }) { Text(suggestion) }
        }
        .listStyle(.plain)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
        .frame(height: 200)
        .zIndex(1)
    }

    // MARK: - Data Loading Functions
    private func triggerDebouncedSearch(for query: String) {
        guard !query.isEmpty else {
            searchSuggestions = []
            debounceTask?.cancel()
            return
        }
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                await performLiveSearch(for: query)
            } catch { print("Debounce task cancelled") }
        }
    }

    private func performLiveSearch(for query: String) async {
        guard self.searchText == query else { return }
        var result: [String] = []

        if dataSource == .officialAPI && contentType == .anime {
            let apiResult = await apiService.searchAnimeAsync(query: query)
            if case .success(let items) = apiResult {
                result = items.map { $0.displayTitle }.prefix(5).compactMap { $0 }
            }
        } else if dataSource == .weebAPI {
            let apiResult = await WeebAPIService.shared.search(query: query)
            if case .success(let items) = apiResult {
                result = items.map { $0.title }.prefix(5).compactMap { $0 }
            }
        }
        
        await MainActor.run {
            if self.searchText == query { self.searchSuggestions = result }
        }
    }
    
    private func searchOfficialAPI() {
        guard !searchText.isEmpty else { return }
        isLoading = true; errorMessage = nil; searchSuggestions = []
        if contentType == .anime {
            apiService.searchAnime(query: searchText) { handleAPIResult($0) }
        } else {
            apiService.searchMovies(query: searchText) { handleAPIResult($0) }
        }
    }

    private func loadTopContent() {
        isLoading = true; errorMessage = nil; searchSuggestions = []
        if contentType == .anime {
            apiService.fetchTopAnime { handleAPIResult($0) }
        } else {
            apiService.fetchPopularMovies { handleAPIResult($0) }
        }
    }
    
    private func loadSeasonalAnime() {
        isLoading = true; errorMessage = nil; searchSuggestions = []
        apiService.fetchSeasonalAnime { handleAPIResult($0) }
    }
    
    private func searchWeebAPI() {
        guard !searchText.isEmpty else { return }
        isLoading = true; errorMessage = nil; searchSuggestions = []
        
        Task {
            let result = await WeebAPIService.shared.search(query: searchText)
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let items):
                    self.weebAPIResults = items
                    if items.isEmpty { self.errorMessage = "No results found on AnimePahe." }
                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func scrapeManualURL() {
        var urlStringToScrape = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlStringToScrape.hasPrefix("http://") && !urlStringToScrape.hasPrefix("https://") {
            urlStringToScrape = "https://" + urlStringToScrape
        }
        guard let url = URL(string: urlStringToScrape) else {
            errorMessage = "Please enter a valid URL."; return
        }
        isLoading = true; errorMessage = nil
        recentManager.addURL(inputURL)
        WebScraper.scrape(url: url) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let items):
                    self.scrapedItems = items
                    if items.isEmpty { self.errorMessage = "Scraper found no items on this page." }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func resetContent() {
        animeItems = []; movieItems = []; scrapedItems = []; weebAPIResults = []; errorMessage = nil; searchText = ""; searchSuggestions = []
    }
    
    private func handleAPIResult(_ result: Result<[AnimeItem], Error>) {
        isLoading = false
        switch result {
        case .success(let items): self.animeItems = items; if items.isEmpty { self.errorMessage = "No results found." }
        case .failure(let error): self.errorMessage = error.localizedDescription
        }
    }
    
    private func handleAPIResult(_ result: Result<[MovieItem], Error>) {
        isLoading = false
        switch result {
        case .success(let items): self.movieItems = items; if items.isEmpty { self.errorMessage = "No results found." }
        case .failure(let error): self.errorMessage = error.localizedDescription
        }
    }
}

struct ListItemView: View {
    let title: String
    let imageURL: URL?
    var body: some View {
        HStack {
            AsyncImage(url: imageURL) { image in image.resizable() }
            placeholder: { Color.gray.opacity(0.3).overlay(Image(systemName: "film")) }
            .frame(width: 50, height: 75).cornerRadius(4)
            Text(title).padding(.leading, 8)
        }
    }
}
