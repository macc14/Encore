import SwiftUI
import SwiftData
import PhotosUI

struct AddConcertView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery = ""
    @State private var searchResults: [TicketmasterSearchResult] = []
    @State private var isSearching = false
    
    // Form fields
    @State private var title = ""
    @State private var headliner = ""
    @State private var openers = ""
    @State private var venue = ""
    @State private var city = ""
    @State private var date = Date()
    @State private var endDate = Date()
    @State private var isFestival = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isFetchingImage = false
    @State private var flyerImageData: Data? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Search Concerts")) {
                    HStack {
                        TextField("Search artist name...", text: $searchQuery)
                            .onSubmit {
                                performSearch()
                            }
                        if isSearching {
                            ProgressView()
                        } else {
                            Button("Search") {
                                performSearch()
                            }
                        }
                    }
                    
                    if !searchResults.isEmpty {
                        List(searchResults) { result in
                            Button(action: {
                                autofill(with: result)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.name.isEmpty ? result.headliner : result.name).font(.headline)
                                    Text("\(result.venue), \(result.city) - \(formatDisplayDate(result.date))").font(.caption)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                Section(header: Text("Concert Details")) {
                    TextField("Tour/Event Name", text: $title)
                    TextField("Headliner", text: $headliner)
                    TextField(isFestival ? "Lineup (comma-separated)" : "Openers (comma-separated)", text: $openers)
                    TextField("Venue", text: $venue)
                    TextField("City", text: $city)
                    DatePicker(isFestival ? "Start Date & Time" : "Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Is Festival", isOn: $isFestival)
                    if isFestival {
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("tour poster")) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Select Photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                flyerImageData = data
                            }
                        }
                    }
                    
                    if let flyerImageData, let uiImage = UIImage(data: flyerImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                }
            }
            .navigationTitle("Add Concert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveConcert() }
                        .disabled(title.isEmpty || venue.isEmpty || isFetchingImage)
                }
            }
        }
    }
    private func formatDisplayDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM/dd/yyyy h:mm a"
            return formatter.string(from: date)
        }
        
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        Task {
            do {
                searchResults = try await BandsInTownService.shared.fetchEvents(for: searchQuery)
            } catch {
                print("Search failed: \(error)")
            }
            isSearching = false
        }
    }
    
    private func autofill(with result: TicketmasterSearchResult) {
        title = result.name
        headliner = result.headliner
        openers = result.artists.filter { $0 != result.headliner }.joined(separator: ", ")
        venue = result.venue
        city = result.city
        isFestival = result.isFestival
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = formatter.date(from: result.date) {
            date = d
        } else {
            // Fallback for simple date strings if any
            formatter.dateFormat = "yyyy-MM-dd"
            if let d = formatter.date(from: result.date) {
                date = d
            }
        }
        
        let query = "\(result.headliner) \(result.city) tour poster"
        isFetchingImage = true
        Task {
            defer { isFetchingImage = false }
            
            if let url = try? await GoogleImageSearchService.shared.searchImage(query: query) {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    flyerImageData = data
                    return
                }
            }
            
            // Fallback to Ticketmaster/Bandsintown image if Google fails
            if let imageUrlString = result.imageUrl, let url = URL(string: imageUrlString) {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    flyerImageData = data
                }
            }
        }
        
        searchResults = []
        searchQuery = ""
    }
    
    private func saveConcert() {
        let artistsArray = openers.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let concert = Concert(
            title: title,
            artists: artistsArray,
            headliner: headliner,
            venue: venue,
            city: city,
            date: date,
            endDate: isFestival ? endDate : nil,
            isFestival: isFestival,
            flyerImageData: flyerImageData,
            status: date > Date() ? "upcoming" : "attended"
        )
        modelContext.insert(concert)
        NotificationManager.shared.scheduleNotification(for: concert)
        dismiss()
    }
}
