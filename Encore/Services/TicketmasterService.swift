import Foundation

struct TicketmasterSearchResult: Identifiable, Hashable {
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

class TicketmasterService {
    static let shared = TicketmasterService()
    
    // API key loaded from Secrets.plist (gitignored)
    private let apiKey = Secrets.ticketmasterApiKey
    private let baseUrl = "https://app.ticketmaster.com/discovery/v2"
    
    var isApiKeyConfigured: Bool {
        return apiKey.count > 5
    }
    
    func searchEvents(query: String) async throws -> [TicketmasterSearchResult] {
        guard isApiKeyConfigured else {
            print("Ticketmaster API key not configured.")
            return []
        }
        
        var components = URLComponents(string: "\(baseUrl)/events.json")!
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "keyword", value: query),
            URLQueryItem(name: "classificationName", value: "music"),
            URLQueryItem(name: "size", value: "10"),
            URLQueryItem(name: "sort", value: "date,asc")
        ]
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            print("Invalid Ticketmaster API key")
            return []
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(TicketmasterResponse.self, from: data)
        
        return result._embedded?.events.map { transformEvent($0) } ?? []
    }
    
    private func transformEvent(_ event: TMEvent) -> TicketmasterSearchResult {
        let venue = event._embedded?.venues?.first
        let attractions = event._embedded?.attractions ?? []
        let headliner = attractions.first?.name ?? event.name
        let artists = attractions.map { $0.name }
        
        let bestImage = event.images?.sorted(by: { a, b in
            let aIs169 = a.ratio == "16_9" ? 1 : 0
            let bIs169 = b.ratio == "16_9" ? 1 : 0
            if aIs169 != bIs169 {
                return bIs169 < aIs169
            }
            return b.width < a.width
        }).first
        
        let genre = event.classifications?.first?.genre?.name ?? attractions.first?.classifications?.first?.genre?.name
        
        let isFestival = event.name.lowercased().contains("festival") ||
                         event.name.lowercased().contains("fest") ||
                         (event.classifications?.first?.subGenre?.name ?? "").lowercased().contains("festival") ||
                         (event.dates.end?.localDate != nil && event.dates.end?.localDate != event.dates.start.localDate)
                         
        var cityStr = ""
        if let v = venue {
            let cityName = v.city?.name ?? ""
            let stateCode = v.state?.stateCode ?? ""
            if !cityName.isEmpty {
                cityStr = cityName
                if !stateCode.isEmpty {
                    cityStr += ", \(stateCode)"
                }
            }
        }
        
        let ticketPrice = event.priceRanges?.first?.min
        
        return TicketmasterSearchResult(
            id: event.id,
            name: event.name,
            headliner: headliner,
            artists: artists,
            venue: venue?.name ?? "",
            city: cityStr,
            date: event.dates.start.localDate,
            endDate: event.dates.end?.localDate,
            genre: (genre != nil && genre != "Undefined") ? genre : nil,
            ticketPrice: ticketPrice,
            imageUrl: bestImage?.url,
            isFestival: isFestival
        )
    }
}

// MARK: - API Response Models
struct TicketmasterResponse: Decodable {
    let _embedded: TMEmbeddedEvents?
}

struct TMEmbeddedEvents: Decodable {
    let events: [TMEvent]
}

struct TMEvent: Decodable {
    let id: String
    let name: String
    let dates: TMDates
    let images: [TMImage]?
    let _embedded: TMEmbeddedDetails?
    let classifications: [TMClassification]?
    let priceRanges: [TMPriceRange]?
}

struct TMDates: Decodable {
    let start: TMStartDate
    let end: TMEndDate?
}

struct TMStartDate: Decodable {
    let localDate: String
    let localTime: String?
}

struct TMEndDate: Decodable {
    let localDate: String?
}

struct TMImage: Decodable {
    let url: String
    let width: Int
    let height: Int
    let ratio: String?
}

struct TMEmbeddedDetails: Decodable {
    let venues: [TMVenue]?
    let attractions: [TMAttraction]?
}

struct TMVenue: Decodable {
    let name: String
    let city: TMCity?
    let state: TMState?
}

struct TMCity: Decodable {
    let name: String
}

struct TMState: Decodable {
    let stateCode: String
}

struct TMAttraction: Decodable {
    let name: String
    let classifications: [TMClassification]?
}

struct TMClassification: Decodable {
    let genre: TMGenre?
    let subGenre: TMGenre?
}

struct TMGenre: Decodable {
    let name: String
}

struct TMPriceRange: Decodable {
    let min: Double
    let max: Double
    let currency: String
}
