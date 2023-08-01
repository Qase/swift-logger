import OSLog

extension OSLogStore {
    static func getOsLogStore() throws -> OSLogStore {
        do {
            return try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            throw OSLogError.logStoreIniFailed(error.localizedDescription)
        }
    }

    func getEntries() async throws -> [OSEntryLog] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let logs = try self
                    .getEntries()
                    .compactMap { $0 as? OSLogEntryLog }
                    .map(OSEntryLog.init)
                    .filter { $0.subsystem == Bundle.main.bundleIdentifier }
                continuation.resume(with: .success(logs))
            } catch {
                continuation.resume(throwing: OSLogError.gettingEntriesFailed(error.localizedDescription))
            }
        }
    }
}
