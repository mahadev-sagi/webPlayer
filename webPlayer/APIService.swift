import Foundation

// MARK: - API Models (Jikan & TMDB)
struct AnimeResponse: Codable {
    let data: [AnimeItem]
}

struct AnimeItem: Codable, Identifiable {
    let mal_id: Int
    let title: String
    let title_english: String?
    let synopsis: String?
    let images: AnimeImages
    let score: Double?
    let episodes: Int?
    let status: String?
    let url: String
    
    var id: Int { mal_id }
    var displayTitle: String { title_english ?? title }
    var imageURL: URL? { URL(string: images.jpg.large_image_url) }
}

struct AnimeImages: Codable {
    let jpg: JPGImages
}

struct JPGImages: Codable {
    let large_image_url: String
}

struct MovieResponse: Codable {
    let results: [MovieItem]
}

struct MovieItem: Codable, Identifiable {
    let id: Int
    let title: String
    let overview: String?
    let poster_path: String?
    let vote_average: Double
    let release_date: String?
    
    var imageURL: URL? {
        guard let poster_path = poster_path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(poster_path)")
    }
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    private init() {}
    
    private let session = URLSession.shared
    private let jikanBaseURL = "https://api.jikan.moe/v4"
    private let tmdbBaseURL = "https://api.themoviedb.org/3"
    private let tmdbAPIKey = "YOUR_TMDB_API_KEY" // REMINDER: Put your key here

    // MARK: - Anime Functions
    func fetchTopAnime(completion: @escaping (Result<[AnimeItem], Error>) -> Void) {
        let url = URL(string: "\(jikanBaseURL)/top/anime")!
        performRequest(url: url, responseType: AnimeResponse.self) { result in
            switch result {
            case .success(let response): completion(.success(response.data))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func searchAnime(query: String, completion: @escaping (Result<[AnimeItem], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(jikanBaseURL)/anime?q=\(encodedQuery)") else {
            completion(.failure(APIError.invalidURL)); return
        }
        performRequest(url: url, responseType: AnimeResponse.self) { result in
            switch result {
            case .success(let response): completion(.success(response.data))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func fetchSeasonalAnime(completion: @escaping (Result<[AnimeItem], Error>) -> Void) {
        let url = URL(string: "\(jikanBaseURL)/seasons/now")!
        performRequest(url: url, responseType: AnimeResponse.self) { result in
            switch result {
            case .success(let response): completion(.success(response.data))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    // MARK: - Movie Functions
    func fetchPopularMovies(completion: @escaping (Result<[MovieItem], Error>) -> Void) {
        let url = URL(string: "\(tmdbBaseURL)/movie/popular?api_key=\(tmdbAPIKey)")!
        performRequest(url: url, responseType: MovieResponse.self) { result in
            switch result {
            case .success(let response): completion(.success(response.results))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func searchMovies(query: String, completion: @escaping (Result<[MovieItem], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(tmdbBaseURL)/search/movie?api_key=\(tmdbAPIKey)&query=\(encodedQuery)") else {
            completion(.failure(APIError.invalidURL)); return
        }
        performRequest(url: url, responseType: MovieResponse.self) { result in
            switch result {
            case .success(let response): completion(.success(response.results))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    // MARK: - Async Function for Live Search
    func searchAnimeAsync(query: String) async -> Result<[AnimeItem], Error> {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(jikanBaseURL)/anime?q=\(encodedQuery)") else {
            return .failure(APIError.invalidURL)
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(AnimeResponse.self, from: data)
            return .success(response.data)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Generic Request Handler
    private func performRequest<T: Codable>(url: URL, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let decodedResponse = try JSONDecoder().decode(responseType, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    completion(.failure(APIError.decodingError(error)))
                }
            }
        }.resume()
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    
    // ✅ THIS IS THE CORRECTED IMPLEMENTATION
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .noData:
            return "No data was received from the server."
        case .decodingError(let error):
            return "Failed to decode the server response: \(error.localizedDescription)"
        }
    }
}
