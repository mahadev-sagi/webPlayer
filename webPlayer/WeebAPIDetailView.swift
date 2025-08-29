import SwiftUI

struct WeebAPIDetailView: View {
    // This is the search result item passed from the list
    let searchItem: WeebAPISearchResult
    
    // State to hold the full details we will fetch
    @State private var fullData: WeebAPIFullData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading Details...")
                    .padding(.top, 50)
            } else if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                    Text(error).multilineTextAlignment(.center).padding()
                }
            } else if let details = fullData {
                // Once loaded, show the content
                VStack(alignment: .leading, spacing: 20) {
                    headerSection(details: details)
                    synopsisSection(details: details)
                    episodeListSection(details: details)
                }
                .padding()
            }
        }
        .navigationTitle(searchItem.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchFullDetails()
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchFullDetails() async {
        let result = await WeebAPIService.shared.fetchDetails(for: searchItem.id)
        
        await MainActor.run {
            isLoading = false
            switch result {
            case .success(let data):
                self.fullData = data
            case .failure(let error):
                self.errorMessage = "Failed to load details: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func headerSection(details: WeebAPIFullData) -> some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: details.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).overlay(ProgressView())
            }
            .frame(width: 150, height: 225).cornerRadius(12).shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(details.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(details.episodes.count) Episodes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func synopsisSection(details: WeebAPIFullData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            Text(details.synopsis.isEmpty ? "No synopsis available." : details.synopsis)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func episodeListSection(details: WeebAPIFullData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Episodes")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                ForEach(details.episodes.keys.sorted { Int($0) ?? 0 < Int($1) ?? 0 }, id: \.self) { episodeNumber in
                    Button(action: {
                        print("Tapped episode \(episodeNumber)")
                    }) {
                        Text(episodeNumber)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
