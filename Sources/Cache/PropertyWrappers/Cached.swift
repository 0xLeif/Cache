/**
 The `Cached` property wrapper provides a convenient way to access values from a cache. It allows you to specify a key, cache instance, and a default value. The property wrapper ensures that the value is always retrieved from the cache and provides type safety for accessing the value.

 Usage:
 ```swift
 @Cached(key: "myKey", cache: myCache, defaultValue: 0)
 var myValue: Int

 // Accessing the value
 let currentValue = myValue

 // Updating the value
 myValue = 42
 ```

 - Parameters:
    - key: The key associated with the value in the cache.
    - cache: The cache instance to retrieve the value from.
    - defaultValue: The default value to be used if the value is not present in the cache.

 The property wrapper provides a `wrappedValue` that can be accessed and mutated like a regular property. When accessed, the `wrappedValue` retrieves the value from the cache based on the specified key. If the value is not present in the cache, the `defaultValue` is used. When mutated, the `wrappedValue` sets the new value into the cache using the specified key.

 - Note: The `Cached` property wrapper relies on a cache instance that conforms to the `Cache` protocol, in order to retrieve and store the values efficiently.
 */
@propertyWrapper public struct Cached<Key: Hashable, Value> {
    /// The key associated with the value in the cache.
    public let key: Key

    /// The cache instance to retrieve the value from.
    public let cache: Cache<Key, Any>

    /// The default value to be used if the value is not present in the cache.
    public let defaultValue: Value

    /// The wrapped value that can be accessed and mutated by the property wrapper.
    public var wrappedValue: Value {
        get {
            cache.get(key, as: Value.self) ?? defaultValue
        }
        set {
            cache.set(value: newValue, forKey: key)
        }
    }


    #if !os(Windows)
    /**
    Initializes a new instance of the `Cached` property wrapper.

    - Parameters:
       - key: The key associated with the value in the cache.
       - cache: The cache instance to retrieve the value from. The default is `Global.cache`.
       - defaultValue: The default value to be used if the value is not present in the cache.
    */
    public init(
        key: Key,
        using cache: Cache<Key, Any> = Global.cache,
        defaultValue: Value
    ) {
        self.key = key
        self.cache = cache
        self.defaultValue = defaultValue
    }
    #else
    /**
    Initializes a new instance of the `Cached` property wrapper.

    - Parameters:
       - key: The key associated with the value in the cache.
       - cache: The cache instance to retrieve the value from.
       - defaultValue: The default value to be used if the value is not present in the cache.
    */
    public init(
        key: Key,
        using cache: Cache<Key, Any>,
        defaultValue: Value
    ) {
        self.key = key
        self.cache = cache
        self.defaultValue = defaultValue
    }
    #endif
}
