//
//  APIService.swift
//  webPlayer
//
import Foundation

class APIService {
    //
    private let baseURL = "https://hi-animeapi.onrender.com/api/v1"

    // Fetches data for the home screen
    func fetchHomePageData() async throws -> HomeData {
        let urlString = "\(baseURL)/home"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(APIResponse<HomeData>.self, from: data)
        return decodedResponse.data
    }
    
    // Searches for anime based on a query
    func searchAnime(query: String) async throws -> [Anime] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        let urlString = "\(baseURL)/search?keyword=\(encodedQuery)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(APIResponse<SearchData>.self, from: data)
        return decodedResponse.data.response
    }
    
    // Fetches full details for a single anime by its ID
    func fetchAnimeDetails(id: String) async throws -> AnimeDetails {
        let urlString = "\(baseURL)/anime/\(id)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(APIResponse<AnimeDetails>.self, from: data)
        return decodedResponse.data
    }
    
    // Fetches the list of episodes for an anime
    func fetchEpisodes(id: String) async throws -> [Episode] {
        let urlString = "\(baseURL)/episodes/\(id)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(APIResponse<[Episode]>.self, from: data)
        return decodedResponse.data
    }

    // Fetches the list of available servers
    func fetchServerList(for episodeID: String) async throws -> ServerList {
        guard let encodedID = episodeID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        let urlString = "\(baseURL)/servers?id=\(encodedID)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(APIResponse<ServerList>.self, from: data).data
    }

    // Fetches the final streaming link using a specific server
    func fetchStreamingLink(episodeID: String, serverName: String, serverType: String) async throws -> String {
        guard let encodedID = episodeID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }

        let urlString = "\(baseURL)/stream?id=\(encodedID)&server=\(serverName)&type=\(serverType)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        print("DEBUG: Raw JSON from /stream: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
        let streamResponse = try JSONDecoder().decode(APIResponse<StreamData>.self, from: data)
        
        
        return streamResponse.data.file
    }
}
