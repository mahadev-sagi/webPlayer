//
//  PlayerView.swift
//  webPlayer
//
import SwiftUI
import AVKit

struct PlayerView: View {
    let episodeID: String
    let server: Server
    let serverType: String
    
    @State private var videoURL: URL?
    @State private var isLoading = true
    
    private let apiService = APIService()
    
    var body: some View {
        VStack {
            if let url = videoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            } else if isLoading {
                ProgressView()
            } else {
                Text("Failed to load video.")
            }
        }
        .navigationTitle(server.name ?? "Player")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Make sure we have a valid server name before fetching
            guard let serverName = server.name else {
                print("Server name is nil.")
                isLoading = false
                return
            }
            
            do {
                let urlString = try await apiService.fetchStreamingLink(
                    episodeID: episodeID,
                    serverName: serverName,
                    serverType: serverType
                )
                print("DEBUG: Attempting to load video from URL: \(urlString)")
                videoURL = URL(string: urlString)
            } catch {
                print("Failed to get stream link: \(error)")
            }
            isLoading = false
        }
    }
}
