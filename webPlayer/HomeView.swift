//
//  HomeView.swift
//  webPlayer
//
import SwiftUI

struct HomeView: View {
    // State for the view's data
    @State private var homeData: HomeData?
    @State private var searchResults: [Anime] = []
    
    // State for the UI
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Our single API service instance
    private let apiService = APIService()
    
    var body: some View {
        NavigationStack {
            VStack {
                // If the user is not searching, show the home screen
                if searchText.isEmpty {
                    homeScreenContent
                } else {
                    // Otherwise, show the search results
                    searchResultsList
                }
            }
            .navigationTitle("webPlayer")
            .searchable(text: $searchText, prompt: "Search for an anime...")
            .onChange(of: searchText) { newQuery in
                Task {
                    if !newQuery.isEmpty {
                        do {
                            searchResults = try await apiService.searchAnime(query: newQuery)
                        } catch {
                            print("Search error: \(error.localizedDescription)")
                        }
                    } else {
                        searchResults = []
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var homeScreenContent: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding(.top, 50)
            } else if let homeData = homeData {
                VStack(alignment: .leading, spacing: 24) {
                    AnimeCarouselView(title: "Trending", animes: homeData.trending)
                    AnimeCarouselView(title: "Top Airing", animes: homeData.topAiring)
                    AnimeCarouselView(title: "Most Popular", animes: homeData.mostPopular)
                    AnimeCarouselView(title: "Latest Episodes", animes: homeData.latestEpisode)
                }
            } else if let errorMessage = errorMessage {
                Text(errorMessage).padding().foregroundColor(.red)
            }
        }
        .task {
            if homeData == nil {
                await loadInitialData()
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsList: some View {
        List(searchResults) { anime in
            // Wrap the row content in a NavigationLink
            NavigationLink(destination: AnimeDetailView(anime: anime)) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: anime.poster)) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 50, height: 75)
                    .cornerRadius(6)
                    
                    Text(anime.title)
                        .font(.headline)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func loadInitialData() async {
        isLoading = true
        errorMessage = nil
        do {
            homeData = try await apiService.fetchHomePageData()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print(error)
        }
        isLoading = false
    }
}


struct AnimeCarouselView: View {
    let title: String
    let animes: [Anime]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    ForEach(animes) { anime in
                        // --- CHANGE IS HERE ---
                        // Wrap the item in a NavigationLink
                        NavigationLink(destination: AnimeDetailView(anime: anime)) {
                            VStack(alignment: .leading) {
                                AsyncImage(url: URL(string: anime.poster)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .aspectRatio(2/3, contentMode: .fit)
                                .frame(width: 140)
                                .cornerRadius(8)
                                
                                Text(anime.title)
                                    .lineLimit(2)
                                    .frame(height: 40, alignment: .top)
                            }
                            .frame(width: 140)
                        }
                        // This makes the link's text black instead of the default blue
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    HomeView()
}
