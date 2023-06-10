extension Dictionary: Cacheable {
    /// Initializes the Dictionary instance with an optional dictionary of key-value pairs.
    ///
    /// - Parameter initialValues: the dictionary of key-value pairs (if any) to initialize the cache.
    public init(initialValues: [Key : Value]) {
        self = initialValues
    }

    /**
    Attempts to retrieve the value for the given key, casting it to the specified type.

    - Parameters:
       - key: The key to retrieve the value for.
       - as: The type to cast the retrieved value to.
    - Returns: The casted value for the given key, or `nil` if the key doesn't exist or the cast fails.
    */
    public func get<Item>(_ key: Key, as: Item.Type = Item.self) -> Item? {
        guard let value = self[key] as? Item else {
            return nil
        }

        let mirror = Mirror(reflecting: value)

        if mirror.displayStyle != .optional {
            return value
        }

        if mirror.children.isEmpty {
            return nil
        }

        guard let (_, unwrappedValue) = mirror.children.first else { return nil }

        guard let value = unwrappedValue as? Item else { return nil }

        return value
    }

    /**
     Attempts to retrieve the value for the given key without casting it to a specific type.

     - Parameters:
        - key: The key to retrieve the value for.
     - Returns: The value for the given key, or `nil` if the key doesn't exist.
     */
    public func get(_ key: Key) -> Value? {
        get(key, as: Value.self)
    }

    /**
     Retrieves the value for the given key, casting it to the specified type, or throws an error if the key is missing or the cast fails.

     - Parameters:
        - key: The key to retrieve the value for.
        - as: The type to cast the retrieved value to.
     - Returns: The casted value for the given key.
     - Throws: A `MissingRequiredKeysError` if the key is missing, or an `InvalidTypeError` if the value couldn't be casted to the specified type.
     */
    public func resolve<Item>(_ key: Key, as: Item.Type = Item.self) throws -> Item {
        guard contains(key) else {
            throw MissingRequiredKeysError(keys: [key])
        }

        guard let value: Item = get(key) else {
            throw InvalidTypeError(
                expectedType: Item.self,
                actualType: type(of: get(key))
            )
        }

        return value
    }

    /**
     Retrieves the value for the given key, or throws an error if the key is missing.

     - Parameters:
        - key: The key to retrieve the value for.
     - Returns: The value for the given key.
     - Throws: A `MissingRequiredKeysError` if the key is missing.
     */
    public func resolve(_ key: Key) throws -> Value {
        try resolve(key, as: Value.self)
    }

    /**
     Sets the value for the given key in the dictionary.

     - Parameters:
        - value: The value to set.
        - forKey: The key to associate with the value.
     */
    public mutating func set(value: Value, forKey key: Key) {
        self[key] = value
    }

    /**
    Removes the value for the given key from the dictionary.

    - Parameters:
       - key: The key to remove the value for.
    */
    public mutating func remove(_ key: Key) {
        self[key] = nil
    }

    /**
     Checks if the dictionary contains a value for the given key.

     - Parameters:
        - key: The key to check for.
     - Returns: `true` if the dictionary contains the key, otherwise `false`.
     */
    public func contains(_ key: Key) -> Bool {
        self[key] != nil
    }

    /**
     Checks if the dictionary contains all of the required keys.

     - Parameters:
        - keys: The set of keys to check the dictionary for.
     - Returns: The dictionary instance.
     - Throws: A `MissingRequiredKeysError` if one or more of the required keys are missing.
     */
    @discardableResult
    public func require(keys: Set<Key>) throws -> Self {
        let missingKeys = keys
            .filter { contains($0) == false }

        guard missingKeys.isEmpty else {
            throw MissingRequiredKeysError(keys: missingKeys)
        }

        return self
    }

    /**
     Checks if the dictionary contains the required key.

     - Parameters:
        - key: The key to check the dictionary for.
     - Returns: The dictionary instance.
     - Throws: A `MissingRequiredKeysError` if the required key is missing.
     */
    @discardableResult
    public func require(_ key: Key) throws -> Self {
        try require(keys: [key])
    }

    /**
     Filters the dictionary by returning values of a specific type.

     - Parameters:
        - ofType: The type to filter the dictionary by.
     - Returns: A new dictionary containing only values of the specified type.
     */
    public func values<Item>(
        ofType: Item.Type = Item.self
    ) -> [Key: Item] {
        compactMapValues { $0 as? Item }
    }

    /**
     Returns a new dictionary containing the keys and values resulting from applying the given transformation to each element in the original dictionary.

     - Parameters:
       - transform: A closure that takes a key-value pair from the dictionary as its argument and returns a tuple containing a new key and a new value. The returned tuple must have two elements of the same type as the expected output for this method.

     - Returns: A new dictionary containing the transformed keys and values.
     */
    public func mapDictionary<NewKey: Hashable, NewValue>(
        _ transform: (Key, Value) -> (NewKey, NewValue)
    ) -> [NewKey: NewValue] {
        compactMapDictionary(transform)
    }

    /**
     Returns a new dictionary containing only the key-value pairs that have non-nil values resulting from applying the given transformation to each element in the original dictionary.

     - Parameters:
       - transform: A closure that takes a key-value pair from the dictionary as its argument and returns an optional tuple containing a new key and a new value. Each non-nil key-value pair will be included in the returned dictionary.

     - Returns: A new dictionary containing the non-nil transformed keys and values.
     */
    public func compactMapDictionary<NewKey: Hashable, NewValue>(
        _ transform: (Key, Value) -> (NewKey, NewValue)?
    ) -> [NewKey: NewValue] {
        var dictionary: [NewKey: NewValue] = [:]

        for (key, value) in self {
            if let (newKey, newValue) = transform(key, value) {
                dictionary[newKey] = newValue
            }
        }

        return dictionary
    }
}
