import XCTest
@testable import Cache

final class CacheTests: XCTestCase {
    func testAllValues() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache.allValues.count, 1)
    }

    func testGet_Success() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache.get(.text), "Hello, World!")
    }

    func testGet_MissingKey() {
        enum Key {
            case text
            case missingKey
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNil(cache.get(.missingKey))
    }

    func testGet_InvalidType() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNil(cache.get(.text, as: Int.self))
    }

    func testResolve_Success() throws {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(try cache.resolve(.text), "Hello, World!")
    }

    func testResolve_MissingKey() throws {
        enum Key {
            case text
            case missingKey
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try cache.resolve(.missingKey))
    }

    func testResolve_InvalidType() throws {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try cache.resolve(.text, as: Int.self))
    }

    func testSet() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache()

        cache.set(value: "Hello, World!", forKey: .text)

        XCTAssertEqual(cache.get(.text), "Hello, World!")
    }

    func testRemove() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache.get(.text), "Hello, World!")

        cache.remove(.text)

        XCTAssertNil(cache.get(.text))
    }

    func testContains() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssert(cache.contains(.text))
    }

    func testRequire_Success() throws {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNoThrow(try cache.require(.text))
    }

    func testRequire_Missing() throws {
        enum Key {
            case text
            case missingKey
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try cache.require(.missingKey))
    }

    func testRequireSet_Success() throws {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNoThrow(try cache.require(keys: [.text]))
    }

    func testRequireSet_Missing() throws {
        enum Key {
            case text
            case missingKey
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try cache.require(keys: [.text, .missingKey]))
    }

    func testSubscript_Get() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache[.text], "Hello, World!")
    }

    func testSubscript_Set() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache()

        cache[.text] = "Hello, World!"

        XCTAssertEqual(cache[.text], "Hello, World!")
    }

    func testSubscript_SetNil() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache()

        cache[.text] = nil

        XCTAssertNil(cache[.text])
    }

    func testSubscriptDefault_GetSuccess() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache[.text, default: "missing value"], "Hello, World!")
    }

    func testSubscriptDefault_GetFailure() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache()

        XCTAssertEqual(cache[.text, default: "missing value"], "missing value")
    }

    func testSubscriptDefault_SetSuccess() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache()

        cache[.text, default: ""] = "Hello, World!"

        XCTAssertEqual(cache[.text, default: "missing value"], "Hello, World!")
    }

    func testSubscriptDefault_SetFailure() {
        enum Key {
            case text
        }

        let cache: Cache<Key, String> = Cache()

        XCTAssertEqual(cache[.text, default: "missing value"], "missing value")
    }
}
