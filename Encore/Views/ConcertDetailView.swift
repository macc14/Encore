import SwiftUI
import SwiftData

struct ConcertDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    
    let concert: Concert
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageData = concert.flyerImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(concert.headliner.isEmpty ? concert.title : concert.headliner)
                        .font(.largeTitle)
                        .bold()
                    
                    if !concert.headliner.isEmpty && !concert.title.isEmpty && concert.headliner != concert.title {
                        Text(concert.title)
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(concert.venue) • \(concert.city)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text(concert.date.formatted(date: .long, time: .shortened))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical)
                    
                    if let setlist = concert.setlist, !setlist.isEmpty {
                        Text(concert.status == "upcoming" ? "Potential Setlist" : "Setlist")
                            .font(.title2)
                            .bold()
                        
                        if let source = concert.setlistSource {
                            Text("Highlighted: \(source)")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .padding(.bottom, 4)
                        }
                        
                        ForEach(Array(setlist.enumerated()), id: \.offset) { index, song in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, alignment: .leading)
                                Text(song)
                            }
                        }
                    } else if isFetchingSetlist {
                        ProgressView("Loading setlist...")
                            .padding()
                    } else {
                        Text("No setlist available yet.")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if concert.setlist == nil || concert.setlist!.isEmpty || concert.status == "upcoming" {
                fetchSetlist()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: deleteConcert) {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditConcertView(concert: concert)
        }
    }
    
    private func deleteConcert() {
        NotificationManager.shared.removeNotification(for: concert.id)
        modelContext.delete(concert)
        dismiss()
    }
    
    @State private var isFetchingSetlist = false
    
    private func fetchSetlist() {
        let artistToSearch = concert.headliner.isEmpty ? concert.title : concert.headliner
        isFetchingSetlist = true
        
        Task {
            do {
                let result = try await SetlistFmService.shared.fetchSetlist(
                    artistName: artistToSearch,
                    venueName: concert.venue
                )
                
                await MainActor.run {
                    concert.setlist = result.songs
                    concert.setlistSource = result.source
                    try? modelContext.save()
                    isFetchingSetlist = false
                }
            } catch {
                print("Failed to fetch setlist: \(error)")
                await MainActor.run {
                    isFetchingSetlist = false
                }
            }
        }
    }
}
