#if !os(Windows)
public struct ComposableCache<Key: Hashable>: Cacheable {
    private let caches: [AnyCacheable]

    public init(caches: [any Cacheable]) {
        self.caches = caches.map { AnyCacheable($0) }
    }

    public init(initialValues: [Key: Any]) {
        self.init(caches: [Cache(initialValues: initialValues)])
    }

    public func get<Output>(
        _ key: Key,
        as: Output.Type = Output.self
    ) -> Output? {
        for cache in caches {
            guard
                let output = cache.get(key, as: Output.self)
            else {
                continue
            }

            return output
        }

        return nil
    }

    public func resolve<Output>(
        _ key: Key,
        as: Output.Type = Output.self
    ) throws -> Output {
        for cache in caches {
            guard
                let output = try? cache.resolve(key, as: Output.self)
            else {
                continue
            }

            return output
        }

        throw MissingRequiredKeysError(keys: [key])
    }

    public func set(value: Any, forKey key: Key) {
        for cache in caches {
            cache.set(value: value, forKey: key)
        }
    }

    public func remove(_ key: Key) {
        for cache in caches {
            cache.remove(key)
        }
    }

    public func contains(_ key: Key) -> Bool {
        for cache in caches {
            if cache.contains(key) {
                return true
            }
        }

        return false
    }

    public func require(keys: Set<Key>) throws -> ComposableCache<Key> {
        for cache in caches {
            _ = try cache.require(keys: keys)
        }

        return self
    }

    public func require(_ key: Key) throws -> ComposableCache<Key> {
        for cache in caches {
            _ = try cache.require(key)
        }

        return self
    }

    public func values<Output>(ofType: Output.Type) -> [Key: Output] {
        for cache in caches {
            let values = cache.values(ofType: Output.self).compactMapKeys { $0 as? Key }

            guard values.keys.count != 0 else {
                continue
            }

            return values
        }

        return [:]
    }
}
#endif
