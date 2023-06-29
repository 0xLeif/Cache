extension RequiredKeysCache {
    /**
     Accesses the value associated with the given required key for reading and writing, optionally using a default value if the key is missing.

     - Parameters:
        - requiredKey: The required key to retrieve the value for.
        - default: The default value to be returned if the key is missing.
     - Returns: The value stored in the cache for the given key, or the default value if it doesn't exist.
     */
    public subscript(requiredKey key: Key) -> Value {
        get {
            resolve(requiredKey: key, as: Value.self)
        }
        set(newValue) {
            set(value: newValue, forKey: key)
        }
    }
}
