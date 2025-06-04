import Foundation

public struct JSON<Key: RawRepresentable & Hashable>: Cacheable, @unchecked Sendable where Key.RawValue == String {
    private let lock = NSLock()
    private var cache: [Key: Any]

    /**
     A dictionary containing all keys and values in the JSON object.
     */
    public var allValues: [Key: Any] {
        values(ofType: Any.self)
    }

    /**
     Initializes the JSON object with the given initial values.

     - Parameters:
        - initialValues: A dictionary of initial key-value pairs.
     */
    public init(initialValues: [Key: Any] = [:]) {
        self.cache = initialValues
    }

    /**
     Initializes the JSON object with data from the given Data object.

     - Parameters:
        - data: The JSON data to parse and use as the object's initial values.
     */
    public init(data: Data) {
        var initialValues: [Key: Any] = [:]

        if
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonDictionary: [String: Any] = json as? [String: Any]
        {
            jsonDictionary.forEach { jsonKey, jsonValue in
                guard let key = Key(rawValue: jsonKey) else { return }

                initialValues[key] = jsonValue
            }
        }

        self.init(initialValues: initialValues)
    }

    /**
     Parses an array of JSON objects from the given Data object.

     - Parameters:
        - data: The JSON data to parse.
     - Returns: An array of parsed JSON objects.
     */
    public static func array(data: Data) -> [JSON] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonArray = json as? [Any]
        else { return [] }

