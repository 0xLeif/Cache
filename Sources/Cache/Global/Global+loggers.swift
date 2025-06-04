#if canImport(OSLog)
import OSLog

/// Typealias for `os.Logger`
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public typealias Logger = os.Logger

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Global {
    /// The global cache for Loggers
    public static let loggers: RequiredKeysCache<AnyHashable, Logger> = RequiredKeysCache()
}
#endif
