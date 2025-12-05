#if !os(Linux) && !os(Windows)
import XCTest
@testable import Cache

/// Tests designed to expose bugs in the Cache package
final class BugExposingTests: XCTestCase {

    // MARK: - Bug #1: PersistableCache Deadlock on Error

    /// This test exposes a deadlock bug in PersistableCache.
    /// When delete() throws an error, the NSLock is never released.
    /// Any subsequent call to save() or delete() will hang forever.
    func testPersistableCacheDeadlockAfterDeleteError() {
        enum Key: String {
            case test
        }

        let uniqueName = "deadlock_test_\(UUID().uuidString)"
        let cache: PersistableCache<Key, String, String> = PersistableCache(name: uniqueName)

        // First: delete() on non-existent file throws - but lock is never released!
        XCTAssertThrowsError(try cache.delete())

        // Now try to save - this should work but will DEADLOCK
        // because the lock was never released after the error above
        cache[.test] = "value"

        // Use a timeout to detect the deadlock
        let expectation = XCTestExpectation(description: "save() should complete")

        DispatchQueue.global().async {
            do {
                try cache.save()
                expectation.fulfill()
            } catch {
                expectation.fulfill()  // Even if it fails, at least it didn't hang
            }
        }

        // Wait only 2 seconds - if it hangs, we have a deadlock
        let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)

        // If this times out, the bug is confirmed
        XCTAssertNotEqual(result, .timedOut, "DEADLOCK DETECTED: save() hung after delete() error - lock was never released!")
    }

    // MARK: - LRUCache contains() Updates Recency

    /// This test validates that contains() updates LRU order.
    /// Calling contains() is considered a "use" of the key, promoting it to most recently used.
    func testLRUCacheContainsUpdatesRecency() {
        let cache = LRUCache<String, Int>(capacity: 2)

        // Add items in order: a, then b
        cache["a"] = 1  // Order: [a]
        cache["b"] = 2  // Order: [a, b]

        // At this point, "a" is the oldest (least recently used)
        // Calling contains() promotes "a" to most recently used
        let exists = cache.contains("a")  // Order: [b, a]
        XCTAssertTrue(exists)

        // Now add "c" - this evicts "b" (now the oldest)
        cache["c"] = 3

        // contains() promoted "a", so "b" was evicted
        XCTAssertNotNil(cache["a"], "'a' should exist - contains() promoted it to most recently used")
        XCTAssertNil(cache["b"], "'b' should be evicted as the oldest after contains() promoted 'a'")
        XCTAssertNotNil(cache["c"])
    }

    // MARK: - Bug #3: LRUCache Dual Lock Issue

    /// This test attempts to expose race conditions from LRUCache having
    /// its own lock separate from the parent Cache's lock.
    func testLRUCacheDualLockRaceCondition() {
        let cache = LRUCache<Int, Int>(capacity: 50)
        let iterations = 100_000
        var errors: [String] = []
        let errorLock = NSLock()

        let expectation = XCTestExpectation(description: "Concurrent operations complete")

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = i % 30

            // Interleave different operations
            switch i % 4 {
            case 0:
                cache[key] = i
            case 1:
                _ = cache[key]
            case 2:
                _ = cache.contains(key)
            case 3:
                cache.remove(key)
            default:
                break
            }

            // Periodically check consistency
            if i % 1000 == 0 {
                let count = cache.allValues.count
                if count > 50 {
                    errorLock.lock()
                    errors.append("Cache exceeded capacity: \(count) > 50 at iteration \(i)")
                    errorLock.unlock()
                }
            }
        }

        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)

        // Report any consistency violations
        if !errors.isEmpty {
            XCTFail("Race condition detected! Errors:\n\(errors.joined(separator: "\n"))")
        }

        // Final consistency check
        let finalCount = cache.allValues.count
        XCTAssertLessThanOrEqual(finalCount, 50, "Final cache size \(finalCount) exceeds capacity of 50")
    }
}
#endif
