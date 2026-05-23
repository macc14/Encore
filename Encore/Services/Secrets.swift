import Foundation

enum Secrets {
    private static let secrets: [String: String] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            print("⚠️ Secrets.plist not found. Copy Secrets.example.plist to Secrets.plist and fill in your API keys.")
            return [:]
        }
        return dict
    }()
    
    static var googleApiKey: String { secrets["GOOGLE_API_KEY"] ?? "" }
    static var googleCx: String { secrets["GOOGLE_CX"] ?? "" }
    static var setlistFmApiKey: String { secrets["SETLISTFM_API_KEY"] ?? "" }
    static var bandsInTownAppId: String { secrets["BANDSINTOWN_APP_ID"] ?? "" }
    static var ticketmasterApiKey: String { secrets["TICKETMASTER_API_KEY"] ?? "" }
}
