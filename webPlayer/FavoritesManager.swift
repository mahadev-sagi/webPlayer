//
//  FavoritesManager.swift
//  webPlayer
//


import Foundation

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    private let favoritesKey = "animeFavorites"
    
    @Published var favoriteIDs: Set<String>
    
    private init() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        self.favoriteIDs = Set(savedIDs)
    }
    
    func isFavorite(id: String) -> Bool {
        favoriteIDs.contains(id)
    }
    
    func toggleFavorite(id: String) {
        if isFavorite(id: id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        saveFavorites()
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }
}
