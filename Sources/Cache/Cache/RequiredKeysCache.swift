///  The `RequiredKeysCache` class is a subclass of `Cache` that allows you to define a set of required keys. This cache ensures that the required keys are always present and throws an error if any of them are missing.
public class RequiredKeysCache<Key: Hashable, Value>: Cache<Key, Value> {

    /// The set of keys that must always be present in the cache.
    public var requiredKeys: Set<Key> {
        didSet {
            for key in requiredKeys {
                _ = resolve(requiredKey: key)
            }
        }
    }

    /**
    Initializes a new instance of `RequiredKeysCache` with the specified required keys and initial values.

    - Parameters:
        - requiredKeys: A set of keys that must always be present in the cache.
        - initialValues: A dictionary of initial key-value pairs to populate the cache.
    */
    public init(
        requiredKeys: Set<Key>,
        initialValues: [Key: Value]
    ) {
        self.requiredKeys = requiredKeys

        super.init(initialValues: initialValues)

        do {
            _ = try require(keys: requiredKeys)
        }

        catch { fatalError(error.localizedDescription) }
    }

    /**
    Initializes a new instance of `RequiredKeysCache` with the specified initial values. The required keys are automatically inferred from the initial values.

    - Parameters:
        - initialValues: A dictionary of initial key-value pairs to populate the cache. The keys are considered as required keys.
    */
    public required convenience init(initialValues: [Key: Value] = [:]) {
        self.init(requiredKeys: Set(initialValues.keys), initialValues: initialValues)
    }

    /**
   Removes a key-value pair from the cache. If the key is one of the required keys, it is not removed.

   - Parameters:
       - key: The key of the value to remove.
   */
    public override func remove(_ key: Key) {
        guard requiredKeys.contains(key) == false else { return }

        super.remove(key)
    }

    /**
    Resolves a required key from the cache, ensuring its presence and returning its value.

    - Parameters:
        - requiredKey: The required key to resolve.
        - as: The type to expect as the value of the key. The default is `Output.self`.

    - Returns: The resolved value for the required key.
    - Throws: A runtime error if the required key is not present in the cache or if the expected value type is incorrect.
    */
    public func resolve<Output>(requiredKey: Key, as: Output.Type = Output.self) -> Output {
        guard
            requiredKeys.contains(requiredKey)
        else { fatalError("The key '\(requiredKey)' is not a Required Key.") }

        guard
            contains(requiredKey)
        else { fatalError("Required Key Missing: '\(requiredKey)'") }

        do {
            return try resolve(requiredKey, as: Output.self)
        }

        catch { fatalError(error.localizedDescription) }
    }

    /**
    Resolves a required key from the cache, ensuring its presence and returning its value.

    - Parameter requiredKey: The required key to resolve.

    - Returns: The resolved value for the required key.
    */
    public func resolve(requiredKey: Key) -> Value {
        resolve(requiredKey: requiredKey, as: Value.self)
    }

    /**
    Updates the value of a required key in the cache using a closure.

    - Parameters:
        - requiredKey: The required key to update.
        - as: The type to expect as the value of the key. The default is `CacheValue.self`.
        - block: A closure that takes the current value of the required key and returns the new value.

    - Returns: The updated value for the required key.
    */
    @discardableResult
    public func update<CacheValue>(
        requiredKey key: Key,
        as: CacheValue.Type = CacheValue.self,
        block: (CacheValue) -> Value
    ) -> Value {
        let newValue = block(resolve(requiredKey: key, as: CacheValue.self))

        set(value: newValue, forKey: key)

        return newValue
    }

    /**
    Updates the value of a required key in the cache using a closure.

    - Parameters:
        - requiredKey: The required key to update.
        - block: A closure that takes the current value of the required key and returns the new value.

    - Returns: The updated value for the required key.
    */
    @discardableResult
    public func update(
        requiredKey key: Key,
        block: (Value) -> Value
    ) -> Value {
        update(
            requiredKey: key,
            as: Value.self,
            block: block
        )
    }

    /**
    Uses the value of a required key from the cache in a closure and returns a result.

    - Parameters:
        - requiredKey: The required key to use.
        - as: The type to expect as the value of the key. The default is `CacheValue.self`.
        - block: A closure that takes the value of the required key and returns a result.

    - Returns: The result of the closure evaluation.
    */
    @discardableResult
    public func use<CacheValue, Output>(
        requiredKey key: Key,
        as: CacheValue.Type = CacheValue.self,
        block: (CacheValue) -> Output?
    ) -> Output? {
        block(resolve(requiredKey: key, as: CacheValue.self))
    }

    /**
    Uses the value of a required key from the cache in a closure.

    - Parameters:
        - requiredKey: The required key to use.
        - as: The type to expect as the value of the key. The default is `CacheValue.self`.
        - block: A closure that takes the value of the required key.

    */
    public func use<CacheValue>(
        requiredKey key: Key,
        as: CacheValue.Type = CacheValue.self,
        block: (CacheValue) -> Void
    ) {
        block(resolve(requiredKey: key, as: CacheValue.self))
    }

    /**
    Uses the value of a required key from the cache in a closure and returns a result.

    - Parameters:
        - requiredKey: The required key to use.
        - block: A closure that takes the value of the required key and returns a result.

    - Returns: The result of the closure evaluation.
    */
    @discardableResult
    public func use<Output>(
        requiredKey key: Key,
        block: (Value) -> Output?
    ) -> Output? {
        use(
            requiredKey: key,
            as: Value.self,
            block: block
        )
    }

    /**
    Uses the value of a required key from the cache in a closure.

    - Parameters:
        - requiredKey: The required key to use.
        - block: A closure that takes the value of the required key.

    */
    public func use(
        requiredKey key: Key,
        block: (Value) -> Void
    ) {
        use(
            requiredKey: key,
            as: Value.self,
            block: block
        )
    }
}
