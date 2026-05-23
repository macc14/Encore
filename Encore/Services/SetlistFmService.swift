import Foundation

class SetlistFmService {
    static let shared = SetlistFmService()
    
    // API key loaded from Secrets.plist (gitignored)
    private let apiKey = Secrets.setlistFmApiKey
    private let baseUrl = "https://api.setlist.fm/rest/1.0"
    
    var isApiKeyConfigured: Bool {
        return apiKey.count > 5
    }
    
    /// Fetches the setlist for a specific artist. Returns the songs and a source attribution string.
    func fetchSetlist(artistName: String, venueName: String? = nil) async throws -> (songs: [String], source: String) {
        guard isApiKeyConfigured else {
            print("Setlist.fm API key not configured.")
            return ([], "")
        }
        
        var components = URLComponents(string: "\(baseUrl)/search/setlists")!
        let queryItems = [
            URLQueryItem(name: "artistName", value: artistName)
        ]
        
        // We omit venueName in the query to get the most recent setlists, allowing us to fallback if the specific venue isn't found
        components.queryItems = queryItems
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(SetlistFmResponse.self, from: data)
        
        let validSetlists = result.setlist.filter { $0.sets.set.contains(where: { !$0.song.isEmpty }) }
        if validSetlists.isEmpty { return ([], "") }
        
        let matchedSetlist = validSetlists.first(where: { $0.venue.name.lowercased() == venueName?.lowercased() })
        let chosenSetlist = matchedSetlist ?? validSetlists.first!
        
        let songs = chosenSetlist.sets.set.flatMap { set in
            set.song.map { song in
                if let info = song.info, !info.isEmpty {
                    return "\(song.name) (\(info))"
                } else {
                    return song.name
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        var formattedDate = chosenSetlist.eventDate
        if let d = dateFormatter.date(from: chosenSetlist.eventDate) {
            dateFormatter.dateFormat = "MM/dd/yyyy"
            formattedDate = dateFormatter.string(from: d)
        }
        
        let source = "From \(formattedDate) at \(chosenSetlist.venue.name)"
        
        return (songs, source)
    }
}

// MARK: - API Response Models
struct SetlistFmResponse: Decodable {
    let setlist: [SFSetlist]
}

struct SFSetlist: Decodable {
    let id: String
    let eventDate: String
    let artist: SFArtist
    let venue: SFVenue
    let sets: SFSets
}

struct SFArtist: Decodable {
    let name: String
}

struct SFVenue: Decodable {
    let name: String
}

struct SFSets: Decodable {
    let set: [SFSet]
}

struct SFSet: Decodable {
    let encore: Int?
    let song: [SFSong]
}

struct SFSong: Decodable {
    let name: String
    let info: String?
}
