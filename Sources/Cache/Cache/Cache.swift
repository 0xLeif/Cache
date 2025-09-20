import Foundation

/**
 `Cache` class provides a cache functionality that can be used to store key-value pairs. It is thread-safe using a locking mechanism.

 You initialize a `Cache` instance with an optional dictionary of initial key-value pairs. You can store, access, and remove values in the cache using key-value patterns. The `Cache` class is also ObservableObject, which means you can observe changes to its dictionary using SwiftUI views.

 Example usage:

 ```swift
 let cache = Cache<String, Int>()
 cache.set(value: 100, forKey: "age")
 let age = cache.get("age") // age is now 100
 ```
 */
open class Cache<Key: Hashable, Value>: Cacheable, @unchecked Sendable {

    /// Lock to synchronize the access to the cache dictionary.
    /// Using NSRecursiveLock to prevent deadlocks with @Published property wrapper
    fileprivate var lock: NSRecursiveLock

    #if os(Linux) || os(Windows)
    fileprivate var cache: [Key: Value] = [:]
    #else
    /// The actual cache dictionary of key-value pairs.
    @Published fileprivate var cache: [Key: Value] = [:]
    #endif

    /**
     Initializes a new `Cache` instance with an optional dictionary of initial key-value pairs.

     - Parameter initialValues: An optional dictionary of initial key-value pairs.
     */
    required public init(initialValues: [Key: Value] = [:]) {
        lock = NSRecursiveLock()
        cache = initialValues
    }

    /**
     Gets a value from the cache for a given key.

     - Parameters:
        - key: The key to retrieve the value for.
        - as: The type the value should be returned as.
     - Returns: The value stored in cache for the given key, or `nil` if it doesn't exist.
     */
    open func get<Output>(_ key: Key, as: Output.Type = Output.self) -> Output? {
        lock.lock()
        defer { lock.unlock() }

        return cache.get(key, as: Output.self)
    }

    /**
     Resolves a value from the cache for a given key.

     - Parameters:
        - key: The key to retrieve the value for.
        - as: The type the value should be returned as.        
     - Returns: The value stored in cache for the given key.
     - Throws: `MissingRequiredKeysError` if the key is missing, or `InvalidTypeError` if the value type is not compatible with the expected type.
     */
    open func resolve<Output>(_ key: Key, as: Output.Type = Output.self) throws -> Output {
        guard contains(key) else {
            throw MissingRequiredKeysError(keys: [key])
        }

        guard let value: Output = get(key) else {
            throw InvalidTypeError(
                expectedType: Output.self,
                actualType: type(of: get(key))
            )
        }

        return value
    }

    /**
     Sets a value in the cache for a given key.

     - Parameters:
        - value: The value to store.
        - key: The key the value should be stored under.
     */
    open func set(value: Value, forKey key: Key) {
        lock.lock()
        cache.set(value: value, forKey: key)
        lock.unlock()
    }

    /**
     Removes a value from the cache for a given key.

     - Parameters:
        - key: The key to remove the value for.
     */
    open func remove(_ key: Key) {
        lock.lock()
        cache.remove(key)
        lock.unlock()
    }

    /**
     Returns a Boolean value indicating whether the cache contains a value for a given key.

     - Parameters:
        - key: The key to check for.
     - Returns: `true` if the key is present in the cache, `false` otherwise.
     */
    open func contains(_ key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }

        return cache.contains(key)
    }

    /**
     Ensures that a set of keys are present in the cache.

     - Parameters:
        - keys: Set of keys that must be present.
     - Throws: `MissingRequiredKeysError` if one or more keys are missing.
     - Returns: The Cache instance.
     */
    open func require(keys: Set<Key>) throws -> Self {
        let missingKeys = keys
            .filter { contains($0) == false }

        guard missingKeys.isEmpty else {
            throw MissingRequiredKeysError(keys: missingKeys)
        }

        return self
    }

    /**
     Ensures that a key is present in the cache.

     - Parameters:
        - key: The key that must be present.
     - Throws: `MissingRequiredKeysError` if the key is missing.
     - Returns: The Cache instance.
     */
    open func require(_ key: Key) throws -> Self {
        try require(keys: [key])
    }

    /**
     Returns a dictionary with all the values of the cache of a given type.

     - Parameters:
        - ofType: The type of the values to return.
     - Returns: A dictionary containing the values of the cache with the specified type.
     */
    open func values<Output>(
        ofType: Output.Type = Output.self
    ) -> [Key: Output] {
        lock.lock(); defer { lock.unlock() }

        return cache.values(ofType: Output.self)
    }
}

#if !os(Linux) && !os(Windows)
extension Cache: ObservableObject { }
#endif

extension Cache {
    /**
     Gets a value from the cache for a given key.

     - Parameters:
        - key: The key to retrieve the value for.
     - Returns: The value stored in cache for the given key, or `nil` if it doesn't exist.
     */
    public func get(_ key: Key) -> Value? {
        get(key, as: Value.self)
    }

    /**
     Resolves a value from the cache for a given key.

     - Parameters:
        - key: The key to retrieve the value for.
     - Returns: The value stored in cache for the given key.
     - Throws: `MissingRequiredKeysError` if the key is missing, or `InvalidTypeError` if the value type is not compatible with the expected type.
     */
    public func resolve(_ key: Key) throws -> Value {
        try resolve(key, as: Value.self)
    }
}
