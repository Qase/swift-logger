enum OSLogError: Error, Equatable {
    case logStoreIniFailed(String)
    case gettingEntriesFailed(String)
    case logRecordsFailed
}
