struct EquatableVoid: Equatable {}

enum Loadable<Value, Error> {
    case idle
    case loading
    case loaded(Value)
    case failure(Error)
}

extension Loadable {
    var error: Error? {
        if case let .failure(error) = self {
            return error
        } else {
            return nil
        }
    }

    var hasValue: Value? {
        if case let .loaded(value) = self {
            return value
        } else {
            return nil
        }
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        } else {
            return false
        }
    }
}

extension Loadable: Equatable where Value: Equatable, Error: Equatable {}
