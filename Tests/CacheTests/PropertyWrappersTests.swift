import XCTest
@testable import Cache

final class PropertyWrappersTests: XCTestCase {
    func testCached() {
        struct CachedValueObject {
            enum Key {
                case value
            }

            static let cache = Cache<Key, Any>()

            @Cached(key: Key.value, using: cache, defaultValue: "no value")
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

            @OptionallyCached(key: Key.value, using: cache)
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

            @Resolved(key: Key.value, using: cache)
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
}
