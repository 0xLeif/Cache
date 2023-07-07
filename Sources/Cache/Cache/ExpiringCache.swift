import Foundation

/**
 A cache that retains and returns objects for a specific duration set by the `ExpirationDuration` enumeration. The `ExpiringCache` class conforms to the `Cacheable` protocol for common cache operations.

 - Note: The keys used in the cache must be `Hashable` conformant.

 - Warning: Using an overly long `ExpirationDuration` can cause the cache to retain more memory than necessary or reduce performance, while using an overly short `ExpirationDuration` can cause the cache to remove outdated results.

 Objects stored in the cache are automatically removed when their expiration duration has passed.
 */
public class ExpiringCache<Key: Hashable, Value>: Cacheable {
    /// `Error` that reports expired values
    public struct ExpiriedValueError: LocalizedError {
        /// Expired key
        public let key: Key

        /// When the value expired
        public let expiration: Date

        /**
         Initializes a new `ExpiredValueError`.
         - Parameters:
             - key: The expired key.
             - expiration: The expiration date.
         */
        public init(
            key: Key,
            expiration: Date
        ) {
            self.key = key
            self.expiration = expiration
        }

        /// Error description for `LocalizedError`
        public var errorDescription: String? {
            let dateFormatter = DateFormatter()

            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium

            return "Expired Key: \(key) (expired at \(dateFormatter.string(from: expiration)))"
        }
    }

    /**
     Enumeration used to represent expiration durations in seconds, minutes or hours.
     */
    public enum ExpirationDuration {
        /// The enumeration cases representing a duration in seconds.
        case seconds(UInt)

        /// The enumeration cases representing a duration in minutes.
        case minutes(UInt)

        /// The enumeration cases representing a duration in hours.
        case hours(UInt)

        /**
         A computed property that returns a TimeInterval value representing
         the duration calculated from the given unit and duration value.

         - Returns: A `TimeInterval` value representing the duration of the time unit set for the `ExpirationDuration`.
         */
        public var timeInterval: TimeInterval {
            switch self {
            case let .seconds(seconds): return TimeInterval(seconds)
            case let .minutes(minutes): return TimeInterval(minutes) * 60
            case let .hours(hours):     return TimeInterval(hours) * 60 * 60
            }
        }
    }

    private struct ExpiringValue {
        let expriation: Date
        let value: Value
    }

    /// The cache used to store the key-value pairs.
    private let cache: Cache<Key, ExpiringValue>

    /// The duration before each object will be removed. The duration for each item is determined when the value is added to the cache.
    public let duration: ExpirationDuration

    /// Returns a dictionary containing all the key value pairs of the cache.
    public var allValues: [Key: Value] {
        values(ofType: Value.self)
    }

    /**
     Initializes a new `ExpiringCache` instance with an optional dictionary of initial key-value pairs.

     - Parameters:
        - duration: The duration before each object will be removed. The duration for each item is determined when the value is added to the Cache.
        - initialValues: An optional dictionary of initial key-value pairs.
     */
    public init(
        duration: ExpirationDuration,
        initialValues: [Key: Value] = [:]
    ) {
        self.cache = Cache(
            initialValues: initialValues.mapValues { value in
                ExpiringValue(
                    expriation: Date().addingTimeInterval(duration.timeInterval),
                    value: value
                )
            }
        )
        self.duration = duration
    }

    /**
     Initializes a new `ExpiringCache` instance with duration of 1 hour and an optional dictionary of initial key-value pairs.

     - Parameters:
        - initialValues: An optional dictionary of initial key-value pairs.
     */
    required public convenience init(initialValues: [Key: Value] = [:]) {
        self.init(duration: .hours(1), initialValues: initialValues)
    }

    /**
     Gets the value for the specified key and casts it to the specified output type (if possible).

     - Parameters:
         - key: the key to look up in the cache.
         - as: the type to cast the value to.
     - Returns: the value of the specified key casted to the output type (if possible).
     */
    public func get<Output>(_ key: Key, as: Output.Type = Output.self) -> Output? {
        guard let expiringValue = cache.get(key, as: ExpiringValue.self) else {
            return nil
        }

        if isExpired(value: expiringValue) {
            cache.remove(key)

            return nil
        }

        return expiringValue.value as? Output
    }

