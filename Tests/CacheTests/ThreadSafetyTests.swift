import XCTest
@testable import Cache

final class ThreadSafetyTests: XCTestCase {
    func testCacheConcurrentAccess() {
        let iterations = 1000
        let cache = Cache<Int, Int>()

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            cache.set(value: i, forKey: i)
            XCTAssertEqual(cache.get(i), i)
            cache.remove(i)
        }

        XCTAssertEqual(cache.allValues.count, 0)
    }

    func testLRUCacheConcurrentAccess() {
        let iterations = 500
        let cache = LRUCache<Int, Int>(capacity: 5)

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            cache.set(value: i, forKey: i)
            XCTAssertEqual(cache.get(i), i)
        }

        XCTAssertEqual(cache.allValues.count, iterations)
    }

    func testExpiringCacheConcurrentAccess() {
        let iterations = 200
        let cache = ExpiringCache<Int, Int>(duration: .seconds(1))

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            cache.set(value: i, forKey: i)
            XCTAssertEqual(cache.get(i), i)
        }

        XCTAssertEqual(cache.allValues.count, iterations)
    }
}
