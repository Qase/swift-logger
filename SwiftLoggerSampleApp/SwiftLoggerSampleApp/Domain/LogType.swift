import Foundation

struct LogType: Identifiable, Equatable {
    var id: UUID { UUID() }
    let level: Level
}
