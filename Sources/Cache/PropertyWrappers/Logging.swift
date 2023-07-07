#if canImport(OSLog)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@propertyWrapper public struct Logging<Key: Hashable> {
    /// The key associated with the Logger in the cache.
    public let key: Key

    /// The `RequiredKeysCache` instance to resolve the dependency from.
    public let cache: RequiredKeysCache<Key, Logger>

    /// The wrapped value that can be accessed and mutated by the property wrapper.
    public var wrappedValue: Logger {
        get {
            cache.resolve(requiredKey: key, as: Logger.self)
        }
        set {
            cache.set(value: newValue, forKey: key)
        }
    }

    #if !os(Windows)
    /// Initializes the `Logging` property wrapper.
    ///
    /// - Parameters:
    ///   - key: The key associated with the Logger in the cache.
    ///   - cache: The `RequiredKeysCache` instance to resolve the dependency from.
    public init(
        key: Key,
        using cache: RequiredKeysCache<Key, Logger> = Global.loggers
    ) {
        self.key = key
        self.cache = cache

        _ = self.cache.requiredKeys.insert(key)
    }
    #else
    /// Initializes the `Logging` property wrapper.
    ///
    /// - Parameters:
    ///   - key: The key associated with the Logger in the cache.
    ///   - cache: The `RequiredKeysCache` instance to resolve the dependency from.
    public init(
        key: Key,
        using cache: RequiredKeysCache<Key, Any>
    ) {
        self.key = key
        self.cache = cache

        _ = self.cache.requiredKeys.insert(key)
    }
    #endif
}
#endif
