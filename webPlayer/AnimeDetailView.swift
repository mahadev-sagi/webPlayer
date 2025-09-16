//
//  AnimeDetailView.swift
//  webPlayer
//
import SwiftUI

struct AnimeDetailView: View {
    let anime: Anime
    @StateObject private var viewModel = AnimeDetailViewModel()
    
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        ScrollView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let details = viewModel.details {
                    detailsContent(details: details)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationTitle(anime.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadDetails(for: anime.id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    favoritesManager.toggleFavorite(id: anime.id)
                }) {
                    Image(systemName: favoritesManager.isFavorite(id: anime.id) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailsContent(details: AnimeDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: URL(string: details.poster)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .aspectRatio(2/3, contentMode: .fit)
                .frame(width: 120)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(details.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let type = details.type { Text("Type: \(type)") }
                    if let status = details.status { Text("Status: \(status)") }
                    Text("Sub: \(details.episodes.sub ?? 0)")
                    Text("Dub: \(details.episodes.dub ?? 0)")
                }
            }
            
            NavigationLink(destination: EpisodeListView(animeID: details.id)) {
                Text("Watch Now")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if let synopsis = details.synopsis {
                Text("Synopsis")
                    .font(.headline)
                Text(synopsis)
                    .font(.body)
            }
        }
        .padding()
    }
}
