# Cache

*A simple, lightweight caching library for Swift.*

## What is Cache?

Cache is a Swift library for caching arbitrary data types in memory. It provides a simple and intuitive API for storing, retrieving, and removing objects from the cache.

## Features

- Generic value type
- Supports JSON serialization and deserialization
- Flexible caching, allowing for multiple Cache objects with different configurations
- Thread-safe implementation

## Installation

### Swift Package Manager (SPM)

Add the following line to your `Package.swift` file in the dependencies array:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/Cache.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

First, import the `Cache` module:

```swift
import Cache
```

Create a cache instance with a generic key-value pair:

```swift
let cache = Cache<CacheKey, String>()
```

Add values to the cache using a key-value syntax:

```swift
cache[.text] = "Hello, World!"
```

Retrieve values using the same key-value syntax:

```swift
let cachedValue = cache[.text]
```

### Multiple Cache Objects

You can create multiple `Cache` objects by specifying a different type of key-value pair:

```swift
let cache1 = Cache<CacheKey, String>()
let imageCache = Cache<URL, UIImage>()
```

### Using JSON

You can use `JSON` to parse and serialize JSON data in the cache:

```swift
let json: JSON<CacheKey> = JSON(data: jsonData)
```

### Removing Values

You can remove values from the cache using the `remove` method:

```swift
cache.remove(.text)
```

You can also just set the value to `nil` using the subscripts

```swift
cache[.text] = nil
```

### Advanced Usage

You can use `Cache` as an observed object:

```swift
struct ExampleView: View {
    enum Key {
        case title
    }

    @ObservedObject var cache = Cache<Key, String>()

    var body: some View {
        TextField(
            "Cache Title",
            text: $cache[.title, default: ""]
        )
    }
}
```

## Cacheable Functions

`Cacheable` protocol defines the following functions which can be used to work with the Cache or JSON.

#### allValues

`allValues` property returns a dictionary containing all the key-value pairs stored in the cache.

```swift
var allValues: [Key: Value] { get }
```

#### init

The `init` function initializes the cache instance with an optional dictionary of key-value pairs.

```swift
init(initialValues: [Key: Value])
```

#### get

The get function retrieves the value of the specified key and casts it to a given output type (if possible).

```swift
func get<Output>(_ key: Key, as: Output.Type) -> Output?
```

Alternatively, calling get with only the key returns the value casted to the default Value type.

```swift
func get(_ key: Key) -> Value?
```

#### resolve

The resolve function retrieves the value of the specified key and casts it to a given output type, but throws an error if the specified key is missing or if the value cannot be casted to the given output type.

```swift
func resolve<Output>(_ key: Key, as: Output.Type) throws -> Output
```

Alternatively, calling resolve with only the key casts the value to the default Value type.

```swift
func resolve(_ key: Key) throws -> Value
```

#### set

The set method sets the specified value for the specified key in the cache.

```swift
func set(value: Value, forKey key: Key)
```

#### remove

The remove method removes the value of the specified key from the cache.

```swift
func remove(_ key: Key)
```

#### contains

The contains method returns a Boolean indicating whether the cache contains the specified key.

```swift
func contains(_ key: Key) -> Bool
```

#### require

The require function ensures that the cache contains the specified key or keys, or else it throws an error.

```swift
func require(_ key: Key) throws -> Self
```

```swift
func require(keys: Set<Key>) throws -> Self
```

#### values

The values function returns a dictionary containing only the key-value pairs where the value is of the specified output type.

```swift
func values<Output>(ofType: Output.Type) -> [Key: Output]
```

The default value for ofType parameter is Value.

## Contributing

If you have improvements or issues, feel free to open an issue or pull request!

## License

Cache is released under the MIT License. See `LICENSE` for details.
