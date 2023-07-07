public protocol Cacheable {
    associatedtype Key: Hashable
    associatedtype Value

    /// Returns a dictionary containing all the key value pairs of the cache.
    var allValues: [Key: Value] { get }

    /// Initializes the Cache instance with an optional dictionary of key-value pairs.
    ///
    /// - Parameter initialValues: the dictionary of key-value pairs (if any) to initialize the cache.
    init(initialValues: [Key: Value])

    /// Gets the value for the specified key and casts it to the specified output type (if possible).
    ///
    /// - Parameters:
    ///   - key: the key to look up in the cache.
    ///   - as: the type to cast the value to.
    /// - Returns: the value of the specified key casted to the output type (if possible).
    func get<Output>(_ key: Key, as: Output.Type) -> Output?

    /// Resolves the value for the specified key and casts it to the specified output type.
    ///
    /// - Parameters:
    ///   - key: the key to look up in the cache.
    ///   - as: the type to cast the value to.
    /// - Throws: InvalidTypeError if the specified key is missing or if the value cannot be casted to the specified output type.
    /// - Returns: the value of the specified key casted to the output type.
    func resolve<Output>(_ key: Key, as: Output.Type) throws -> Output

    /// Sets the value for the specified key.
    ///
    /// - Parameters:
    ///   - value: the value to store in the cache.
    ///   - key: the key to use for storing the value in the cache.
    mutating func set(value: Value, forKey key: Key)

    /// Removes the value for the specified key from the cache.
    ///
    /// - Parameter key: the key to remove from the cache.
    mutating func remove(_ key: Key)

    /// Checks whether the cache contains the specified key.
    ///
    /// - Parameter key: the key to look up in the cache.
    /// - Returns: true if the cache contains the key, false otherwise.
    func contains(_ key: Key) -> Bool

    /// Checks whether the cache contains all the specified keys.
    ///
    /// - Parameter keys: the set of keys to require.
    /// - Throws: MissingRequiredKeysError if any of the specified keys are missing from the cache.
    /// - Returns: self (the Cache instance).
    func require(keys: Set<Key>) throws -> Self

    /// Checks whether the cache contains the specified key.
    ///
    /// - Parameter key: the key to require.
    /// - Throws: MissingRequiredKeysError if the specified key is missing from the cache.
    /// - Returns: self (the Cache instance).
    func require(_ key: Key) throws -> Self

    /// Returns a dictionary containing only the key-value pairs where the value is of the specified output type.
    ///
    /// - Parameter ofType: the type of values to include in the dictionary (defaults to Value).
    /// - Returns: a dictionary containing only the key-value pairs where the value is of the specified output type.
    func values<Output>(ofType: Output.Type) -> [Key: Output]
}

public extension Cacheable {
    var allValues: [Key: Value] {
        values(ofType: Value.self)
    }
}
