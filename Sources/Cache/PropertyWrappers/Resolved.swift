/**
 The `Resolved` property wrapper provides a convenient way to access resolved dependencies from a `RequiredKeysCache`. It allows you to specify a key and a cache instance. The property wrapper ensures that the required key is resolved from the cache and provides type safety for accessing the value.
 
 Usage:
 ```swift
 @Resolved(key: "myDependency", cache: myDependencyCache)
 var myDependency: MyDependency
 ```
 
 - Parameters:
 - key: The key associated with the dependency in the cache.
 - cache: The `RequiredKeysCache` instance to resolve the dependency from.
 
 The property wrapper provides a `wrappedValue` that can be accessed and mutated like a regular property. When accessed, the `wrappedValue` resolves the dependency from the cache based on the specified key. When mutated, the `wrappedValue` sets the new dependency value into the cache using the specified key.
 
 - Note: The `Resolved` property wrapper relies on a cache instance that conforms to the `RequiredKeysCache` protocol, specifically designed to efficiently store and retrieve resolved dependencies.
 */
@propertyWrapper public struct Resolved<Key: Hashable, Value> {
    /// The key associated with the dependency in the cache.
    public let key: Key
    
    /// The `RequiredKeysCache` instance to resolve the dependency from.
    public let cache: RequiredKeysCache<Key, Any>
    
    /// The wrapped value that can be accessed and mutated by the property wrapper.
    public var wrappedValue: Value {
        get {
            cache.resolve(requiredKey: key, as: Value.self)
        }
        set {
            cache.set(value: newValue, forKey: key)
        }
    }
    


    #if !os(Windows)
    /**
     Initializes a new instance of the `Resolved` property wrapper.

     - Parameters:
     - key: The key associated with the dependency in the cache.
     - cache: The `RequiredKeysCache` instance to resolve the dependency from. The default is `Global.dependencies`.
     */
    public init(
        key: Key,
        using cache: RequiredKeysCache<Key, Any> = Global.dependencies
    ) {
        self.key = key
        self.cache = cache

        _ = self.cache.requiredKeys.insert(key)
    }
    #else
    /**
     Initializes a new instance of the `Resolved` property wrapper.

     - Parameters:
     - key: The key associated with the dependency in the cache.
     - cache: The `RequiredKeysCache` instance to resolve the dependency from. The default is `Global.dependencies`.
     */
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
