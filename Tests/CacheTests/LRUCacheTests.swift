import XCTest
@testable import Cache

final class LRUCacheTests: XCTestCase {
    func testLRUCacheCapacity() {
        let cache = LRUCache<String, Int>(capacity: 3)

        // Add some key-value pairs
        cache["one"] = 1
        cache["two"] = 2
        cache["three"] = 3

        // Test that the cache has the expected contents
        XCTAssertEqual(cache["one"], 1)
        XCTAssertEqual(cache["two"], 2)
        XCTAssertEqual(cache["three"], 3)

        // Add a new key-value pair to exceed the capacity
        cache["four"] = 4

        // Test that the least recently used key was removed
        XCTAssertNil(cache["one"])

        // Test that the cache has the expected contents
        XCTAssertEqual(cache["two"], 2)
        XCTAssertEqual(cache["three"], 3)
        XCTAssertEqual(cache["four"], 4)

        // Access an existing key to promote it to the end of the keys array
        XCTAssert(cache.contains("two"))

        // Add another key-value pair to exceed the capacity
        cache["five"] = 5

        // Test that the least recently used key was removed
        XCTAssertNil(cache["three"])

        // Test that the cache has the expected contents
        XCTAssertEqual(cache["two"], 2)
        XCTAssertEqual(cache["four"], 4)
        XCTAssertEqual(cache["five"], 5)

        // Remove a key and test that it was removed from both the cache and the keys array
        cache["two"] = nil
        XCTAssertNil(cache["two"])
        XCTAssertFalse(cache.contains("two"))
    }

    func testLRUCacheInitialValues() {
        let cache = LRUCache<String, Int>(
            initialValues: [
                "one": 1,
                "two": 2,
                "three": 3
            ]
        )

        // Test that the cache has the expected contents
        XCTAssertEqual(cache["one"], 1)
        XCTAssertEqual(cache["two"], 2)
        XCTAssertEqual(cache["three"], 3)

        // Add a new key-value pair to exceed the capacity
        cache["four"] = 4

        // Test that the least recently used key was removed
        XCTAssertNil(cache["one"])

        // Test that the cache has the expected contents
        XCTAssertEqual(cache["two"], 2)
        XCTAssertEqual(cache["three"], 3)
        XCTAssertEqual(cache["four"], 4)

        // Access an existing key to promote it to the end of the keys array
        XCTAssert(cache.contains("two"))

        // Add another key-value pair to exceed the capacity
        cache["five"] = 5

        // Test that the least recently used key was removed
        XCTAssertNil(cache["three"])

        // Test that the cache has the expected contents
        XCTAssertEqual(cache["two"], 2)
        XCTAssertEqual(cache["four"], 4)
        XCTAssertEqual(cache["five"], 5)

        // Remove a key and test that it was removed from both the cache and the keys array
        cache["two"] = nil
        XCTAssertNil(cache["two"])
        XCTAssertFalse(cache.contains("two"))
    }
}
