import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ConcertListView(status: "upcoming")
                .tabItem {
                    Label("Upcoming", systemImage: "calendar")
                }
            
            ConcertListView(status: "attended")
                .tabItem {
                    Label("Past", systemImage: "ticket.fill")
                }
                
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
        }
        .tint(.purple)
    }
}

#Preview {
    MainTabView()
}
