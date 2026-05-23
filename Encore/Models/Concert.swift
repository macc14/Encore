import Foundation
import SwiftData

@Model
final class Concert {
    @Attribute(.unique) var id: String
    var title: String
    var artists: [String]
    var headliner: String
    var venue: String
    var city: String
    var date: Date
    var endDate: Date?
    var isFestival: Bool
    var genre: String?
    
    @Attribute(.externalStorage)
    var flyerImageData: Data?
    
    var ticketPrice: Double?
    var notes: String?
    var setlist: [String]?
    var setlistSource: String?
    
    // Using a string for status: "upcoming", "attended", "cancelled"
    var status: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         title: String,
         artists: [String] = [],
         headliner: String = "",
         venue: String = "",
         city: String = "",
         date: Date,
         endDate: Date? = nil,
         isFestival: Bool = false,
         genre: String? = nil,
         flyerImageData: Data? = nil,
         ticketPrice: Double? = nil,
         notes: String? = nil,
         status: String = "upcoming",
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.artists = artists
        self.headliner = headliner
        self.venue = venue
        self.city = city
        self.date = date
        self.endDate = endDate
        self.isFestival = isFestival
        self.genre = genre
        self.flyerImageData = flyerImageData
        self.ticketPrice = ticketPrice
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
    }
}
