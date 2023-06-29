import XCTest
@testable import Cache

final class RequiredKeysCacheTests: XCTestCase {
    func testRequiredKeysCache() {
        enum Key {
            case pi
            case text
        }

        let cache: RequiredKeysCache<Key, String> = RequiredKeysCache(
            initialValues: [
                .pi: Double.pi.description,
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache[requiredKey: .text], "Hello, World!")

        // Unable to remove required keys
        cache.remove(.text)

        XCTAssertEqual(cache[requiredKey: .text], "Hello, World!")

        // Remove required key
        cache.requiredKeys.remove(.text)

        // Use normal subscript since .text isn't required
        XCTAssertEqual(cache[.text], "Hello, World!")

        cache.remove(.text)

        XCTAssertFalse(cache.contains(.text))
    }

    func testRequiredKeysCache_update() {
        enum Key {
            case pi
            case text
        }

        let cache: RequiredKeysCache<Key, String> = RequiredKeysCache(
            initialValues: [
                .pi: Double.pi.description,
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache[requiredKey: .text], "Hello, World!")

        cache.update(requiredKey: .text) { text in
            text + text
        }

        XCTAssertEqual(cache[requiredKey: .text], "Hello, World!Hello, World!")

        cache[requiredKey: .text] = "Hello, World!"

        XCTAssertEqual(cache[requiredKey: .text], "Hello, World!")
    }

    func testRequiredKeysCache_use() {
        enum Key {
            case pi
            case text
        }

        let cache: RequiredKeysCache<Key, String> = RequiredKeysCache(
            initialValues: [
                .pi: Double.pi.description,
                .text: "Hello, World!"
            ]
        )

        cache.use(requiredKey: .text) { text in
            XCTAssertEqual(text, "Hello, World!")
        }
    }

    func testRequiredKeysCache_useOutput() {
        enum Key {
            case pi
            case text
        }

        let cache: RequiredKeysCache<Key, String> = RequiredKeysCache(
            initialValues: [
                .pi: Double.pi.description,
                .text: "Hello, World!"
            ]
        )

        let text = cache.use(requiredKey: .text) { text in
            "Hello, World!Hello, World!"
        }

        XCTAssertEqual(text, "Hello, World!Hello, World!")
        XCTAssertEqual(cache[requiredKey: .text], "Hello, World!")
    }
}
