import Synchronization

/// A thread-safe lock wrapper around Swift's `Mutex` type.
///
/// Usage:
/// ```swift
/// let lock = CacheLock()
/// let result = lock.withLock {
///     // protected code
///     return value
/// }
/// ```
final class CacheLock: Sendable {
    private let mutex = Mutex<Void>(())

    init() {}

    /// Executes the given closure while holding the lock.
    ///
    /// - Parameter body: The closure to execute.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        try mutex.withLock { _ in try body() }
    }
}
