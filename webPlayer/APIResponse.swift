//
//  APIResponse.swift
//  webPlayer
//
import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
}

// MARK: - Home Screen Models
struct HomeData: Decodable {
    let spotlight: [SpotlightAnime]
    let trending: [Anime]
    let topAiring: [Anime]
    let mostPopular: [Anime]
    let mostFavorite: [Anime]
    let latestEpisode: [Anime]
}

struct SpotlightAnime: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let poster: String
    let rank: Int
    let duration: String?
    let synopsis: String?
    let episodes: EpisodeInfo
}

// MARK: - Search Models
struct SearchData: Decodable {
    let response: [Anime]
}

// MARK: - Detail Models
struct AnimeDetails: Decodable, Identifiable {
    let id: String
    let title: String
    let poster: String
    let synopsis: String?
    let type: String?
    let status: String?
    let genres: [String]?
    let episodes: EpisodeInfo
}

// MARK: - Episode & Server Models
struct Episode: Decodable, Identifiable {
    let id: String
    let title: String
}

struct ServerList: Decodable {
    let sub: [Server]
    let dub: [Server]
}

struct Server: Decodable, Hashable {
    let id: String?
    let name: String?
}

// MARK: - Stream Models
struct StreamData: Decodable {
    let file: String

    // Custom initializer to handle three inconsistent JSON formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // FORMAT 1: Check for "streamingLink" as a complex object
        if let linkObject = try? container.decode(StreamingLinkObject.self, forKey: .streamingLink) {
            self.file = linkObject.link.file
        // FORMAT 2: Check for "streamingLink" as a simple string
        } else if let linkString = try? container.decode(String.self, forKey: .streamingLink) {
            self.file = linkString
        // FORMAT 3: Check for the "link" object directly (the new format we just found)
        } else if let directLinkObject = try? container.decode(VideoLinkObject.self, forKey: .link) {
            self.file = directLinkObject.file
        } else {
            // If none of the known formats work, then the data is truly corrupted
            throw DecodingError.dataCorruptedError(forKey: .streamingLink, in: container, debugDescription: "Could not find a valid link in any known format.")
        }
    }

    // These private helpers are needed for the custom decoder to work
    private enum CodingKeys: String, CodingKey {
        case streamingLink
        case link // Added for the new format
    }
    
    private struct StreamingLinkObject: Decodable {
        let link: VideoLinkObject
    }

    private struct VideoLinkObject: Decodable {
        let file: String
    }
}

// MARK: - Generic Reusable Models
struct Anime: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let poster: String
    let rank: Int?
    let episodes: EpisodeInfo?
}

struct EpisodeInfo: Decodable, Hashable {
    let sub: Int?
    let dub: Int?
}
