import OSLog

struct OSEntryLog: Equatable {
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
        """
        \(date) \(process)[\(processIdentifier):\(threadIdentifier)] \
        [\(category)] \(composedMessage) \\ \(formatString)
        """
    }
}

extension OSEntryLog: Identifiable {
    var id: String {
        UUID().uuidString
    }
}

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

extension OSEntryLog {
    static let mock = OSEntryLog(
        activityIdentifier: 0,
        category: "category",
        composedMessage: "composedMessage",
        date: Date.now,
        description: "description",
        formatString: "formatString",
        level: .info,
        process: "process",
        processIdentifier: 40104,
        sender: "sender",
        subsystem: "subsystem",
        threadIdentifier: 2118665
    )
}
