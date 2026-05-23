import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(filter: #Predicate<Concert> { $0.status == "attended" }, sort: \Concert.date)
    private var concerts: [Concert]
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                CustomHeader(title: "stats", showingAddSheet: $showingAddSheet)
                
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if !concerts.isEmpty {
                                HStack(spacing: 0) {
                                    Text("You've been to ")
                                    Text("\(concerts.count)")
                                        .foregroundColor(.purple)
                                        .bold()
                                    Text(" concerts")
                                }
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.top)
                            }
                        
                        if concerts.isEmpty {
                            ContentUnavailableView(
                                "No Data Yet",
                                systemImage: "chart.bar.xaxis",
                                description: Text("Attend some concerts to see your stats!")
                            )
                        } else {
                            // Top Artists
                            StatSection(title: "Top Artists", icon: "person.3.fill", items: topBands, label: "concerts")
                            
                            // Top Venues
                            StatSection(title: "Top Venues", icon: "building.2.fill", items: topVenues, label: "concerts")
                            
                            // Top Locations
                            StatSection(title: "Top Locations", icon: "mappin.and.ellipse", items: topLocations, label: "concerts")
                            
                            // Longest Streaks
                            if let longestStreak = longestStreakString {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.purple)
                                        Text("Longest Streak")
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal)
                                    
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text("1")
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .frame(width: 24, alignment: .leading)
                                            Text(longestStreak.dateRange)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(longestStreak.days) days")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color(UIColor.darkGray).opacity(0.3))
                                    }
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Grand Totals
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.purple)
                                    Text("Grand Totals")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    TotalRow(label: "Performances Seen", value: performancesSeen)
                                    Divider().background(Color.gray.opacity(0.3))
                                    TotalRow(label: "Bands Seen", value: uniqueBandsSeen)
                                    Divider().background(Color.gray.opacity(0.3))
                                    TotalRow(label: "Concerts Attended", value: concerts.count)
                                    Divider().background(Color.gray.opacity(0.3))
                                    TotalRow(label: "Venues Visited", value: uniqueVenues)
                                    Divider().background(Color.gray.opacity(0.3))
                                    TotalRow(label: "Locations Visited", value: uniqueLocations)
                                }
                                .background(Color(UIColor.darkGray).opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 40)
                        } // ends else
                    } // ends VStack
                } // ends ScrollView
            } // ends ZStack
        } // ends VStack(spacing: 0)
        .toolbar(.hidden, for: .navigationBar)
    } // ends NavigationStack
} // ends body
    
    // MARK: - Computed Stats
    
    private var topBands: [(String, Int)] {
        var counts: [String: Int] = [:]
        for concert in concerts {
            let names = [concert.headliner] + concert.artists
            let uniqueNames = Set(names.filter { !$0.isEmpty })
            for name in uniqueNames {
                counts[name, default: 0] += 1
            }
        }
        return Array(counts.sorted { $0.value > $1.value }.prefix(5))
    }
    
    private var topVenues: [(String, Int)] {
        var counts: [String: Int] = [:]
        for concert in concerts {
            counts[concert.venue, default: 0] += 1
        }
        return Array(counts.sorted { $0.value > $1.value }.prefix(5))
    }
    
    private var topLocations: [(String, Int)] {
        var counts: [String: Int] = [:]
        for concert in concerts {
            if !concert.city.isEmpty {
                counts[concert.city, default: 0] += 1
            }
        }
        return Array(counts.sorted { $0.value > $1.value }.prefix(5))
    }
    
    private var performancesSeen: Int {
        concerts.reduce(0) { total, concert in
            let acts = Set([concert.headliner] + concert.artists).filter { !$0.isEmpty }
            return total + acts.count
        }
    }
    
    private var uniqueBandsSeen: Int {
        var acts: Set<String> = []
        for concert in concerts {
            acts.insert(concert.headliner)
            for artist in concert.artists {
                acts.insert(artist)
            }
        }
        return acts.filter { !$0.isEmpty }.count
    }
    
    private var uniqueVenues: Int {
        Set(concerts.map { $0.venue }).count
    }
    
    private var uniqueLocations: Int {
        Set(concerts.map { $0.city }.filter { !$0.isEmpty }).count
    }
    
    private var longestStreakString: (dateRange: String, days: Int)? {
        guard !concerts.isEmpty else { return nil }
        
        let calendar = Calendar.current
        var uniqueDates: Set<Date> = []
        for concert in concerts {
            uniqueDates.insert(calendar.startOfDay(for: concert.date))
        }
        
        let sortedDates = Array(uniqueDates).sorted()
        
        var maxStreak = 1
        var currentStreak = 1
        var bestStreakStart = sortedDates[0]
        var bestStreakEnd = sortedDates[0]
        var currentStreakStart = sortedDates[0]
        
        for i in 1..<sortedDates.count {
            let previous = sortedDates[i-1]
            let current = sortedDates[i]
            
            if let days = calendar.dateComponents([.day], from: previous, to: current).day, days == 1 {
                currentStreak += 1
            } else {
                if currentStreak > maxStreak {
                    maxStreak = currentStreak
                    bestStreakStart = currentStreakStart
                    bestStreakEnd = previous
                }
                currentStreak = 1
                currentStreakStart = current
            }
        }
        
        if currentStreak > maxStreak {
            maxStreak = currentStreak
            bestStreakStart = currentStreakStart
            bestStreakEnd = sortedDates.last!
        }
        
        if maxStreak < 2 {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        
        let startString = formatter.string(from: bestStreakStart)
        let endString = formatter.string(from: bestStreakEnd)
        
        return ("\(startString) - \(endString)", maxStreak)
    }
}

struct StatSection: View {
    let title: String
    let icon: String
    let items: [(String, Int)]
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            if items.isEmpty {
                Text("Not enough data")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                                .frame(width: 24, alignment: .leading)
                            
                            Text(item.0)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(item.1) \(label)")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(index % 2 == 0 ? Color(UIColor.darkGray).opacity(0.3) : Color.clear)
                    }
                }
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            }
        }
    }
}

struct TotalRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text("\(value)")
                .foregroundColor(.gray)
        }
        .padding()
    }
}
