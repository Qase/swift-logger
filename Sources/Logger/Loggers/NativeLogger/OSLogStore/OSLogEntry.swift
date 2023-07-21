import Foundation
import OSLog

public struct OSEntryLog: Equatable {
    /// activity identifier
    let activityIdentifier: Int
    /// category
    let category: String
    /// message
    let composedMessage: String
    /// date
    let date: Date
    /// description
    let description: String
    /// Using ~%@ resources (%{public}s)
    let formatString: String
    /// Level
    let level: Level
    /// Aka app name
    let process: String
    /// process identifier
    let processIdentifier: Int
    /// sender
    let sender: String
    /// subsystem (mostly used bundle ID)
    let subsystem: String
    /// thread identifier
    let threadIdentifier: Int

    var formatted: String {
        "\(date) \(process)[\(processIdentifier):\(threadIdentifier)] [\(category)] \(composedMessage)"
    }
}

@available(iOS 15.0, *)
extension OSLogEntry: Identifiable {
    public var id: String {
        UUID().uuidString
    }
}

@available(iOS 15.0, *)
extension OSEntryLog {
    init(log: OSLogEntryLog) {
        self.activityIdentifier = Int(log.activityIdentifier)
        self.category = log.category
        self.composedMessage = log.composedMessage
        self.date = log.date
        self.description = log.description
        self.formatString = log.formatString
        self.level = Level(osLevel: log.level)
        self.process = log.process
        self.processIdentifier = Int(log.processIdentifier)
        self.sender = log.sender
        self.subsystem = log.subsystem
        self.threadIdentifier = Int(log.threadIdentifier)
    }
}
