import Foundation

// FileAccessExecutor is used to execute logging (writing to a file) and deletion (deleting files) on the same queue, so no race conditions can appear.
struct FileAccessExecutor {
    var execute: (@escaping () -> Void) -> ()
    func callAsFunction(job: @escaping () -> Void) { execute(job) }
}

extension FileAccessExecutor {
    static func live(queue: DispatchQueue) -> Self {
        .init(execute: { queue.async(execute: $0) })
    }
}
