extension Global {
    /// The global cache for storing required dependencies.
    public static let dependencies: RequiredKeysCache<AnyHashable, Any> = RequiredKeysCache()
}
