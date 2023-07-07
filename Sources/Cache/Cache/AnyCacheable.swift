#if !os(Windows)
public class AnyCacheable: Cacheable {
    public typealias Key = AnyHashable
    public typealias Value = Any

    private var cache: any Cacheable

    private var cacheGet: ((AnyHashable) -> Any?)!
    private var cacheResolve: ((AnyHashable) throws -> Any)!
    private var cacheSet: ((Any, AnyHashable) -> Void)!
    private var cacheRemove: ((AnyHashable) -> Void)!
    private var cacheContains: ((AnyHashable) -> Bool)!
    private var cacheRequireKeys: ((Set<AnyHashable>) throws -> Void)!
    private var cacheRequireKey: ((AnyHashable) throws -> Void)!
    private var cacheValues: (() -> [AnyHashable: Any])!

    public init<InnerCache: Cacheable>(_ cache: InnerCache) {
        self.cache = cache

        self.cacheGet = { key in
            guard let key = key as? InnerCache.Key else { return nil }

            return cache.get(key, as: Any.self)
        }

        self.cacheResolve = { key in
            guard
                let key = key as? InnerCache.Key
            else { throw MissingRequiredKeysError(keys: [key]) }

            return try cache.resolve(key, as: Any.self)
        }

        self.cacheSet = { value, key in
            guard
                let value = value as? InnerCache.Value,
                let key = key as? InnerCache.Key
            else { return }

            var mutableCache = cache

            mutableCache.set(value: value, forKey: key)

            self.cache = mutableCache
        }

        self.cacheRemove = { key in
            guard let key = key as? InnerCache.Key else { return }

            var mutableCache = cache

            mutableCache.remove(key)

            self.cache = mutableCache
        }

        self.cacheContains = { key in
            guard
                let key = key as? InnerCache.Key
            else { return false }

            return cache.contains(key)
        }

        self.cacheRequireKeys = { keys in
            let validKeys: Set<InnerCache.Key> = Set(keys.compactMap { $0 as? InnerCache.Key })

            guard
                validKeys.count == keys.count
            else { throw MissingRequiredKeysError(keys: keys.subtracting(validKeys)) }

            _ = try cache.require(keys: validKeys)
        }

        self.cacheRequireKey = { key in
            guard
                let key = key as? InnerCache.Key
            else { throw MissingRequiredKeysError(keys: [key]) }

            _ = try cache.require(key)
        }

        self.cacheValues = {
            cache.values(ofType: Any.self)
        }
    }

    required public convenience init(initialValues: [AnyHashable: Any]) {
        self.init(Cache(initialValues: initialValues))
    }

    public func get<Output>(
        _ key: AnyHashable,
        as: Output.Type = Output.self
    ) -> Output? {
        guard let value = cacheGet(key) else {
            return nil
        }

        guard let output = value as? Output else {
            return nil
        }

        return output
    }

    public func resolve<Output>(
        _ key: AnyHashable,
        as: Output.Type = Output.self
    ) throws -> Output {
        let resolvedValue = try cacheResolve(key)

        guard let output = resolvedValue as? Output else {
            throw InvalidTypeError(
                expectedType: Output.self,
                actualType: type(of: get(key, as: Any.self))
            )
        }

        return output
    }

    public func set(value: Value, forKey key: AnyHashable) {
        cacheSet(value, key)
    }

    public func remove(_ key: AnyHashable) {
        cacheRemove(key)
    }

    public func contains(_ key: AnyHashable) -> Bool {
        cacheContains(key)
    }

    public func require(keys: Set<AnyHashable>) throws -> Self {
        try cacheRequireKeys(keys)

        return self
    }

    public func require(_ key: AnyHashable) throws -> Self {
        try cacheRequireKey(key)

        return self
    }

    public func values<Output>(ofType: Output.Type) -> [AnyHashable: Output] {
        cacheValues().compactMapValues { value in
            value as? Output
        }
    }
}
#endif
