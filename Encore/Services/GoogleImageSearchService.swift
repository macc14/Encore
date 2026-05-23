import Foundation

class GoogleImageSearchService {
    static let shared = GoogleImageSearchService()
    
    // API keys loaded from Secrets.plist (gitignored)
    private let apiKey = Secrets.googleApiKey
    private let cx = Secrets.googleCx
    
    private let baseUrl = "https://customsearch.googleapis.com/customsearch/v1"
    
    func searchImage(query: String) async throws -> URL? {
        // Build the URL components
        var components = URLComponents(string: baseUrl)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "cx", value: cx),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "searchType", value: "image"),
            URLQueryItem(name: "num", value: "1") // Only fetch the top result
        ]
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(GoogleSearchResponse.self, from: data)
            if let link = result.items?.first?.link {
                return URL(string: link)
            }
        } catch {
            print("Google Image Search Decode Error: \(error)")
        }
        
        return nil
    }
}

// MARK: - API Response Models
struct GoogleSearchResponse: Decodable {
    let items: [GoogleSearchItem]?
}

struct GoogleSearchItem: Decodable {
    let link: String
}
