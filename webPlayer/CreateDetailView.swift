//
//  DetailView.swift
//  webPlayer
//
//  Created by Mahadev on 7/3/25.
//

import SwiftUI

// MARK: - Info Card Component
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 100)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DetailView: View {
    let anime: AnimeItem?
    let movie: MovieItem?
    let scrapedItem: ScrapedItem?
    
    @StateObject private var favoritesManager = FavoritesManager()
    @State private var showWebView = false
    @State private var activeURL: URL?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var isAnime: Bool { anime != nil }
    var isMovie: Bool { movie != nil }
    
    var itemId: String {
        if let anime = anime { return "anime_\(anime.mal_id)" }
        if let movie = movie { return "movie_\(movie.id)" }
        if let scraped = scrapedItem { return scraped.id.uuidString }
        return ""
    }
    
    var itemTitle: String {
        anime?.displayTitle ?? movie?.title ?? scrapedItem?.title ?? "Unknown"
    }
    
    var imageURL: URL? {
        anime?.imageURL ?? movie?.imageURL ?? scrapedItem?.imageURL
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image & Title
                headerSection
                
                // Action Buttons
                actionButtons
                
                // Info Cards
                if isAnime || isMovie {
                    infoSection
                }
                
                // Synopsis
                if let synopsis = anime?.synopsis ?? movie?.overview {
                    synopsisSection(synopsis)
                }
                
                // Watch Status (if favorited)
                if favoritesManager.isFavorite(id: itemId) {
                    watchStatusSection
                }
            }
            .padding()
        }
        .navigationTitle(itemTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showWebView) {
            if let url = activeURL {
                WebPlayerView(url: url)
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Poster Image
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(ProgressView())
            }
            .frame(width: 150, height: 225)
            .cornerRadius(12)
            .shadow(radius: 5)
            
            // Title and Basic Info
            VStack(alignment: .leading, spacing: 8) {
                Text(itemTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(3)
                
                if let score = anime?.score ?? movie?.vote_average {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", score))
                            .fontWeight(.semibold)
                    }
                }
                
                if let episodes = anime?.episodes {
                    Label("\(episodes) episodes", systemImage: "tv")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let status = anime?.status {
                    Label(status, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let releaseDate = movie?.release_date {
                    Label(releaseDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons
    var actionButtons: some View {
        HStack(spacing: 12) {
            // Favorite Button
            Button(action: toggleFavorite) {
                Label(
                    favoritesManager.isFavorite(id: itemId) ? "Favorited" : "Add to Favorites",
                    systemImage: favoritesManager.isFavorite(id: itemId) ? "heart.fill" : "heart"
                )
                .foregroundColor(favoritesManager.isFavorite(id: itemId) ? .red : .blue)
            }
            .buttonStyle(.bordered)
            
            // Watch Button
            Button(action: openInBrowser) {
                Label("Watch", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            
            // Share Button
            Button(action: shareContent) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Info Section
    var infoSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let score = anime?.score ?? movie?.vote_average {
                    InfoCard(
                        title: "Rating",
                        value: String(format: "%.1f", score),
                        icon: "star.fill",
                        color: Color.yellow
                    )
                }
                
                if let episodes = anime?.episodes {
                    InfoCard(
                        title: "Episodes",
                        value: "\(episodes)",
                        icon: "tv.fill",
                        color: Color.blue
                    )
                }
                
                if anime != nil {
                    InfoCard(
                        title: "Type",
                        value: "Anime",
                        icon: "play.tv",
                        color: Color.purple
                    )
                } else if movie != nil {
                    InfoCard(
                        title: "Type",
                        value: "Movie",
                        icon: "film",
                        color: Color.orange
                    )
                }
            }
        }
    }
    
    // MARK: - Synopsis Section
    func synopsisSection(_ synopsis: String) -> some View {
        VStack(
