//
//  WebScraper.swift
//  webPlayer
//
//  Created by Mahadev on 7/3/25.
//

import Foundation
import SwiftSoup

enum ScraperError: LocalizedError {
    case invalidURL
    case noData
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}

class WebScraper {
    static func scrape(url: URL, completion: @escaping (Result<[ScrapedItem], Error>) -> Void) {
        print("🔍 Starting scrape for: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(ScraperError.noData))
                return
            }
            
            print("📦 Received data: \(data.count) bytes")
            
            guard let html = String(data: data, encoding: .utf8) else {
                print("❌ Failed to decode HTML")
                completion(.failure(ScraperError.parsingError("Failed to decode HTML")))
                return
            }
            
            do {
                let document = try SwiftSoup.parse(html)
                let items = try scrapeForHost(url: url, document: document)
                print("✅ Scraped \(items.count) items")
                completion(.success(items))
            } catch {
                print("❌ Parsing error: \(error)")
                completion(.failure(ScraperError.parsingError(error.localizedDescription)))
            }
        }.resume()
    }
    
    private static func scrapeForHost(url: URL, document: Document) throws -> [ScrapedItem] {
        let host = url.host ?? ""
        print("🌐 Scraping for host: \(host)")
        
        if host.contains("animepahe") {
            return try scrapeAnimepahe(document, baseURL: url)
        } else if host.contains("hurawatch") {
            return try scrapeHurawatch(document, baseURL: url)
        } else {
            return try scrapeGeneric(document)
        }
    }
    
    private static func scrapeAnimepahe(_ document: Document, baseURL: URL) throws -> [ScrapedItem] {
        print("🎌 Using Animepahe scraper")
        var items: [ScrapedItem] = []
        
        // For the main page, look for anime cards
        let animeCards = try document.select("div.tab-content div.col-12.col-md-6")
        print("🔍 Found \(animeCards.count) anime cards")
        
        for card in animeCards {
            // Get title
            let titleElement = try? card.select("h3 a").first()
            let title = try? titleElement?.text()
            
            // Get link
            let link = try? titleElement?.attr("href")
            let fullLink = link.map { "https://animepahe.ru\($0)" }
            
            // Get image
            let imgElement = try? card.select("img").first()
            let imgSrc = try? imgElement?.attr("data-src") ?? imgElement?.attr("src")
            
            if let title = title, !title.isEmpty {
                var item = ScrapedItem(
                    title: title,
                    imageURL: imgSrc.flatMap { URL(string: $0) }
                )
                item.link = fullLink
                items.append(item)
            }
        }
        
        // If no anime cards found, try episode format
        if items.isEmpty {
            let episodes = try document.select("div.episode-wrap a")
            print("🔍 Found \(episodes.count) episodes")
            
            for episode in episodes {
                let title = try? episode.select("div.episode-title").text()
                let link = try? episode.attr("href")
                let fullLink = link.map { "https://animepahe.ru\($0)" }
                let imgSrc = try? episode.select("img").attr("data-src")
                
                if let title = title, !title.isEmpty {
                    var item = ScrapedItem(
                        title: title,
                        imageURL: imgSrc.flatMap { URL(string: $0) }
                    )
                    item.link = fullLink
                    items.append(item)
                }
            }
        }
        
        print("✅ Animepahe scraper found \(items.count) items")
        return items
    }
    
    private static func scrapeHurawatch(_ document: Document, baseURL: URL) throws -> [ScrapedItem] {
        print("🎬 Using Hurawatch scraper")
        var items: [ScrapedItem] = []
        
        // Try main movie/show cards
        let cards = try document.select("div.flw-item")
        print("🔍 Found \(cards.count) media cards")
        
        for card in cards {
            let titleEl = try? card.select("h3.film-name a").first()
            let title = try? titleEl?.text()
            let link = try? titleEl?.attr("href")
            let fullLink = link.map { "https://hurawatch.cc\($0)" }
            
            let imgEl = try? card.select("img.film-poster-img").first()
            let imgSrc = try? imgEl?.attr("data-src") ?? imgEl?.attr("src")
            
            if let title = title, !title.isEmpty {
                var item = ScrapedItem(
                    title: title,
                    imageURL: imgSrc.flatMap { URL(string: $0) }
                )
                item.link = fullLink
                items.append(item)
            }
        }
        
        print("✅ Hurawatch scraper found \(items.count) items")
        return items
    }
    
    private static func scrapeGeneric(_ document: Document) throws -> [ScrapedItem] {
        print("🌐 Using generic scraper")
        var items: [ScrapedItem] = []
        
        // Look for common video/media patterns
        let links = try document.select("a[href]")
        for link in links {
            let title = try? link.text()
            let href = try? link.attr("href")
            
            // Filter for likely media content
            if let title = title,
               !title.isEmpty,
               title.count > 3,
               !title.lowercased().contains("login"),
               !title.lowercased().contains("register"),
               !title.lowercased().contains("home") {
                
                let imgEl = try? link.select("img").first()
                let imgSrc = try? imgEl?.attr("src") ?? imgEl?.attr("data-src")
                
                var item = ScrapedItem(
                    title: title,
                    imageURL: imgSrc.flatMap { URL(string: $0) }
                )
                item.link = href
                items.append(item)
            }
        }
        
        // Limit results
        items = Array(items.prefix(50))
        
        print("✅ Generic scraper found \(items.count) items")
        return items
    }
}
