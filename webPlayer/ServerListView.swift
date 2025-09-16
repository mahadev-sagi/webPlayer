//
//  ServerListView.swift
//  webPlayer
//

import SwiftUI

struct ServerListView: View {
    let episodeID: String
    
    @State private var serverList: ServerList?
    @State private var isLoading = true
    
    private let apiService = APIService()
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if let servers = serverList {
                // Section for Subbed servers
                if !servers.sub.isEmpty {
                    Section(header: Text("Subbed")) {
                        ForEach(servers.sub.compactMap { $0 }, id: \.id) { server in
                            // Each server links to the PlayerView
                            NavigationLink(destination: PlayerView(episodeID: episodeID, server: server, serverType: "sub")) {
                                Text(server.name ?? "Unknown Server")
                            }
                        }
                    }
                }
                
                // Section for Dubbed servers
                if !servers.dub.isEmpty {
                    Section(header: Text("Dubbed")) {
                        ForEach(servers.dub.compactMap { $0 }, id: \.id) { server in
                            NavigationLink(destination: PlayerView(episodeID: episodeID, server: server, serverType: "dub")) {
                                Text(server.name ?? "Unknown Server")
                            }
                        }
                    }
                }
            } else {
                Text("No servers found for this episode.")
            }
        }
        .navigationTitle("Select Server")
        .task {
            do {
                serverList = try await apiService.fetchServerList(for: episodeID)
            } catch {
                print("Failed to fetch servers: \(error)")
            }
            isLoading = false
        }
    }
}