    /**
     Gets a value from the cache for a given key.

     - Parameters:
     - key: The key to retrieve the value for.
     - Returns: The value stored in cache for the given key, or `nil` if it doesn't exist.
     */
    open func get(_ key: Key) -> Value? {
        get(key, as: Value.self)
    }

    /**
     Resolves the value for the specified key and casts it to the specified output type.

     - Parameters:
         - key: the key to look up in the cache.
         - as: the type to cast the value to.
     - Throws: InvalidTypeError if the specified key is missing or if the value cannot be casted to the specified output type.
     - Returns: the value of the specified key casted to the output type.
     */
    public func resolve<Output>(_ key: Key, as: Output.Type = Output.self) throws -> Output {
        let expiringValue = try cache.resolve(key, as: ExpiringValue.self)

        if isExpired(value: expiringValue) {
            remove(key)

            throw ExpiriedValueError(
                key: key,
                expiration: expiringValue.expriation
            )
        }

        guard let value = expiringValue.value as? Output else {
            throw InvalidTypeError(
                expectedType: Output.self,
                actualType: type(of: expiringValue.value)
            )
        }

        return value
    }

    /**
     Resolves a value from the cache for a given key.

     - Parameters:
        - key: The key to retrieve the value for.
     - Returns: The value stored in cache for the given key.
     - Throws: `MissingRequiredKeysError` if the key is missing, or `InvalidTypeError` if the value type is not compatible with the expected type.
     */
    open func resolve(_ key: Key) throws -> Value {
        try resolve(key, as: Value.self)
    }

    /**
     Sets the value for the specified key.

     - Parameters:
         - value: the value to store in the cache.
         - key: the key to use for storing the value in the cache.
     */
    public func set(value: Value, forKey key: Key) {
        cache.set(
            value: ExpiringValue(
                expriation: Date().addingTimeInterval(duration.timeInterval),
                value: value
            ),
            forKey: key
        )
    }

    /**
     Removes the value for the specified key from the cache.

     - Parameter key: the key to remove from the cache.
     */
    public func remove(_ key: Key) {
        cache.remove(key)
    }

    /**
     Checks whether the cache contains the specified key.

     - Parameter key: the key to look up in the cache.
     - Returns: true if the cache contains the key, false otherwise.
     */
    public func contains(_ key: Key) -> Bool {
        guard let expiringValue = cache.get(key, as: ExpiringValue.self) else {
            return false
        }

        if isExpired(value: expiringValue) {
            remove(key)

            return false
        }

        return cache.contains(key)
    }

    /**
     Checks whether the cache contains all the specified keys.

     - Parameter keys: the set of keys to require.
     - Throws: MissingRequiredKeysError if any of the specified keys are missing from the cache.
     - Returns: self (the Cache instance).
     */
    public func require(keys: Set<Key>) throws -> Self {
        var missingKeys: Set<Key> = []

        for key in keys {
            if contains(key) == false {
                missingKeys.insert(key)
            }
        }

        guard missingKeys.isEmpty else {
            throw MissingRequiredKeysError(keys: missingKeys)
        }

        return self
    }

    /**
     Checks whether the cache contains the specified key.

     - Parameter key: the key to require.
     - Throws: MissingRequiredKeysError if the specified key is missing from the cache.
     - Returns: self (the Cache instance).
     */
    public func require(_ key: Key) throws -> Self {
        try require(keys: [key])
    }

    /**
     Returns a dictionary containing only the key-value pairs where the value is of the specified output type.

     - Parameter ofType: the type of values to include in the dictionary (defaults to Value).
     - Returns: a dictionary containing only the key-value pairs where the value is of the specified output type.
     */
    public func values<Output>(ofType: Output.Type) -> [Key: Output] {
        let values = cache.values(ofType: ExpiringValue.self)

        var nonExpiredValues: [Key: Output] = [:]

        values.forEach { key, expiringValue in
            if
                isExpired(value: expiringValue) == false,
                let output = expiringValue.value as? Output
            {
                nonExpiredValues[key] = output
            }
        }

        return nonExpiredValues
    }

    // MARK: - Private Helpers

    private func isExpired(value: ExpiringValue) -> Bool {
        value.expriation <= Date()
    }
}
