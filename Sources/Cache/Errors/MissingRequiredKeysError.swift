import Foundation

/// `Error` that reports the required keys
public struct MissingRequiredKeysError<Key: Hashable>: LocalizedError {
    /// Required keys
    public let keys: Set<Key>

    /// init for `MissingRequiredKeysError<Key>`
    public init(keys: Set<Key>) {
        self.keys = keys
    }

    /// Error description for `LocalizedError`
    public var errorDescription: String? {
        "Missing Required Keys: \(keys.map { "\($0)" }.joined(separator: ", "))"
    }
}
