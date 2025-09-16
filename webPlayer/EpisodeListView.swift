//
//  EpisodeListView.swift
//  webPlayer
//
import SwiftUI

struct EpisodeListView: View {
    let animeID: String
    @State private var episodes: [Episode] = []
    @State private var isLoading = true
    
    private let apiService = APIService()
    
    var body: some View {
        List(Array(episodes.enumerated()), id: \.element.id) { index, episode in
            NavigationLink(destination: ServerListView(episodeID: episode.id)) {
                Text("\(index + 1). \(episode.title)")
            }
        }
        .navigationTitle("Episodes")
        .task {
            do {
                episodes = try await apiService.fetchEpisodes(id: animeID)
            } catch {
                print("Error fetching episodes: \(error)")
            }
            isLoading = false
        }
    }
}
