import Foundation

/// `Error` that reports the expected type for a value
public struct InvalidTypeError<ExpectedType, ActualType>: LocalizedError {
    /// Expected type
    public let expectedType: ExpectedType.Type

    // Actual Type
    public let actualType: ActualType.Type

    /// init for `InvalidTypeError<Key>`
    public init(
        expectedType: ExpectedType.Type,
        actualType: ActualType.Type
    ) {
        self.expectedType = expectedType
        self.actualType = actualType
    }

    /// Error description for `LocalizedError`
    public var errorDescription: String? {
        "Invalid Type: (Expected: \(expectedType.self)) got \(actualType.self))"
    }
}
