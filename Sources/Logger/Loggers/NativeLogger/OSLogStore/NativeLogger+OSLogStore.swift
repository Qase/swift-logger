import Foundation
import OSLog

@available(iOS 15.0, *)
extension NativeLogger {
    public func exportLogs(
        fromDate: Date,
        getOsLogStore: () throws -> OSLogStore = OSLogStore.getOsLogStore
    ) async throws -> [OSEntryLog] {
        let store = try getOsLogStore()
        let position = store.position(date: fromDate)
        return try await store.getEntries(bundleIdentifier: bundleIdentifier, position: position)
    }
}
