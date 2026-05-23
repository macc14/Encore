import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    Text("encore")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text("track your concerts!")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("Designed & Developed by")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("mack w")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
