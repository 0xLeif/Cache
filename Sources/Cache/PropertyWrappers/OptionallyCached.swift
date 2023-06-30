/**
 The `OptionallyCached` property wrapper provides a convenient way to optionally access values from a cache. It allows you to specify a key and a cache instance. The property wrapper ensures that the value is retrieved from the cache if present, and provides type safety for accessing the value.
 
 Usage:
 ```swift
 @OptionallyCached(key: "myKey", cache: myCache)
 var myValue: Int?
 
 // Accessing the value
 let currentValue = myValue
 
 // Setting the value
 myValue = 42
 
 // Removing the value from the cache
 myValue = nil
 ```
 
 - Parameters:
 - key: The key associated with the value in the cache.
 - cache: The cache instance to retrieve the value from.
 
 The property wrapper provides a `wrappedValue` that can be accessed and mutated like a regular optional property. When accessed, the `wrappedValue` retrieves the value from the cache based on the specified key. If the value is not present in the cache, `nil` is returned. When mutated, the `wrappedValue` sets the new value into the cache using the specified key. If the new value is `nil`, the key-value pair is removed from the cache.
 
 - Note: The `OptionallyCached` property wrapper relies on a cache instance that conforms to the `Cache` protocol, in order to retrieve and store the values efficiently.
 
 */
@propertyWrapper public struct OptionallyCached<Key: Hashable, Value, CacheSource: Cacheable> where CacheSource.Key == Key, CacheSource.Value == Any {
    /// The key associated with the value in the cache.
    public let key: Key
    
    /// The cache instance to retrieve the value from.
    public var cache: CacheSource

    /// The wrapped value that can be accessed and mutated by the property wrapper.
    public var wrappedValue: Value? {
        get {
            cache.get(key, as: Value.self)
        }
        set {
            guard let newValue = newValue else {
                return cache.remove(key)
            }
            
            cache.set(value: newValue, forKey: key)
        }
    }

    /**
     Initializes a new instance of the `OptionallyCached` property wrapper.

     - Parameters:
     - key: The key associated with the value in the cache.
     - cache: The cache instance to retrieve the value from.
     */
    public init(
        key: Key,
        using cache: CacheSource
    ) {
        self.key = key
        self.cache = cache
    }

    /**
     Initializes a new instance of the `OptionallyCached` property wrapper using the`Global.cache`

     - Parameters:
     - key: The key associated with the value in the cache.
     */
    public init(
        key: Key
    ) where CacheSource == Cache<AnyHashable, Any> {
        self.key = key
        self.cache = Global.cache
    }
}
