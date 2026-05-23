import Foundation

struct EventSearchResult: Identifiable, Hashable {
    let id: String
    let name: String
    let headliner: String
    let artists: [String]
    let venue: String
    let city: String
    let date: String
    let endDate: String?
    let genre: String?
    let ticketPrice: Double?
    let imageUrl: String?
    let isFestival: Bool
}

class BandsInTownService {
    static let shared = BandsInTownService()
    
    // App ID loaded from Secrets.plist (gitignored)
    private let appId = Secrets.bandsInTownAppId
    private let baseUrl = "https://rest.bandsintown.com"
    
    func fetchEvents(for artist: String, includePast: Bool = false, fromDate: Date? = nil) async throws -> [EventSearchResult] {
        let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? artist
        
        var dateParam = includePast ? "past" : "upcoming"
        if includePast, let fromDate = fromDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let startStr = formatter.string(from: fromDate)
            let endStr = formatter.string(from: Date())
            dateParam = "\(startStr),\(endStr)"
        }
        
        let urlString = "\(baseUrl)/artists/\(encodedArtist)/events?app_id=\(appId)&date=\(dateParam)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Bandsintown returns 404 or empty string if artist not found
            if data.isEmpty || String(data: data, encoding: .utf8)?.contains("warn") == true {
                return []
            }
            throw URLError(.badServerResponse)
        }
        
        // Handle empty response which BIT sometimes sends
        if data.isEmpty || String(data: data, encoding: .utf8) == "{}" || String(data: data, encoding: .utf8) == "[]\n" {
            return []
        }
        
        let decoder = JSONDecoder()
        
        do {
            let events = try decoder.decode([BITEvent].self, from: data)
            let results = events.map { transformEvent($0, artistName: artist) }
            // For past events, return most recent first
            return includePast ? results.reversed() : results
        } catch {
            print("Bandsintown Decode Error: \(error)")
            return []
        }
    }
    
    private func transformEvent(_ event: BITEvent, artistName: String) -> EventSearchResult {
        let title = event.title ?? artistName
        let lineup = event.lineup ?? [artistName]
        let venueName = event.venue?.name ?? ""
        let city = event.venue?.city ?? ""
        let region = event.venue?.region ?? ""
        let cityStr = region.isEmpty ? city : "\(city), \(region)"
        
        // Return full datetime "2024-05-22T19:00:00"
        let dateString = event.datetime
        
        let isFestival = title.lowercased().contains("festival") || title.lowercased().contains("fest")
        
        // Get ticket price if offers exist
        let ticketPrice: Double? = nil // BIT usually just has URLs, not direct price floats
        
        return EventSearchResult(
            id: event.id,
            name: title,
            headliner: lineup.first ?? artistName,
            artists: lineup,
            venue: venueName,
            city: cityStr,
            date: dateString,
            endDate: nil,
            genre: nil,
            ticketPrice: ticketPrice,
            imageUrl: event.artist?.image_url,
            isFestival: isFestival
        )
    }
}

// MARK: - API Response Models
struct BITEvent: Decodable {
    let id: String
    let title: String?
    let datetime: String
    let venue: BITVenue?
    let lineup: [String]?
    let artist: BITArtist?
}

struct BITVenue: Decodable {
    let name: String
    let city: String
    let region: String
    let country: String
}

struct BITArtist: Decodable {
    let image_url: String?
}
