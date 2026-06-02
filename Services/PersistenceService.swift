import SwiftData
import Foundation

actor PersistenceService {
    static let shared = PersistenceService()
    private init() {}

    nonisolated var container: ModelContainer {
        get throws {
            let schema = Schema([TaskItem.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
