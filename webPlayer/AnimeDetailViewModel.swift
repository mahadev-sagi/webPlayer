//
//  AnimeDetailViewModel.swift
//  webPlayer
//
import Foundation

@MainActor
class AnimeDetailViewModel: ObservableObject {
    @Published var details: AnimeDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService()
    
    func loadDetails(for animeID: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                details = try await apiService.fetchAnimeDetails(id: animeID)
            } catch {
                errorMessage = "Failed to load details: \(error.localizedDescription)"
                print(error)
            }
            isLoading = false
        }
    }
}
