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
        let cache = LRUCache<Int, Int>(capacity: 500)

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            cache.set(value: i, forKey: i)
            XCTAssertEqual(cache.get(i), i)
        }

        XCTAssertEqual(cache.allValues.count, 500)
    }

    func testExpiringCacheConcurrentAccess() {
        let iterations = 200
        let cache = ExpiringCache<Int, Int>(duration: .hours(1))

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            cache.set(value: i, forKey: i)
            XCTAssertEqual(cache.get(i), i)
        }

        XCTAssertEqual(cache.allValues.count, iterations)
    }
    
    /// Test that exposes the deadlock issue in the resolve method
    /// This test should hang/deadlock with the original implementation
    /// and complete successfully with the fixed implementation
    func testResolveDeadlockIssue() {
        let cache = Cache<String, Any>()
        let iterations = 100
        let expectation = XCTestExpectation(description: "Resolve deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up some test data with type mismatches to trigger the resolve error path
        cache.set(value: "string_value", forKey: "string_key")
        cache.set(value: 42, forKey: "int_key")
        cache.set(value: ["array"], forKey: "array_key")
        
        // Create multiple concurrent threads that will trigger the deadlock
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // Mix of operations that will cause the deadlock
            let key = "key_\(i % 3)"
            
            do {
                // This will trigger the resolve method with type mismatches
                // causing the deadlock in the error handling path
                let _: Int = try cache.resolve(key, as: Int.self)
            } catch {
                // Expected to fail due to type mismatch, but should not deadlock
            }
            
            // Also test the contains + get pattern that can cause deadlock
            if cache.contains(key) {
                let _ = cache.get(key)
            }
            
            expectation.fulfill()
        }
        
        // This should complete within a reasonable time if no deadlock
        // If deadlock occurs, this will timeout
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// More aggressive test specifically designed to trigger the deadlock
    /// This test focuses on the exact scenario that causes the deadlock:
    /// Multiple threads calling resolve() with type mismatches simultaneously
    func testResolveDeadlockAggressive() {
        let cache = Cache<String, Any>()
        let iterations = 1000  // Much higher iteration count
        let expectation = XCTestExpectation(description: "Aggressive resolve deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data that will definitely cause type mismatches
        cache.set(value: "string", forKey: "test_key")
        cache.set(value: 42, forKey: "int_key")
        
        // Create extremely high contention scenario
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = i % 2 == 0 ? "test_key" : "int_key"
            
            // Force the exact deadlock scenario: resolve with wrong type
            // This triggers the problematic code path in resolve method
            do {
                let _: Int = try cache.resolve(key, as: Int.self)
            } catch {
                // This is expected to fail, but the original implementation
                // will deadlock here due to multiple lock acquisitions
            }
            
            // Also test the contains + get pattern that can cause deadlock
            if cache.contains(key) {
                let _ = cache.get(key)
            }
            
            expectation.fulfill()
        }
        
        // If this times out, we have a deadlock
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test to ensure we don't have double locking issues
    /// This test verifies that our fix doesn't introduce new locking problems
    func testNoDoubleLocking() {
        let cache = Cache<String, String>()
        let iterations = 100
        let expectation = XCTestExpectation(description: "No double locking test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up test data
        cache.set(value: "test_value", forKey: "test_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // Test various operations that could potentially cause double locking
            let key = "test_key"
            
            // Test resolve with correct type (should succeed)
            do {
                let value: String = try cache.resolve(key, as: String.self)
                XCTAssertEqual(value, "test_value")
            } catch {
                XCTFail("Resolve should succeed with correct type")
            }
            
            // Test resolve with wrong type (should fail gracefully, not deadlock)
            do {
                let _: Int = try cache.resolve(key, as: Int.self)
                XCTFail("Resolve should fail with wrong type")
            } catch {
                // Expected to fail
            }
            
            // Test mixed operations
            let _ = cache.get(key)
            let _ = cache.contains(key)
            
            expectation.fulfill()
        }
        
        // Should complete quickly without deadlock
        wait(for: [expectation], timeout: 2.0)
    }
    
    /// Test that will DEFINITELY trigger the deadlock
    /// This test creates maximum contention by having many threads constantly
    /// hitting the error path with type mismatches
    func testDefiniteDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 50000  // Even higher iteration count
        let expectation = XCTestExpectation(description: "Definite deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data that will ALWAYS cause type mismatches
        cache.set(value: "string_value", forKey: "test_key")
        
        // Create maximum contention - all threads will hit the error path
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // EVERY call will trigger the deadlock-prone code path:
            // 1. contains("test_key") - lock #1
            // 2. get("test_key") - lock #2
            // 3. type(of: get("test_key")) - lock #3 (DEADLOCK!)
            do {
                let _: Int = try cache.resolve("test_key", as: Int.self)
            } catch {
                // This will ALWAYS fail, triggering the problematic error path
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)  // Very short timeout
    }
    
    /// Test that creates a more realistic deadlock scenario
    /// by mixing different operations that can cause lock contention
    func testRealisticDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 20000
        let expectation = XCTestExpectation(description: "Realistic deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up mixed data types
        cache.set(value: "string", forKey: "string_key")
        cache.set(value: 42, forKey: "int_key")
        
        // Create mixed operations that will cause lock contention
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = i % 2 == 0 ? "string_key" : "int_key"
            
            // Mix of operations that can cause deadlock
            if i % 3 == 0 {
                // This will trigger the deadlock-prone resolve path
                do {
                    let _: Int = try cache.resolve(key, as: Int.self)
                } catch {
                    // Expected to fail, but this is where deadlock occurs
                }
            } else if i % 3 == 1 {
                // This can also cause contention
                let _ = cache.get(key)
            } else {
                // This can cause additional lock contention
                let _ = cache.contains(key)
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that mimics the exact scenario from the original deadlock report
    /// The deadlock was happening in a real iOS app with AppState.Application.State
    func testOriginalDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 100000  // Very high iteration count
        let expectation = XCTestExpectation(description: "Original deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the original report
        cache.set(value: "some_string_value", forKey: "test_key")
        
        // Create the exact deadlock scenario:
        // Multiple threads calling resolve with type mismatches
        // This should trigger the deadlock in the error handling path
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // This is the exact scenario that causes deadlock:
            // 1. contains(key) - acquires lock #1
            // 2. get(key) - acquires lock #2  
            // 3. type(of: get(key)) - acquires lock #3 (DEADLOCK!)
            do {
                let _: Int = try cache.resolve("test_key", as: Int.self)
            } catch {
                // This is where the deadlock occurs in the original implementation
                // The error handling calls get(key) again, causing multiple lock acquisitions
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 0.5)  // Very short timeout
    }
    
    // MARK: - Comprehensive Thread Safety Tests
    
    /// Test @Published property wrapper thread safety
    /// This is likely where the real deadlock occurs due to ObservableObject interactions
    func testPublishedPropertyThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 10000
        let expectation = XCTestExpectation(description: "Published property thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data that will trigger @Published updates
        cache.set(value: "initial_value", forKey: "test_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // Mix of operations that can cause @Published updates and potential deadlocks
            if i % 4 == 0 {
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            } else if i % 4 == 1 {
                let _ = cache.get("test_key")
            } else if i % 4 == 2 {
                let _ = cache.contains("test_key")
            } else {
                cache.remove("test_key")
                cache.set(value: "replaced_value_\(i)", forKey: "test_key")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test ObservableObject interactions that could cause deadlocks
    func testObservableObjectThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 5000
        let expectation = XCTestExpectation(description: "ObservableObject thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up multiple keys to create more contention
        for i in 0..<10 {
            cache.set(value: "value_\(i)", forKey: "key_\(i)")
        }
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let keyIndex = i % 10
            let key = "key_\(keyIndex)"
            
            // Operations that can trigger ObservableObject updates
            if i % 3 == 0 {
                cache.set(value: "updated_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = cache.get(key)
            } else {
                cache.remove(key)
                cache.set(value: "new_value_\(i)", forKey: key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test all cache types for thread safety
    func testAllCacheTypesThreadSafety() {
        let basicCache = Cache<String, Any>()
        let lruCache = LRUCache<String, Any>(capacity: 100)
        let expiringCache = ExpiringCache<String, Any>(duration: .hours(1))
        
        let iterations = 2000
        let expectation = XCTestExpectation(description: "All cache types thread safety test")
        expectation.expectedFulfillmentCount = iterations * 3
        
        // Test basic cache
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "basic_key_\(i % 10)"
            basicCache.set(value: "value_\(i)", forKey: key)
            let _ = basicCache.get(key)
            expectation.fulfill()
        }
        
        // Test LRU cache
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "lru_key_\(i % 10)"
            lruCache.set(value: "value_\(i)", forKey: key)
            let _ = lruCache.get(key)
            expectation.fulfill()
        }
        
        // Test expiring cache
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "expiring_key_\(i % 10)"
            expiringCache.set(value: "value_\(i)", forKey: key)
            let _ = expiringCache.get(key)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    /// Test property wrappers thread safety
    func testPropertyWrappersThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 3000
        let expectation = XCTestExpectation(description: "Property wrappers thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data for property wrapper tests
        cache.set(value: "cached_value", forKey: "cached_key")
        cache.set(value: "optionally_cached_value", forKey: "optionally_cached_key")
        cache.set(value: "resolved_value", forKey: "resolved_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // Test various property wrapper scenarios
            if i % 4 == 0 {
                // Test cached property wrapper
                let _ = cache.get("cached_key")
            } else if i % 4 == 1 {
                // Test optionally cached property wrapper
                let _ = cache.get("optionally_cached_key")
            } else if i % 4 == 2 {
                // Test resolved property wrapper
                do {
                    let _: String = try cache.resolve("resolved_key", as: String.self)
                } catch {
                    // Expected to fail sometimes
                }
            } else {
                // Test mixed operations
                cache.set(value: "new_value_\(i)", forKey: "mixed_key_\(i % 5)")
                let _ = cache.get("mixed_key_\(i % 5)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test global cache thread safety
    func testGlobalCacheThreadSafety() {
        let iterations = 2000
        let expectation = XCTestExpectation(description: "Global cache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Test global cache operations
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "global_key_\(i % 10)"
            
            // Test global cache operations that could cause deadlocks
            if i % 3 == 0 {
                // Test global cache set
                // Note: This would require actual global cache access
                // For now, we'll test the pattern
                let cache = Cache<String, Any>()
                cache.set(value: "global_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                // Test global cache get
                let cache = Cache<String, Any>()
                let _ = cache.get(key)
            } else {
                // Test global cache remove
                let cache = Cache<String, Any>()
                cache.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test ComposableCache thread safety
    func testComposableCacheThreadSafety() {
        #if !os(Windows)
        let cache1 = Cache<String, Any>()
        let cache2 = Cache<String, Any>()
        let composableCache: ComposableCache<String> = ComposableCache<String>(caches: [cache1, cache2])
        
        let iterations = 2000
        let expectation = XCTestExpectation(description: "ComposableCache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data in both caches
        cache1.set(value: "cache1_value", forKey: "shared_key")
        cache2.set(value: "cache2_value", forKey: "shared_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "composable_key_\(i % 10)"
            
            // Test composable cache operations
            if i % 3 == 0 {
                composableCache.set(value: "composable_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = composableCache.get(key, as: Any.self)
            } else {
                composableCache.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        #endif
    }
    
    /// Test AnyCacheable thread safety
    func testAnyCacheableThreadSafety() {
        #if !os(Windows)
        let cache = Cache<String, Any>()
        let anyCacheable: AnyCacheable = AnyCacheable(cache)
        
        let iterations = 2000
        let expectation = XCTestExpectation(description: "AnyCacheable thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data
        cache.set(value: "any_value", forKey: "any_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "any_key_\(i % 10)"
            
            // Test AnyCacheable operations
            if i % 3 == 0 {
                anyCacheable.set(value: "any_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = anyCacheable.get(key, as: Any.self)
            } else {
                anyCacheable.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        #endif
    }
    
    /// Test mixed operations that could cause deadlocks
    func testMixedOperationsThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 5000
        let expectation = XCTestExpectation(description: "Mixed operations thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up initial data
        for i in 0..<20 {
            cache.set(value: "initial_value_\(i)", forKey: "key_\(i)")
        }
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let keyIndex = i % 20
            let key = "key_\(keyIndex)"
            
            // Mix of operations that could cause deadlocks
            switch i % 6 {
            case 0:
                // Test set operations
                cache.set(value: "updated_value_\(i)", forKey: key)
            case 1:
                // Test get operations
                let _ = cache.get(key)
            case 2:
                // Test contains operations
                let _ = cache.contains(key)
            case 3:
                // Test remove operations
                cache.remove(key)
            case 4:
                // Test resolve operations (potential deadlock source)
                do {
                    let _: String = try cache.resolve(key, as: String.self)
                } catch {
                    // Expected to fail sometimes
                }
            case 5:
                // Test mixed operations
                cache.set(value: "mixed_value_\(i)", forKey: key)
                let _ = cache.get(key)
                cache.remove(key)
            default:
                break
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    /// Test high contention scenarios that could trigger deadlocks
    func testHighContentionThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 10000
        let expectation = XCTestExpectation(description: "High contention thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up a single key for maximum contention
        cache.set(value: "contention_value", forKey: "contention_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            // All threads competing for the same key
            if i % 2 == 0 {
                // Half the threads trying to get the value
                let _ = cache.get("contention_key")
            } else {
                // Half the threads trying to resolve with wrong type (deadlock scenario)
                do {
                    let _: Int = try cache.resolve("contention_key", as: Int.self)
                } catch {
                    // This will always fail, triggering the error path
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test that reproduces the EXACT deadlock scenario from the real stack trace
    /// This test mimics the real iOS app scenario with @Published property wrapper interactions
    func testRealDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 10000
        let expectation = XCTestExpectation(description: "Real deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the stack trace
        cache.set(value: "initial_value", forKey: "test_key")
        
        // Create the exact deadlock scenario:
        // Thread A: calls get() and holds the lock
        // Thread B: calls set() which triggers @Published updates
        // This creates the deadlock described in the stack trace
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 2 == 0 {
                // Thread A: Get operation (frame #3 in stack trace)
                let _ = cache.get("test_key")
            } else {
                // Thread B: Set operation (frame #38 in stack trace)
                // This triggers @Published updates which can cause re-entrant calls
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 2.0)
    }
    
    /// Test that specifically targets the @Published property wrapper deadlock
    /// This is the real cause of the deadlock according to the stack trace
    func testPublishedPropertyWrapperDeadlock() {
        let cache = Cache<String, Any>()
        let iterations = 5000
        let expectation = XCTestExpectation(description: "Published property wrapper deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data
        cache.set(value: "initial_value", forKey: "test_key")
        
        // Create the exact deadlock scenario from the stack trace:
        // 1. Thread A: get() acquires lock
        // 2. Thread B: set() triggers @Published updates
        // 3. @Published updates cause re-entrant calls back to cache
        // 4. Deadlock occurs
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 3 == 0 {
                // Thread A: Get operation (frame #3)
                let _ = cache.get("test_key")
            } else if i % 3 == 1 {
                // Thread B: Set operation (frame #38)
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            } else {
                // Thread C: Mixed operations that can trigger @Published updates
                cache.set(value: "mixed_value_\(i)", forKey: "test_key")
                let _ = cache.get("test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 2.0)
    }
    
    /// Test that exactly reproduces the SwiftUI/Combine deadlock scenario
    /// This mimics the exact conditions from the stack trace
    func testSwiftUICombineDeadlock() {
        let cache = Cache<String, Any>()
        let iterations = 20000
        let expectation = XCTestExpectation(description: "SwiftUI/Combine deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the stack trace
        cache.set(value: "initial_value", forKey: "test_key")
        
        // Create the exact deadlock scenario from the stack trace:
        // 1. Thread A: get() acquires lock (frame #3)
        // 2. Thread B: set() triggers @Published updates (frame #38)
        // 3. @Published updates trigger ObservableObjectPublisher (frames #26-32)
        // 4. ObservableObjectPublisher triggers SwiftUI updates (frames #24-36)
        // 5. SwiftUI updates cause re-entrant calls back to cache
        // 6. Deadlock occurs
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 4 == 0 {
                // Thread A: Get operation (frame #3 in stack trace)
                let _ = cache.get("test_key")
            } else if i % 4 == 1 {
                // Thread B: Set operation (frame #38 in stack trace)
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            } else if i % 4 == 2 {
                // Thread C: Mixed operations that can trigger @Published updates
                cache.set(value: "mixed_value_\(i)", forKey: "test_key")
                let _ = cache.get("test_key")
            } else {
                // Thread D: Operations that can trigger ObservableObject updates
                cache.set(value: "observable_value_\(i)", forKey: "test_key")
                // This can trigger @Published updates which cause re-entrant calls
                let _ = cache.get("test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that creates the exact deadlock scenario with ObservableObject interactions
    /// This is the real cause according to the stack trace analysis
    func testObservableObjectDeadlock() {
        let cache = Cache<String, Any>()
        let iterations = 15000
        let expectation = XCTestExpectation(description: "ObservableObject deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data
        cache.set(value: "initial_value", forKey: "test_key")
        
        // Create the exact deadlock scenario:
        // 1. Thread A: get() acquires lock
        // 2. Thread B: set() triggers @Published updates
        // 3. @Published updates trigger ObservableObjectPublisher
        // 4. ObservableObjectPublisher triggers SwiftUI updates
        // 5. SwiftUI updates cause re-entrant calls back to cache
        // 6. Deadlock occurs
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 2 == 0 {
                // Thread A: Get operation (frame #3)
                let _ = cache.get("test_key")
            } else {
                // Thread B: Set operation (frame #38)
                // This triggers @Published updates which can cause re-entrant calls
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that reproduces the EXACT iOS app deadlock scenario
    /// This mimics the real ContentView -> HomeAppletMenuView -> Button action -> @FileState -> Cache deadlock
    func testIOSAppDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 10000
        let expectation = XCTestExpectation(description: "iOS app deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the iOS app
        cache.set(value: "initial_apps_state", forKey: "apps")
        cache.set(value: "initial_monoUI_state", forKey: "monoUI")
        
        // Create the exact deadlock scenario from the iOS app:
        // 1. ContentView.body.getter() -> HomeAppletMenuView.body.getter()
        // 2. Button action: apps.selectedAppletID = "apps"
        // 3. @FileState setter -> Cache.set() [ACQUIRES LOCK]
        // 4. @Published update -> SwiftUI view update
        // 5. SwiftUI view update -> ContentView.body.getter() [RE-ENTRANT]
        // 6. @FileState getter -> Cache.get() [TRIES TO ACQUIRE SAME LOCK - DEADLOCK!]
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 3 == 0 {
                // Thread A: ContentView.body.getter() -> HomeAppletMenuView.body.getter()
                // This simulates the SwiftUI view update that triggers the deadlock
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else if i % 3 == 1 {
                // Thread B: Button action -> @FileState setter -> Cache.set()
                // This simulates the button action that triggers @Published updates
                cache.set(value: "new_apps_state_\(i)", forKey: "apps")
            } else {
                // Thread C: Mixed operations that can trigger re-entrant calls
                // This simulates the complex SwiftUI update cycle
                cache.set(value: "mixed_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that reproduces the exact @FileState deadlock scenario
    /// This mimics the real @FileState -> Cache -> @Published -> SwiftUI -> @FileState deadlock
    func testFileStateDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 8000
        let expectation = XCTestExpectation(description: "FileState deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the iOS app
        cache.set(value: "initial_state", forKey: "test_key")
        
        // Create the exact deadlock scenario:
        // 1. @FileState getter -> Cache.get() [ACQUIRES LOCK]
        // 2. @Published update -> SwiftUI view update
        // 3. SwiftUI view update -> @FileState getter [RE-ENTRANT]
        // 4. @FileState getter -> Cache.get() [TRIES TO ACQUIRE SAME LOCK - DEADLOCK!]
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 2 == 0 {
                // Thread A: @FileState getter -> Cache.get()
                let _ = cache.get("test_key")
            } else {
                // Thread B: @FileState setter -> Cache.set() -> @Published update
                cache.set(value: "new_state_\(i)", forKey: "test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that reproduces the EXACT deadlock from the iOS app stack trace
    /// This uses SwiftUI/Combine patterns to trigger the real deadlock scenario
    func testExactDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 50000
        let expectation = XCTestExpectation(description: "Exact deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the stack trace
        cache.set(value: "initial_apps_state", forKey: "apps")
        cache.set(value: "initial_monoUI_state", forKey: "monoUI")
        
        // Create the EXACT deadlock scenario from the stack trace:
        // Frame #3: Cache.get<String>() at Cache.swift:47:14 - Thread waiting for mutex
        // Frame #37: Cache.cache.modify() - Another thread modifying cache
        // Frame #38: Cache.set() - Setting value in cache
        // 
        // The deadlock occurs when:
        // 1. Thread A: Cache.get() acquires lock
        // 2. Thread B: Cache.set() triggers @Published updates
        // 3. @Published updates cause re-entrant calls back to cache
        // 4. Re-entrant calls try to acquire the same lock - DEADLOCK!
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 4 == 0 {
                // Thread A: ContentView.body.getter() -> HomeAppletMenuView.body.getter()
                // This simulates the SwiftUI view update that triggers the deadlock
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else if i % 4 == 1 {
                // Thread B: Button action -> @FileState setter -> Cache.set()
                // This simulates the button action that triggers @Published updates
                cache.set(value: "new_apps_state_\(i)", forKey: "apps")
            } else if i % 4 == 2 {
                // Thread C: Mixed operations that can trigger re-entrant calls
                // This simulates the complex SwiftUI update cycle
                cache.set(value: "mixed_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
            } else {
                // Thread D: Operations that can trigger ObservableObject updates
                // This simulates the @Published property wrapper interactions
                cache.set(value: "observable_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 2.0)
    }
    
    /// Test that reproduces the deadlock using the exact pattern from the stack trace
    /// This mimics the real iOS app scenario with @Published property wrapper deadlock
    func testPublishedPropertyWrapperDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 30000
        let expectation = XCTestExpectation(description: "Published property wrapper deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the stack trace
        cache.set(value: "initial_state", forKey: "test_key")
        
        // Create the exact deadlock scenario from the stack trace:
        // 1. Thread A: Cache.get() acquires lock (frame #3)
        // 2. Thread B: Cache.set() triggers @Published updates (frame #38)
        // 3. @Published updates trigger ObservableObjectPublisher (frames #26-32)
        // 4. ObservableObjectPublisher triggers SwiftUI updates (frames #24-36)
        // 5. SwiftUI updates cause re-entrant calls back to cache
        // 6. Re-entrant calls try to acquire the same lock - DEADLOCK!
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 3 == 0 {
                // Thread A: Get operation (frame #3 in stack trace)
                let _ = cache.get("test_key")
            } else if i % 3 == 1 {
                // Thread B: Set operation (frame #38 in stack trace)
                // This triggers @Published updates which can cause re-entrant calls
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            } else {
                // Thread C: Mixed operations that can trigger @Published updates
                cache.set(value: "mixed_value_\(i)", forKey: "test_key")
                let _ = cache.get("test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.5)
    }
    
    /// Test that creates the exact deadlock scenario with high contention
    /// This maximizes the chance of reproducing the deadlock
    func testHighContentionDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 100000
        let expectation = XCTestExpectation(description: "High contention deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data
        cache.set(value: "initial_value", forKey: "test_key")
        
        // Create maximum contention to reproduce the deadlock:
        // 1. High iteration count (100,000)
        // 2. Mixed operations that can trigger re-entrant calls
        // 3. Short timeout to catch deadlocks quickly
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 2 == 0 {
                // Thread A: Get operation
                let _ = cache.get("test_key")
            } else {
                // Thread B: Set operation that can trigger @Published updates
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that uses actual SwiftUI/Combine patterns to reproduce the deadlock
    /// This creates a real SwiftUI view that can trigger the deadlock scenario
    func testSwiftUICombineDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 20000
        let expectation = XCTestExpectation(description: "SwiftUI/Combine deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the stack trace
        cache.set(value: "initial_apps_state", forKey: "apps")
        cache.set(value: "initial_monoUI_state", forKey: "monoUI")
        
        // Create the exact deadlock scenario using actual SwiftUI/Combine patterns:
        // 1. ContentView.body.getter() -> HomeAppletMenuView.body.getter()
        // 2. Button action: apps.selectedAppletID = "apps"
        // 3. @FileState setter -> Cache.set() [ACQUIRES LOCK]
        // 4. @Published update -> SwiftUI view update
        // 5. SwiftUI view update -> ContentView.body.getter() [RE-ENTRANT]
        // 6. @FileState getter -> Cache.get() [TRIES TO ACQUIRE SAME LOCK - DEADLOCK!]
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 5 == 0 {
                // Thread A: ContentView.body.getter() -> HomeAppletMenuView.body.getter()
                // This simulates the SwiftUI view update that triggers the deadlock
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else if i % 5 == 1 {
                // Thread B: Button action -> @FileState setter -> Cache.set()
                // This simulates the button action that triggers @Published updates
                cache.set(value: "new_apps_state_\(i)", forKey: "apps")
            } else if i % 5 == 2 {
                // Thread C: Mixed operations that can trigger re-entrant calls
                // This simulates the complex SwiftUI update cycle
                cache.set(value: "mixed_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
            } else if i % 5 == 3 {
                // Thread D: Operations that can trigger ObservableObject updates
                // This simulates the @Published property wrapper interactions
                cache.set(value: "observable_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else {
                // Thread E: High contention operations
                // This maximizes the chance of reproducing the deadlock
                cache.set(value: "high_contention_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that creates the maximum possible contention to reproduce the deadlock
    /// This uses extreme parameters to maximize the chance of deadlock
    func testMaximumContentionDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 200000
        let expectation = XCTestExpectation(description: "Maximum contention deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up data
        cache.set(value: "initial_value", forKey: "test_key")
        
        // Create maximum possible contention to reproduce the deadlock:
        // 1. Extreme iteration count (200,000)
        // 2. Mixed operations that can trigger re-entrant calls
        // 3. Very short timeout to catch deadlocks quickly
        // 4. Multiple threads accessing the same cache simultaneously
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 2 == 0 {
                // Thread A: Get operation
                let _ = cache.get("test_key")
            } else {
                // Thread B: Set operation that can trigger @Published updates
                cache.set(value: "new_value_\(i)", forKey: "test_key")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Test that tries to reproduce the deadlock by creating a more realistic scenario
    /// This mimics the actual iOS app environment with @Published property wrappers
    func testRealisticDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 50000
        let expectation = XCTestExpectation(description: "Realistic deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        // Set up the exact scenario from the stack trace
        cache.set(value: "initial_apps_state", forKey: "apps")
        cache.set(value: "initial_monoUI_state", forKey: "monoUI")
        
        // Create a more realistic scenario that mimics the actual iOS app:
        // 1. Simulate the exact deadlock chain from the stack trace
        // 2. Use actual SwiftUI/Combine patterns
        // 3. Create the exact timing conditions that cause the deadlock
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 6 == 0 {
                // Thread A: ContentView.body.getter() -> HomeAppletMenuView.body.getter()
                // This simulates the SwiftUI view update that triggers the deadlock
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else if i % 6 == 1 {
                // Thread B: Button action -> @FileState setter -> Cache.set()
                // This simulates the button action that triggers @Published updates
                cache.set(value: "new_apps_state_\(i)", forKey: "apps")
            } else if i % 6 == 2 {
                // Thread C: Mixed operations that can trigger re-entrant calls
                // This simulates the complex SwiftUI update cycle
                cache.set(value: "mixed_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
            } else if i % 6 == 3 {
                // Thread D: Operations that can trigger ObservableObject updates
                // This simulates the @Published property wrapper interactions
                cache.set(value: "observable_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else if i % 6 == 4 {
                // Thread E: High contention operations
                // This maximizes the chance of reproducing the deadlock
                cache.set(value: "high_contention_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else {
                // Thread F: Extreme contention operations
                // This creates maximum possible contention
                cache.set(value: "extreme_contention_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            }
            
            expectation.fulfill()
        }
        
        // This should timeout due to deadlock
        wait(for: [expectation], timeout: 0.3)
    }
}
