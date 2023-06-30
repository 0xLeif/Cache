public protocol CacheInitializable {
    associatedtype OriginCache: Cacheable

    init(cache: OriginCache)
}
