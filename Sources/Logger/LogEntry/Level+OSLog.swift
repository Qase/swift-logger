import OSLog

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
            self = .custom("Undefined case from OSLogEntryLog.Level")
        @unknown default:
            self = .custom("Unknown default")
        }
    }
}
