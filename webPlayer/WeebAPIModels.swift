import Foundation

struct WeebAPISearchResult: Codable, Identifiable {
    let id: String
    let title: String
    let session: String
    let cover: String
    
    var imageURL: URL? { URL(string: cover) }

    enum CodingKeys: String, CodingKey {
        case id = "siteLink", title, session, cover
    }
}

struct WeebAPIFullData: Codable {
    let title: String
    let cover: String
    let synopsis: String
    let episodes: [String: String]
    
    var imageURL: URL? { URL(string: cover) }
}
