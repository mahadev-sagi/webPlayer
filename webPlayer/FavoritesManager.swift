import Foundation
import SwiftUI

enum WatchStatus: String, CaseIterable, Codable {
    case watching = "Watching"
    case completed = "Completed"
    case planToWatch = "Plan to Watch"
    case dropped = "Dropped"
    
    var color: Color {
        switch self {
        case .watching: return .blue
        case .completed: return .green
        case .planToWatch: return .orange
        case .dropped: return .red
        }
    }
}

struct FavoriteItem: Codable, Identifiable {
    let id: String
    let title: String
    let imageURL: String?
    let type: ContentType
    let dateAdded: Date
    var watchStatus: WatchStatus = .planToWatch
    var rating: Double?
    var notes: String?
    let malId: Int? // For anime
    let tmdbId: Int? // For movies
}

class FavoritesManager: ObservableObject {
    @Published var favorites: [FavoriteItem] = []
    private let userDefaults = UserDefaults.standard
    private let key = "UserFavorites"
    
    init() {
        loadFavorites()
    }
    
    func addFavorite(_ item: FavoriteItem) {
        if !isFavorite(id: item.id) {
            favorites.insert(item, at: 0)
            saveFavorites()
        }
    }
    
    func removeFavorite(id: String) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }
    
    func updateStatus(id: String, status: WatchStatus) {
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            favorites[index].watchStatus = status
            saveFavorites()
        }
    }
    
    func updateRating(id: String, rating: Double) {
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            favorites[index].rating = rating
            saveFavorites()
        }
    }
    
    func isFavorite(id: String) -> Bool {
        favorites.contains { $0.id == id }
    }
    
    func getFavorite(id: String) -> FavoriteItem? {
        favorites.first { $0.id == id }
    }
    
    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: key) else { return }
        do {
            let decoder = JSONDecoder()
            favorites = try decoder.decode([FavoriteItem].self, from: data)
        } catch {
            print("Failed to decode favorites: \(error)")
        }
    }
    
    private func saveFavorites() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favorites)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to encode favorites: \(error)")
        }
    }
}
