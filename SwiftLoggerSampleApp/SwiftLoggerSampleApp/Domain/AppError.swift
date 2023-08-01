enum AppError: Error, Equatable {
    case osLog(OSLogError)
    case unknown(String)

    init(error: Error) {
        if let osLogError = error as? OSLogError {
            self = .osLog(osLogError)
        } else {
            self = .unknown("Mapping error")
        }
    }
}
