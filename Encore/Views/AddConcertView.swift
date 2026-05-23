import SwiftUI
import SwiftData
import PhotosUI

struct AddConcertView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery = ""
    @State private var searchResults: [EventSearchResult] = []
    @State private var isSearching = false
    @State private var searchMode = 0 // 0 = upcoming, 1 = past
    @State private var searchDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    
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
                Section(header: Text("search concerts")) {
                    Picker("", selection: $searchMode) {
                        Text("upcoming").tag(0)
                        Text("past").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    
                    if searchMode == 1 {
                        DatePicker("search from", selection: $searchDate, in: ...Date(), displayedComponents: .date)
                    }
                    
                    HStack {
                        TextField("search artist name...", text: $searchQuery)
                            .onSubmit {
                                performSearch()
                            }
                        if isSearching {
                            ProgressView()
                        } else {
                            Button("search") {
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
                                    Text("\(result.venue), \(result.city) — \(formatDisplayDate(result.date))").font(.caption)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                Section(header: Text("concert details")) {
                    TextField("tour/event name", text: $title)
                    TextField("headliner", text: $headliner)
                    TextField(isFestival ? "lineup (comma-separated)" : "openers (comma-separated)", text: $openers)
                    TextField("venue", text: $venue)
                    TextField("city", text: $city)
                    DatePicker(isFestival ? "start date & time" : "date & time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("is festival", isOn: $isFestival)
                    if isFestival {
                        DatePicker("end date", selection: $endDate, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("tour poster")) {
                    if isFetchingImage {
                        HStack {
                            ProgressView()
                            Text("fetching image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let flyerImageData, let uiImage = UIImage(data: flyerImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(flyerImageData != nil ? "replace photo" : "select photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                flyerImageData = data
                            }
                        }
                    }
                }
            }
            .navigationTitle("add concert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { saveConcert() }
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
                searchResults = try await BandsInTownService.shared.fetchEvents(
                    for: searchQuery,
                    includePast: searchMode == 1,
                    fromDate: searchMode == 1 ? searchDate : nil
                )
            } catch {
                print("Search failed: \(error)")
            }
            isSearching = false
        }
    }
    
    private func autofill(with result: EventSearchResult) {
        title = result.name.isEmpty ? result.headliner : result.name
        headliner = result.headliner
        isFestival = result.isFestival
        
        // For festivals, put the full lineup; for regular shows, exclude the headliner
        if isFestival {
            openers = result.artists.joined(separator: ", ")
        } else {
            openers = result.artists.filter { $0 != result.headliner }.joined(separator: ", ")
        }
        
        venue = result.venue
        city = result.city
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = formatter.date(from: result.date) {
            date = d
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
            if let d = formatter.date(from: result.date) {
                date = d
            }
        }
        
        if let endDateStr = result.endDate {
            formatter.dateFormat = "yyyy-MM-dd"
            if let d = formatter.date(from: endDateStr) {
                endDate = d
            }
        }
        
        // Auto-fetch tour poster image
        isFetchingImage = true
        Task {
            defer { isFetchingImage = false }
            
            // Try Google Image Search first
            let query = "\(result.headliner) \(result.city) tour poster"
            if let url = try? await GoogleImageSearchService.shared.searchImage(query: query) {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    flyerImageData = data
                    return
                }
            }
            
            // Fallback to Bandsintown/Ticketmaster artist image
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
