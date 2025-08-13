import SwiftUI

/// The entry point for the WorkingHours iOS application.
///
/// This struct defines the main scene for the app and injects a shared
/// ``DataStore`` into the environment.  The ``DataStore`` manages the
/// collection of companies and time entries, and persists changes to
/// ``UserDefaults``.  By storing it in a `@StateObject`, we ensure
/// that there is exactly one instance of the data store for the lifetime
/// of the app.
@main
struct WorkingHoursAppApp: App {
    /// The shared data model for the entire app.
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            // Inject the data store into the environment so that all
            // descendant views can access and modify the data without
            // manually passing it around.
            ContentView()
                .environmentObject(dataStore)
        }
    }
}