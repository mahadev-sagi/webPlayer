import Foundation

class WeebAPIService {
    static let shared = WeebAPIService()
    private let baseURL = "https://weebapi.onrender.com"
    
    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "The URL was invalid."
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
            case .invalidResponse: return "Received an invalid response from the server."
            }
        }
    }

    func search(query: String) async -> Result<[WeebAPISearchResult], APIError> {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              
              let url = URL(string: "\(baseURL)/get_search_results/\(encodedQuery)") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url)
    }
    
    func fetchDetails(for id: String) async -> Result<WeebAPIFullData, APIError> {
        guard let url = URL(string: "\(baseURL)/get_full_data/\(id)") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url)
    }
    
    private func performRequest<T: Decodable>(url: URL) async -> Result<T, APIError> {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.invalidResponse)
            }
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return .success(decodedData)
        } catch let error as DecodingError {
            return .failure(.decodingError(error))
        } catch {
            return .failure(.networkError(error))
        }
    }
}
