import SwiftUI
import SwiftData
import PhotosUI

struct EditConcertView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var concert: Concert
    
    @State private var title: String
    @State private var headliner: String
    @State private var openers: String
    @State private var venue: String
    @State private var city: String
    @State private var date: Date
    @State private var isFestival: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var flyerImageData: Data? = nil
    
    init(concert: Concert) {
        self.concert = concert
        _title = State(initialValue: concert.title)
        _headliner = State(initialValue: concert.headliner)
        _openers = State(initialValue: concert.artists.joined(separator: ", "))
        _venue = State(initialValue: concert.venue)
        _city = State(initialValue: concert.city)
        _date = State(initialValue: concert.date)
        _isFestival = State(initialValue: concert.isFestival)
        _flyerImageData = State(initialValue: concert.flyerImageData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Concert Details")) {
                    TextField("Tour/Event Name", text: $title)
                    TextField("Headliner", text: $headliner)
                    TextField("Openers (comma-separated)", text: $openers)
                    TextField("Venue", text: $venue)
                    TextField("City", text: $city)
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Is Festival", isOn: $isFestival)
                }
                
                Section(header: Text("Flyer Image")) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(flyerImageData == nil ? "Select Photo" : "Change Photo")
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
            .navigationTitle("Edit Concert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveConcert() }
                        .disabled(title.isEmpty || venue.isEmpty)
                }
            }
        }
    }
    
    private func saveConcert() {
        concert.title = title
        concert.headliner = headliner
        let artistsArray = openers.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        concert.artists = artistsArray
        concert.venue = venue
        concert.city = city
        concert.date = date
        concert.isFestival = isFestival
        concert.flyerImageData = flyerImageData
        concert.status = date > Date() ? "upcoming" : "attended"
        
        try? modelContext.save()
        NotificationManager.shared.scheduleNotification(for: concert)
        dismiss()
    }
}
