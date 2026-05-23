import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    @MainActor
    private func getClosestConcert() -> Concert? {
        do {
            let schema = Schema([Concert.self])
            let fileManager = FileManager.default
            guard let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.macky.Encore") else {
                print("Widget failed: Could not get App Group URL.")
                return nil
            }
            let storeURL = appGroupURL.appendingPathComponent("Encore.sqlite")
            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])
            
            let context = container.mainContext
            let descriptor = FetchDescriptor<Concert>(
                predicate: #Predicate<Concert> { $0.status == "upcoming" },
                sortBy: [SortDescriptor(\.date)]
            )
            return try context.fetch(descriptor).first
        } catch {
            print("Widget failed to fetch concert: \(error)")
            return nil
        }
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), concert: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let concert = getClosestConcert()
            let entry = SimpleEntry(date: Date(), concert: concert)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let concert = getClosestConcert()
            let entry = SimpleEntry(date: Date(), concert: concert)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let concert: Concert?
}

struct EncoreWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            if let concert = entry.concert {
                // Background Image
                if let data = concert.flyerImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.purple
                }
                
                // Dark Gradient overlay for text readability
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear, Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                
                VStack(alignment: .leading) {
                    Text(concert.title.isEmpty ? concert.headliner : concert.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if let days = Calendar.current.dateComponents([.day], from: Date(), to: concert.date).day {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(max(0, days))")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(days == 1 ? "day" : "days")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        Text("Soon")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack {
                    Image(systemName: "music.mic")
                        .font(.largeTitle)
                    Text("No Upcoming Concerts")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .foregroundColor(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

struct EncoreWidget: Widget {
    let kind: String = "EncoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EncoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Concert")
        .description("See your next upcoming concert.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
