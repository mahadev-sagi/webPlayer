import Foundation

class RecentURLsManager: ObservableObject {
    @Published var recentURLs: [String] = []
    private let userDefaults = UserDefaults.standard
    private let key = "RecentURLs"
    private let maxCount = 10
    
    init() {
        loadURLs()
    }
    
    func addURL(_ urlString: String) {
        // Remove existing instance to move it to the top
        recentURLs.removeAll { $0 == urlString }
        
        // Add to the top
        recentURLs.insert(urlString, at: 0)
        
        // Trim the array if it exceeds the max count
        if recentURLs.count > maxCount {
            recentURLs = Array(recentURLs.prefix(maxCount))
        }
        
        saveURLs()
    }
    
    private func loadURLs() {
        recentURLs = userDefaults.stringArray(forKey: key) ?? []
    }
    
    private func saveURLs() {
        userDefaults.set(recentURLs, forKey: key)
    }
}
