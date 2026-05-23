import SwiftUI

struct CustomHeader: View {
    let title: String
    @Binding var showingAddSheet: Bool
    @State private var showingAboutSheet = false
    
    var body: some View {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Button(action: { showingAboutSheet = true }) {
                    Text("encore")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.purple)
                }
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color.black)
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
    }
}
