import Foundation
import OSLog

@available(iOS 15.0, *)
extension OSLogStore {
    public static func getOsLogStore() throws -> OSLogStore {
        do {
            // Currently, the log store is limited to the scope of the current process,
            // which means that it's only possible to retrieve logs from the app's current run.
            // If the app crashes or killed, it's no longer possible to do so.
            // https://developer.apple.com/forums/thread/733262
            return try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            throw UnifiedLoggerError.logStoreInitFailed(error)
        }
    }

    func getEntries(bundleIdentifier: String, position: OSLogPosition) async throws -> [OSEntryLog] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let logs = try self
                    .getEntries(at: position)
                    .compactMap { $0 as? OSLogEntryLog }
                    .map(OSEntryLog.init)
                    .filter { $0.subsystem == bundleIdentifier }
                continuation.resume(with: .success(logs))
            } catch {
                continuation.resume(throwing: UnifiedLoggerError.gettingEntriesFailed(error))
            }
        }
    }
}
