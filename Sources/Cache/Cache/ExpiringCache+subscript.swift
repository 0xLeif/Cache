extension ExpiringCache {
    /**
     Accesses the value associated with the given key for reading and writing.

     - Parameters:
        - key: The key to retrieve the value for.
     - Returns: The value stored in the cache for the given key, or `nil` if it doesn't exist.
     - Notes: If `nil` is assigned to the subscript, then the key-value pair is removed from the cache.
     */
    public subscript(_ key: Key) -> Value? {
        get {
            get(key, as: Value.self)
        }
        set(newValue) {
            guard let newValue = newValue else {
                return remove(key)
            }

            set(value: newValue, forKey: key)
        }
    }

    /**
     Accesses the value associated with the given key for reading and writing, optionally using a default value if the key is missing.

     - Parameters:
        - key: The key to retrieve the value for.
        - default: The default value to be returned if the key is missing.
     - Returns: The value stored in the cache for the given key, or the default value if it doesn't exist.
     */
    public subscript(_ key: Key, default value: Value) -> Value {
        get {
            get(key, as: Value.self) ?? value
        }
        set(newValue) {
            set(value: newValue, forKey: key)
        }
    }
}
