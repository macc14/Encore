import SwiftUI
import SwiftData

struct ConcertListView: View {
    @Query private var concerts: [Concert]
    @State private var showingAddSheet = false
    
    let status: String
    
    init(status: String) {
        self.status = status
        let filter = #Predicate<Concert> { concert in
            concert.status == status
        }
        if status == "upcoming" {
            _concerts = Query(filter: filter, sort: \Concert.date, order: .forward)
        } else {
            _concerts = Query(filter: filter, sort: \Concert.date, order: .reverse)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                CustomHeader(title: status == "upcoming" ? "upcoming" : "past", showingAddSheet: $showingAddSheet)
                
                List {
                    ForEach(concerts) { concert in
                        ZStack {
                            ConcertRow(concert: concert)
                            NavigationLink(destination: ConcertDetailView(concert: concert)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.black)
                    }
                }
                .listStyle(.plain)
                .background(Color.black.edgesIgnoringSafeArea(.all))
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddConcertView()
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
            }
            .overlay {
                if concerts.isEmpty {
                    ContentUnavailableView(
                        "No Concerts",
                        systemImage: "music.mic",
                        description: Text("Tap + to add a concert")
                    )
                }
            }
        }
    }
}

struct ConcertRow: View {
    let concert: Concert
    
    var daysUntil: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfConcert = calendar.startOfDay(for: concert.date)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfConcert)
        return components.day ?? 0
    }
    var isCurrentYear: Bool {
        Calendar.current.component(.year, from: Date()) == Calendar.current.component(.year, from: concert.date)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Image
            if let imageData = concert.flyerImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: 100)
            }
            
            // Dark Gradient Overlay for readability
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.85), .black.opacity(0.3), .black.opacity(0.85)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            
            HStack(spacing: 16) {
                // Left: Date
                HStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .center, spacing: 2) {
                            Text(concert.date, format: .dateTime.month(.defaultDigits))
                                .font(.title2).bold()
                                .offset(y: -4)
                                .lineLimit(1)
                            Text("/")
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(concert.date, format: .dateTime.day(.defaultDigits))
                                .font(.title3).bold()
                                .offset(y: 4)
                                .lineLimit(1)
                        }
                        
                        if !isCurrentYear {
                            Text(String(Calendar.current.component(.year, from: concert.date)))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 2)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 65, alignment: .center)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 40)
                }
                .foregroundColor(.white)
                
                // Middle: Artists
                VStack(alignment: .leading, spacing: 4) {
                    Text(concert.headliner.isEmpty ? concert.title : concert.headliner)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    let artistsString = concert.artists.joined(separator: ", ")
                    if !artistsString.isEmpty {
                        Text(artistsString)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right: Countdown
                VStack(alignment: .trailing, spacing: 0) {
                    if daysUntil == 0 {
                        Text("today")
                            .font(.subheadline).bold()
                            .foregroundColor(.cyan)
                    } else if daysUntil == -1 {
                        Text("1")
                            .font(.title2).bold()
                        Text("day ago")
                            .font(.caption2)
                    } else if daysUntil < 0 {
                        Text("\(-daysUntil)")
                            .font(.title2).bold()
                        Text("days ago")
                            .font(.caption2)
                    } else if daysUntil == 1 {
                        Text("1")
                            .font(.title).bold()
                        Text("day")
                            .font(.caption2)
                    } else {
                        Text("\(daysUntil)")
                            .font(.title).bold()
                        Text("days")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
}
