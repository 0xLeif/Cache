import Foundation

/**
The `LRUCache` class is a cache that uses the Least Recently Used (LRU) algorithm to evict items when the cache capacity is exceeded. The LRU cache is implemented as a key-value store where the access to items is tracked and the least recently used ones are evicted when the capacity is reached.

Use `LRUCache` to create a cache that automatically evicts items from memory when the cache capacity is exceeded. The cache contents are automatically loaded from the initial values dictionary when initialized.

Note: You must make sure that the specified key type conforms to the `Hashable` protocol.

Error Handling: The set(value:forKey:) function does not throw any error. Instead, when the cache capacity is exceeded, the least recently used item is automatically evicted from the cache.

The `LRUCache` class is a subclass of the `Cache` class. You can use its `capacity` property to specify the maximum number of key-value pairs that the cache can hold.
*/
public class LRUCache<Key: Hashable, Value>: Cache<Key, Value>, @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var keys: [Key]

    /// The maximum capacity of the cache.
    public let capacity: UInt

    /**
     Initializes a new `LRUCache` instance with the specified capacity.

     - Parameter capacity: The maximum number of key-value pairs that the cache can hold.
     */
    public init(capacity: UInt) {
        self.keys = []
        self.capacity = capacity

        super.init()
    }

    /**
     Initializes a new `LRUCache` instance with the specified initial values dictionary.

     The contents of the dictionary are loaded into the cache, and the capacity is set to the number of key-value pairs in the dictionary.

     - Parameter initialValues: A dictionary of key-value pairs to load into the cache initially.
     */
    public required init(initialValues: [Key: Value] = [:]) {
        let keys = Array(initialValues.keys)

        self.keys = keys
        self.capacity = UInt(keys.count)

        super.init(initialValues: initialValues)
    }

    public override func get<Output>(_ key: Key, as: Output.Type = Output.self) -> Output? {
        lock.lock(); defer { lock.unlock() }
        guard let value = super.get(key, as: Output.self) else {
            return nil
        }

        updateKeys(recentlyUsed: key)

        return value
    }

    public override func set(value: Value, forKey key: Key) {
        lock.lock(); defer { lock.unlock() }
        super.set(value: value, forKey: key)

        updateKeys(recentlyUsed: key)
        checkCapacity()
    }

    public override func remove(_ key: Key) {
        lock.lock(); defer { lock.unlock() }
        super.remove(key)

        if let index = keys.firstIndex(of: key) {
            keys.remove(at: index)
        }
    }

    public override func contains(_ key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard super.contains(key) else {
            return false
        }

        updateKeys(recentlyUsed: key)

        return true
    }

    // MARK: - Private Helpers

    private func checkCapacity() {
        guard
            keys.count > capacity,
            let keyToRemove = keys.first
        else { return }

        remove(keyToRemove)
    }

    private func updateKeys(recentlyUsed: Key) {
        if let index = keys.firstIndex(of: recentlyUsed) {
            keys.remove(at: index)
        }

        keys.append(recentlyUsed)
    }
}
