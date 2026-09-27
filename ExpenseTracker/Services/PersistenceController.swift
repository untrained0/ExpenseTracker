import Foundation
import SwiftData

/// Owns the app's `ModelContainer`.
///
/// `shared` is a singleton because App Intents (`LogExpenseIntent`) run outside the view
/// hierarchy and need the same store the UI uses. Intents declared in the app target run
/// in the app's process, so they share this exact container.
///
/// Phase 4 (widgets) moves the store into an App Group by passing
/// `groupContainer: .identifier("group.<bundle-id>")` to `ModelConfiguration`.
enum PersistenceController {
    static let shared: ModelContainer = makeContainer()

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([Expense.self])
        // A unique name per in-memory container keeps parallel tests isolated from each other.
        let configuration = ModelConfiguration(
            inMemory ? UUID().uuidString : nil,
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // The app can't do anything useful without its store, so failing loudly is correct.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
