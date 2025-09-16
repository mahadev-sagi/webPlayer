//
//  FavoritesView.swift
//  webPlayer
//


import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.favoriteAnimes.isEmpty {
                    Text("No favorites yet!")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.favoriteAnimes) { animeDetails in
                        // create a simple Anime object to pass to the detail view
                        let anime = Anime(id: animeDetails.id, title: animeDetails.title, poster: animeDetails.poster, rank: nil, episodes: animeDetails.episodes)
                        
                        NavigationLink(destination: AnimeDetailView(anime: anime)) {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: anime.poster)) { image in
                                    image.resizable()
                                } placeholder: { Color.gray.opacity(0.3) }
                                    .frame(width: 50, height: 75)
                                    .cornerRadius(6)
                                
                                Text(anime.title)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                viewModel.fetchFavorites()
            }
        }
    }
}
