import Foundation

/**
 The `PersistableCache` class is a cache that stores its contents persistently on disk using a JSON file.

 Use `PersistableCache` to create a cache that persists its contents between application launches. The cache contents are automatically loaded from the disk when initialized. You can save the cache whenever using the `save()` function.

 Here's an example of creating a cache, setting a value, and saving it to disk:

 ```swift
 let cache = PersistableCache<String, Double>()

 cache["pi"] = Double.pi

 do {
     try cache.save()
 } catch {
     print("Failed to save cache: \(error)")
 }
 ```

 You can also load a previously saved cache from disk:

 ```swift
 let cache = PersistableCache<String, Double>()

 let pi = cache["pi"] // pi == Double.pi
 ```

 Note: You must make sure that the specified key type conforms to both `RawRepresentable` and `Hashable` protocols. The `RawValue` of `Key` must be a `String` type.

 Error Handling: The save() function may throw errors because either:
    - A`JSONSerialization` error if the encoder fails to serialize the cache contents to JSON.
    - An error if the `data.write(to:)` call fails to write the JSON data to disk.

 Make sure to handle the errors appropriately.
 */
open class PersistableCache<
    Key: RawRepresentable & Hashable, Value
>: Cache<Key, Value> where Key.RawValue == String {
    private let lock: NSLock = NSLock()

    /// The name of the cache. This will be used as the filename when saving to disk.
    public let name: String

    /// The URL of the persistable cache file's directory.
    public let url: URL

    /**
     Loads a persistable cache with a specified name and URL.

     - Parameters:
        - name: A string specifying the name of the cache.
        - url: A URL where the cache file directory will be or is stored.
     */
    public init(
        name: String,
        url: URL
    ) {
        self.name = name
        self.url = url

        var initialValues: [Key: Value] = [:]

        if let fileData = try? Data(contentsOf: url.fileURL(withName: name)) {
            let loadedJSON = JSON<Key>(data: fileData)
            initialValues = loadedJSON.values(ofType: Value.self)
        }

        super.init(initialValues: initialValues)
    }

    /**
     Loads a persistable cache with a specified name and default URL.

     - Parameter name: A string specifying the name of the cache.
     */
    public convenience init(
        name: String
    ) {
        self.init(
            name: name,
            url: URL.defaultFileURL
        )
    }

    /**
     Loads the persistable cache with the given initial values. The `name` is set to `"\(Self.self)"`.

     - Parameter initialValues: A dictionary containing the initial cache contents.
     */
    public required convenience init(initialValues: [Key: Value] = [:]) {
        self.init(name: "\(Self.self)")

        initialValues.forEach { key, value in
            set(value: value, forKey: key)
        }
    }

    /**
     Saves the cache contents to disk.

     - Throws:
        - A `JSONSerialization` error if the encoder fails to serialize the cache contents to JSON.
        - An error if the `data.write(to:)` call fails to write the JSON data to disk.
     */
    public func save() throws {
        lock.lock()
        let json = JSON<Key>(initialValues: allValues)
        let data = try json.data()
        try data.write(to: url.fileURL(withName: name))
        lock.unlock()
    }

    /**
     Deletes the cache file from disk.

     - Throws: An error if the file manager fails to remove the cache file.
     */
    public func delete() throws {
        lock.lock()
        try FileManager.default.removeItem(at: url.fileURL(withName: name))
        lock.unlock()
    }
}

// MARK: - Private Helpers

private extension URL {
    static var defaultFileURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    func fileURL(withName name: String) -> URL {
        guard
            #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
        else { return appendingPathComponent(name) }

        return appending(path: name)
    }
}
