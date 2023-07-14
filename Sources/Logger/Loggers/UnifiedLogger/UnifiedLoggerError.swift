enum UnifiedLoggerError: Error {
    case logStoreInitFailed(Error)
    case gettingEntriesFailed(Error)
}
