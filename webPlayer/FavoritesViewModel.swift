//
//  FavoritesViewModel.swift
//  webPlayer
//


import Foundation
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteAnimes: [AnimeDetails] = []
    @Published var isLoading = false
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // This listens for any changes in the FavoritesManager
        FavoritesManager.shared.$favoriteIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchFavorites()
            }
            .store(in: &cancellables)
    }
    
    func fetchFavorites() {
        isLoading = true
        let ids = FavoritesManager.shared.favoriteIDs
        
        // If there are no favorite IDs, don't do anything.
        guard !ids.isEmpty else {
            self.favoriteAnimes = []
            self.isLoading = false
            return
        }
        
        Task {
            // Create a temporary array to hold the results
            var detailsList: [AnimeDetails] = []
            
            // Loop through each saved ID and fetch its details
            for id in ids {
                do {
                    let details = try await apiService.fetchAnimeDetails(id: id)
                    detailsList.append(details)
                } catch {
                    print("Failed to fetch details for favorite ID \(id): \(error)")
                }
            }
            
            // Update the main array once all fetches are complete
            self.favoriteAnimes = detailsList
            self.isLoading = false
        }
    }
}