        return jsonArray.compactMap { jsonObject in
            guard let jsonDictionary = jsonObject as? [String: Any] else { return nil }

            return JSON(
                initialValues: jsonDictionary.compactMapDictionary { jsonKey, jsonValue in
                    guard let key = Key(rawValue: jsonKey) else { return nil }

                    return (key, jsonValue)
                }
            )
        }
    }

    /**
     Returns a `Data` object representing the JSON-encoded key-value pairs transformed into a dictionary where their keys are the raw values of their associated enum cases.

     - Throws: `JSONSerialization.data(withJSONObject:)` errors, if any.

     - Returns: A `Data` object that encodes the key-value pairs.
     */
    public func data() throws -> Data {
        try JSONSerialization.data(
            withJSONObject: allValues.mapKeys(\.rawValue)
        )
    }

    /**
    Retrieves a nested JSON object within the current object.

    - Parameters:
       - key: The key for the nested JSON value.
       - keyed: The type of the keyed enumeration that contains the nested JSON object (used to define the return type).
    - Returns: A nested JSON object of the specified type if it exists within the current object, otherwise `nil`.
    */
    public func json<JSONKey: RawRepresentable & Hashable>(
        _ key: Key,
        keyed: JSONKey.Type = JSONKey.self
    ) -> JSON<JSONKey>? {
        lock.lock(); defer { lock.unlock() }
        let value = cache[key]
        var jsonDictionary: JSON<JSONKey>?

        if let data = value as? Data {
            jsonDictionary = JSON<JSONKey>(data: data)
        } else if let dictionary = value as? [String: Any] {
            jsonDictionary = JSON<JSONKey>(
                initialValues: dictionary.compactMapKeys { key in
                    guard let key = JSONKey(rawValue: key) else {
                        return nil
                    }

                    return key
                }
            )
        } else if let dictionary = value as? [JSONKey: Any] {
            jsonDictionary = JSON<JSONKey>(initialValues: dictionary)
        } else if let json = value as? JSON<JSONKey> {
            jsonDictionary = json
        }

        return jsonDictionary
    }

    /**
     Retrieves an array of nested JSON objects within the current object.

     - Parameters:
        - key: The key for the nested JSON array.
        - keyed: The type of the keyed enumeration that contains the nested JSON object (used to define the return type).
     - Returns: An array of nested JSON objects of the specified type if they exist within the current object, otherwise `nil`.
     */
    public func array<JSONKey: RawRepresentable & Hashable>(
        _ key: Key,
        keyed: JSONKey.Type = JSONKey.self
    ) -> [JSON<JSONKey>]? {
        lock.lock(); defer { lock.unlock() }
        let value = cache[key]
        var jsonArray: [JSON<JSONKey>]?

        if let data = value as? Data {
            jsonArray = JSON<JSONKey>.array(data: data)
        } else if let array = value as? [[String: Any]] {
            jsonArray = array.compactMap { json in
                guard
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                else { return nil }

                return JSON<JSONKey>(data: jsonData)
            }
        } else if let array = value as? [[JSONKey: Any]] {
            jsonArray = array.map { json in
                JSON<JSONKey>(initialValues: json)
            }
        } else if let json = value as? [JSON<JSONKey>] {
            jsonArray = json
        }

        return jsonArray
    }

    /**
     Retrieves the value for the given key, casting it to the specified type if possible.

     - Parameters:
        - key: The key to retrieve the value for.
        - as: The type to cast the retrieved value to.
     - Returns: The value for the given key, or `nil` if the key doesn't exist or the cast fails.
     */
    public func get<Value>(_ key: Key, as: Value.Type = Value.self) -> Value? {
        lock.lock(); defer { lock.unlock() }
        return cache.get(key, as: Value.self)
    }

    /**
     Retrieves the value for the given key, casting it to the specified type if possible, or throws an error if the key is missing or the cast fails.

     - Parameters:
        - key: The key to retrieve the value for.
        - as: The type to cast the retrieved value to.
     - Returns: The value for the given key, casted to the specified type.
     - Throws: A `MissingRequiredKeysError` if the key is missing, or an `InvalidTypeError` if the value couldn't be casted to the specified type.
     */
    public func resolve<Value>(_ key: Key, as: Value.Type = Value.self) throws -> Value {
        lock.lock(); defer { lock.unlock() }
        return try cache.resolve(key, as: Value.self)
    }

    /**
     Sets the value for the given key in the JSON object.

     - Parameters:
        - value: The value to set.
        - forKey: The key to associate with the value.
     */
    public mutating func set<Value>(value: Value, forKey key: Key) {
        lock.lock()
        cache.set(value: value, forKey: key)
        lock.unlock()
    }

    /**
     Removes the value for the given key from the JSON object.

     - Parameters:
        - key: The key to remove the value for.
     */
    public mutating func remove(_ key: Key) {
        lock.lock()
        cache.remove(key)
        lock.unlock()
    }

    /**
     Checks if the JSON object contains a value for the given key.

     - Parameters:
        - key: The key to check for.
     - Returns: `true` if the object contains the key, otherwise `false`.
     */
    public func contains(_ key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cache.contains(key)
    }

    /**
     Checks if the JSON object contains all of the required keys.

     - Parameters:
        - keys: The set of keys to check the object for.
     - Returns: The object instance.
     - Throws: A `MissingRequiredKeysError` if one or more of the required keys are missing.
     */
    @discardableResult
    public func require(keys: Set<Key>) throws -> Self {
        lock.lock(); defer { lock.unlock() }
        try cache.require(keys: keys)

        return self
    }

    /**
     Checks if the JSON object contains the required key.

     - Parameters:
        - key: The key to check the object for.
     - Returns: The object instance.
     - Throws: A `MissingRequiredKeysError` if the required key is missing.
     */
    @discardableResult
    public func require(_ key: Key) throws -> Self {
        lock.lock(); defer { lock.unlock() }
        try cache.require(key)

        return self
    }

    /**
     Filters the JSON object by returning values of a specific type.

     - Parameters:
        - type: The type to filter the object by.
     - Returns: A new dictionary containing only values of the specified type.
     */
    public func values<Value>(
        ofType type: Value.Type = Value.self
    ) -> [Key: Value] {
        lock.lock(); defer { lock.unlock() }
        return cache.values(ofType: type)
    }
}
