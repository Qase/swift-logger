import OSLog

@available(iOS 15.0, *)
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
            self = .error
        case .fault:
            self = .fault
        case .undefined:
            self = .undefined("Undefined case from OSLogEntryLog.Level")
        @unknown default:
            self = .undefined("Unknown default")
        }
    }
}
