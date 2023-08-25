import Foundation
import OSLog

enum Level: String, CaseIterable {
    case debug      // trace
    case info
    case `default`
    case warning    // error
    case critical   // fault
}

extension Level {
    public init(osLevel: OSLogEntryLog.Level) {
        switch osLevel {
        case .debug:
            self = .debug
        case .info:
            self = .info
        case .notice:
            self = .default
        case .error:
            self = .warning
        case .fault:
            self = .critical
        case .undefined:
            self = .default
        @unknown default:
            self = .default
        }
    }
}
