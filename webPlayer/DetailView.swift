import SwiftUI

struct DetailView: View {
    // Item Data (only one will be non-nil)
    let anime: AnimeItem?
    let movie: MovieItem?
    
    // CRITICAL FIX: Use @ObservedObject to receive the shared manager from ContentView
    @ObservedObject var favoritesManager: FavoritesManager
    
    @State private var showWebView = false
    @State private var activeURL: URL?
    
    // MARK: - Computed Properties
    var isApiItem: Bool { anime != nil || movie != nil }
    
    var itemId: String {
        if let anime = anime { return "anime_\(anime.mal_id)" }
        if let movie = movie { return "movie_\(movie.id)" }
        return ""
    }
    
    var itemTitle: String { anime?.displayTitle ?? movie?.title ?? "Unknown" }
    var imageURL: URL? { anime?.imageURL ?? movie?.imageURL }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                actionButtons
                infoSection
                
                if let synopsis = anime?.synopsis ?? movie?.overview, !synopsis.isEmpty {
                    synopsisSection(synopsis)
                }
                
                if favoritesManager.isFavorite(id: itemId) {
                    watchStatusSection
                }
            }
            .padding()
        }
        .navigationTitle(itemTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWebView) {
            if let url = activeURL { WebPlayerView(url: url) }
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: imageURL) { image in image.resizable().aspectRatio(contentMode: .fit) }
            placeholder: { RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).overlay(ProgressView()) }
            .frame(width: 150, height: 225).cornerRadius(12).shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(itemTitle).font(.title2).fontWeight(.bold).lineLimit(3)
                if let score = anime?.score ?? movie?.vote_average {
                    Label(String(format: "%.1f", score), systemImage: "star.fill").foregroundColor(.yellow)
                }
                if let episodes = anime?.episodes {
                    Label("\(episodes) episodes", systemImage: "tv").font(.caption).foregroundColor(.secondary)
                }
                if let status = anime?.status {
                    Label(status, systemImage: "info.circle").font(.caption).foregroundColor(.secondary)
                }
                if let releaseDate = movie?.release_date {
                    Label(releaseDate, systemImage: "calendar").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: toggleFavorite) {
                Label(
                    favoritesManager.isFavorite(id: itemId) ? "Favorited" : "Add to Favorites",
                    systemImage: favoritesManager.isFavorite(id: itemId) ? "heart.fill" : "heart"
                )
                .foregroundColor(favoritesManager.isFavorite(id: itemId) ? .red : .accentColor)
            }
            .buttonStyle(.bordered).animation(.spring(), value: favoritesManager.isFavorite(id: itemId))
            
            // This button's action would ideally search for streams.
            // For now, it can open the official page if available.
            Button(action: {
                if let urlString = anime?.url, let url = URL(string: urlString) {
                    activeURL = url
                    showWebView = true
                }
            }) { Label("Watch", systemImage: "play.tv") }
            .buttonStyle(.borderedProminent)
            .disabled(anime?.url == nil)
            
            Spacer()
        }
    }
    
    private var infoSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let score = anime?.score ?? movie?.vote_average {
                    InfoCard(title: "Score", value: String(format: "%.1f", score), icon: "star.fill", color: .yellow)
                }
                if let episodes = anime?.episodes {
                    InfoCard(title: "Episodes", value: "\(episodes)", icon: "tv", color: .blue)
                }
                if let type = anime != nil ? "Anime" : "Movie" {
                    InfoCard(title: "Type", value: type, icon: "film", color: .purple)
                }
                if let status = anime?.status {
                    InfoCard(title: "Status", value: status, icon: "info.circle", color: .cyan)
                }
            }
        }
    }
    
    private func synopsisSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis").font(.headline)
            Text(text).font(.body).foregroundColor(.secondary)
        }
    }
    
    private var watchStatusSection: some View {
        VStack(alignment: .leading) {
            Text("My Status").font(.headline)
            Picker("Status", selection: Binding(
                get: { favoritesManager.getFavorite(id: itemId)?.watchStatus ?? .planToWatch },
                set: { newStatus in favoritesManager.updateStatus(id: itemId, status: newStatus) }
            )) {
                ForEach(WatchStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    // MARK: - Functions
    private func toggleFavorite() {
        if favoritesManager.isFavorite(id: itemId) {
            favoritesManager.removeFavorite(id: itemId)
        } else {
            // Create a new FavoriteItem and add it
            let newItem: FavoriteItem
            let type: ContentType = anime != nil ? .anime : .movies
            
            newItem = FavoriteItem(
                id: itemId,
                title: itemTitle,
                imageURL: imageURL?.absoluteString,
                type: type,
                dateAdded: Date(),
                malId: anime?.mal_id,
                tmdbId: movie?.id
            )
            favoritesManager.addFavorite(newItem)
        }
    }
}

struct InfoCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.headline).fontWeight(.bold)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(width: 100, height: 100)
        .background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
}
