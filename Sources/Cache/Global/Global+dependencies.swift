extension Global {
    /// The global cache for storing required dependencies.
    public static var dependencies: RequiredKeysCache<AnyHashable, Any> = RequiredKeysCache()
}
