import SwiftUI
import SwiftData

@main
struct EncoreApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Concert.self,
        ])
        
        let fileManager = FileManager.default
        let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.macky.Encore")
        
        let storeURL: URL
        if let appGroupURL = appGroupURL {
            storeURL = appGroupURL.appendingPathComponent("Encore.sqlite")
        } else {
            // Fallback for when App Groups fail (e.g. free Apple ID provisioning)
            storeURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Encore.sqlite")
        }
        
        if let defaultDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let defaultStoreURL = defaultDirectoryURL.appendingPathComponent("default.store")
            if fileManager.fileExists(atPath: defaultStoreURL.path) && !fileManager.fileExists(atPath: storeURL.path) {
                do {
                    let filesToMove = ["default.store", "default.store-shm", "default.store-wal"]
                    for file in filesToMove {
                        let sourceURL = defaultDirectoryURL.appendingPathComponent(file)
                        let targetFileName = file.replacingOccurrences(of: "default.store", with: "Encore.sqlite")
                        if let appGroupURL = appGroupURL {
                            let destURL = appGroupURL.appendingPathComponent(targetFileName)
                            if fileManager.fileExists(atPath: sourceURL.path) {
                                try fileManager.moveItem(at: sourceURL, to: destURL)
                            }
                        }
                    }
                } catch {
                    print("Migration failed: \(error)")
                }
            }
        }
        
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
