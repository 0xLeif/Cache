import XCTest
@testable import Cache

final class PropertyWrappersTests: XCTestCase {
    func testCached() {
        struct CachedValueObject {
            enum Key {
                case value
            }

            static let cache = ExpiringCache<Key, Any>(duration: .minutes(2))

            @Cached(key: .value, using: cache, defaultValue: "no value")
            var someValue: String
        }

        var object = CachedValueObject()

        XCTAssertEqual(object.someValue, "no value")

        object.someValue = "Hello, World"

        let cachedObject = CachedValueObject()

        XCTAssertEqual(object.someValue, "Hello, World")
        XCTAssertEqual(cachedObject.someValue, "Hello, World")
    }

    func testOptionallyCached() {
        struct CachedValueObject {
            enum Key {
                case value
            }

            static let cache = Cache<Key, Any>()

            @OptionallyCached(key: .value, using: cache)
            var someValue: String?
        }

        var object = CachedValueObject()

        XCTAssertNil(object.someValue)

        object.someValue = "Hello, World"

        let cachedObject = CachedValueObject()

        XCTAssertEqual(object.someValue, "Hello, World")
        XCTAssertEqual(cachedObject.someValue, "Hello, World")

        object.someValue = nil

        XCTAssertNil(object.someValue)
        XCTAssertNil(cachedObject.someValue)
    }

    func testResolved() {
        struct CachedValueObject {
            enum Key {
                case pi
                case value
            }

            static let cache = RequiredKeysCache<Key, Any>()

            @Resolved(key: .value, using: cache)
            var someValue: String
        }

        CachedValueObject.cache.set(value: "init", forKey: .value)
        
        var object = CachedValueObject()

        XCTAssertEqual(object.someValue, "init")

        object.someValue = "Hello, World"

        let cachedObject = CachedValueObject()

        XCTAssertEqual(object.someValue, "Hello, World")
        XCTAssertEqual(cachedObject.someValue, "Hello, World")
    }

    func testGlobalCached() {
        struct CachedValueObject {
            enum Key {
                case value
            }

            @Cached(key: Key.value, defaultValue: "no value")
            var someValue: String
        }

        var object = CachedValueObject()

        XCTAssertEqual(object.someValue, "no value")

        object.someValue = "Hello, World"

        let cachedObject = CachedValueObject()

        XCTAssertEqual(object.someValue, "Hello, World")
        XCTAssertEqual(cachedObject.someValue, "Hello, World")
    }

    func testGloballyOptionallyCached() {
        struct CachedValueObject {
            enum Key {
                case value
            }

            @OptionallyCached(key: Key.value)
            var someValue: String?
        }

        var object = CachedValueObject()

        XCTAssertNil(object.someValue)

        object.someValue = "Hello, World"

        let cachedObject = CachedValueObject()

        XCTAssertEqual(object.someValue, "Hello, World")
        XCTAssertEqual(cachedObject.someValue, "Hello, World")

        object.someValue = nil

        XCTAssertNil(object.someValue)
        XCTAssertNil(cachedObject.someValue)
    }

    func testGloballyResolved() {
        struct CachedValueObject {
            enum Key {
                case pi
                case value
            }

            @Resolved(key: Key.value)
            var someValue: String
        }

        Global.dependencies.set(value: "init", forKey: CachedValueObject.Key.value)

        var object = CachedValueObject()

        XCTAssertEqual(object.someValue, "init")

        object.someValue = "Hello, World"

        let cachedObject = CachedValueObject()

        XCTAssertEqual(object.someValue, "Hello, World")
        XCTAssertEqual(cachedObject.someValue, "Hello, World")
    }
}
