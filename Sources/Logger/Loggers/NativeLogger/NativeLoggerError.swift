enum NativeLoggerError: Error {
    case logStoreInitFailed(Error)
    case gettingEntriesFailed(Error)
}
