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
    
    func testResolveDeadlockIssue() {
        let cache = Cache<String, Any>()
        let iterations = 100
        let expectation = XCTestExpectation(description: "Resolve deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "string_value", forKey: "string_key")
        cache.set(value: 42, forKey: "int_key")
        cache.set(value: ["array"], forKey: "array_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "key_\(i % 3)"
            
            do {
                let _: Int = try cache.resolve(key, as: Int.self)
            } catch {
            }
            
            if cache.contains(key) {
                let _ = cache.get(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testResolveDeadlockAggressive() {
        let cache = Cache<String, Any>()
        let iterations = 1000
        let expectation = XCTestExpectation(description: "Aggressive resolve deadlock test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "string", forKey: "test_key")
        cache.set(value: 42, forKey: "int_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = i % 2 == 0 ? "test_key" : "int_key"
            
            do {
                let _: Int = try cache.resolve(key, as: Int.self)
            } catch {
            }
            
            if cache.contains(key) {
                let _ = cache.get(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNoDoubleLocking() {
        let cache = Cache<String, String>()
        let iterations = 100
        let expectation = XCTestExpectation(description: "No double locking test")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "test_key_\(i)"
            cache.set(value: "test_value", forKey: key)
            
            do {
                let value: String = try cache.resolve(key, as: String.self)
                XCTAssertEqual(value, "test_value")
            } catch {
                XCTFail("Resolve should succeed with correct type")
            }
            
            do {
                let _: Int = try cache.resolve(key, as: Int.self)
                XCTFail("Resolve should fail with wrong type")
            } catch {
            }
            
            let _ = cache.get(key)
            let _ = cache.contains(key)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDefiniteDeadlockReproduction() {
        let cache = Cache<String, Any>()
        let iterations = 50000
        let expectation = XCTestExpectation(description: "Definite deadlock reproduction test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "string_value", forKey: "test_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            do {
                let _: Int = try cache.resolve("test_key", as: Int.self)
            } catch {
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRealisticDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 20000
        let expectation = XCTestExpectation(description: "Realistic deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "string", forKey: "string_key")
        cache.set(value: 42, forKey: "int_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = i % 2 == 0 ? "string_key" : "int_key"
            
            if i % 3 == 0 {
                do {
                    let _: Int = try cache.resolve(key, as: Int.self)
                } catch {
                }
            } else if i % 3 == 1 {
                let _ = cache.get(key)
            } else {
                cache.set(value: "new_value_\(i)", forKey: key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOriginalDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 100000
        let expectation = XCTestExpectation(description: "Original deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "some_string_value", forKey: "test_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            do {
                let _: Int = try cache.resolve("test_key", as: Int.self)
            } catch {
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testPublishedPropertyThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 10000
        let expectation = XCTestExpectation(description: "Published property thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "initial_value", forKey: "published_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 2 == 0 {
                cache.set(value: "updated_value_\(i)", forKey: "published_key")
            } else {
                let _ = cache.get("published_key")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testObservableObjectThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 8000
        let expectation = XCTestExpectation(description: "ObservableObject thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "observable_initial", forKey: "observable_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 3 == 0 {
                cache.set(value: "observable_update_\(i)", forKey: "observable_key")
            } else if i % 3 == 1 {
                let _ = cache.get("observable_key")
            } else {
                cache.set(value: "observable_mixed_\(i)", forKey: "observable_key")
                let _ = cache.get("observable_key")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSwiftUICombineThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 12000
        let expectation = XCTestExpectation(description: "SwiftUI Combine thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "swiftui_initial", forKey: "swiftui_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 4 == 0 {
                cache.set(value: "swiftui_update_\(i)", forKey: "swiftui_key")
            } else if i % 4 == 1 {
                let _ = cache.get("swiftui_key")
            } else if i % 4 == 2 {
                cache.set(value: "swiftui_combine_\(i)", forKey: "swiftui_key")
                let _ = cache.get("swiftui_key")
            } else {
                if cache.contains("swiftui_key") {
                    let _ = cache.get("swiftui_key")
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPropertyWrapperThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 15000
        let expectation = XCTestExpectation(description: "Property wrapper thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "wrapper_initial", forKey: "wrapper_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 5 == 0 {
                cache.set(value: "wrapper_update_\(i)", forKey: "wrapper_key")
            } else if i % 5 == 1 {
                let _ = cache.get("wrapper_key")
            } else if i % 5 == 2 {
                cache.set(value: "wrapper_property_\(i)", forKey: "wrapper_key")
                let _ = cache.get("wrapper_key")
            } else if i % 5 == 3 {
                if cache.contains("wrapper_key") {
                    let _ = cache.get("wrapper_key")
                }
            } else {
                cache.set(value: "wrapper_mixed_\(i)", forKey: "wrapper_key")
                let _ = cache.get("wrapper_key")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGlobalCacheThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 2000
        let expectation = XCTestExpectation(description: "Global cache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "initial_value", forKey: "global_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "global_key_\(i % 10)"
            
            if i % 3 == 0 {
                cache.set(value: "global_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = cache.get(key)
            } else {
                cache.remove(key)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testComposableCacheThreadSafety() {
        #if !os(Windows)
        let cache1 = Cache<String, Any>()
        let cache2 = Cache<String, Any>()
        let composableCache: ComposableCache<String> = ComposableCache<String>(caches: [cache1, cache2])
        
        let iterations = 2000
        let expectation = XCTestExpectation(description: "ComposableCache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache1.set(value: "cache1_value", forKey: "shared_key")
        cache2.set(value: "cache2_value", forKey: "shared_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "composable_key_\(i % 10)"
            
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
    
    func testAnyCacheableThreadSafety() {
        #if !os(Windows)
        let cache = Cache<String, Any>()
        let anyCacheable: AnyCacheable = AnyCacheable(cache)
        
        let iterations = 2000
        let expectation = XCTestExpectation(description: "AnyCacheable thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "any_value", forKey: "any_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "any_key_\(i % 10)"
            
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
    
    func testRequiredKeysCacheThreadSafety() {
        let requiredCache = RequiredKeysCache<String, Any>(requiredKeys: ["required_key"], initialValues: ["required_key": "required_value"])
        let iterations = 1000
        let expectation = XCTestExpectation(description: "RequiredKeysCache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "required_key_\(i % 5)"
            
            if i % 3 == 0 {
                requiredCache.set(value: "required_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = requiredCache.get(key)
            } else {
                requiredCache.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testExpiringCacheThreadSafety() {
        let cache = ExpiringCache<String, Any>(duration: .hours(1))
        let iterations = 3000
        let expectation = XCTestExpectation(description: "ExpiringCache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "expiring_value", forKey: "expiring_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "expiring_key_\(i % 10)"
            
            if i % 3 == 0 {
                cache.set(value: "expiring_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = cache.get(key)
            } else {
                cache.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLRUCacheThreadSafety() {
        let cache = LRUCache<String, Any>(capacity: 100)
        let iterations = 5000
        let expectation = XCTestExpectation(description: "LRUCache thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "lru_value", forKey: "lru_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "lru_key_\(i % 50)"
            
            if i % 3 == 0 {
                cache.set(value: "lru_value_\(i)", forKey: key)
            } else if i % 3 == 1 {
                let _ = cache.get(key)
            } else {
                cache.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAllCacheTypesThreadSafety() {
        let basicCache = Cache<String, Any>()
        let lruCache = LRUCache<String, Any>(capacity: 100)
        let expiringCache = ExpiringCache<String, Any>(duration: .hours(1))
        let requiredCache = RequiredKeysCache<String, Any>(requiredKeys: ["required_key"], initialValues: ["required_key": "required_value"])
        
        let iterations = 100
        let expectation = XCTestExpectation(description: "All cache types thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        basicCache.set(value: "basic_value", forKey: "basic_key")
        lruCache.set(value: "lru_value", forKey: "lru_key")
        expiringCache.set(value: "expiring_value", forKey: "expiring_key")
        requiredCache.set(value: "required_value", forKey: "required_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "test_key_\(i % 10)"
            
            if i % 4 == 0 {
                basicCache.set(value: "basic_value_\(i)", forKey: key)
                let _ = basicCache.get(key)
            } else if i % 4 == 1 {
                lruCache.set(value: "lru_value_\(i)", forKey: key)
                let _ = lruCache.get(key)
            } else if i % 4 == 2 {
                expiringCache.set(value: "expiring_value_\(i)", forKey: key)
                let _ = expiringCache.get(key)
            } else {
                requiredCache.set(value: "required_value_\(i)", forKey: key)
                let _ = requiredCache.get(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMixedOperationsThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 15000
        let expectation = XCTestExpectation(description: "Mixed operations thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "mixed_initial", forKey: "mixed_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "mixed_key_\(i % 20)"
            
            if i % 6 == 0 {
                cache.set(value: "mixed_set_\(i)", forKey: key)
            } else if i % 6 == 1 {
                let _ = cache.get(key)
            } else if i % 6 == 2 {
                cache.remove(key)
            } else if i % 6 == 3 {
                let _ = cache.contains(key)
            } else if i % 6 == 4 {
                cache.set(value: "mixed_complex_\(i)", forKey: key)
                let _ = cache.get(key)
            } else {
                if cache.contains(key) {
                    let _ = cache.get(key)
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testHighContentionThreadSafety() {
        let cache = Cache<String, Any>()
        let iterations = 25000
        let expectation = XCTestExpectation(description: "High contention thread safety test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "contention_initial", forKey: "contention_key")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let key = "contention_key_\(i % 5)"
            
            if i % 4 == 0 {
                cache.set(value: "contention_set_\(i)", forKey: key)
            } else if i % 4 == 1 {
                let _ = cache.get(key)
            } else if i % 4 == 2 {
                cache.set(value: "contention_update_\(i)", forKey: key)
                let _ = cache.get(key)
            } else {
                cache.remove(key)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testIOSAppDeadlockScenario() {
        let cache = Cache<String, Any>()
        let iterations = 10000
        let expectation = XCTestExpectation(description: "iOS app deadlock scenario test")
        expectation.expectedFulfillmentCount = iterations
        
        cache.set(value: "initial_apps_state", forKey: "apps")
        cache.set(value: "initial_monoUI_state", forKey: "monoUI")
        
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i % 3 == 0 {
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            } else if i % 3 == 1 {
                cache.set(value: "new_apps_state_\(i)", forKey: "apps")
            } else {
                cache.set(value: "mixed_state_\(i)", forKey: "apps")
                let _ = cache.get("apps")
                let _ = cache.get("monoUI")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}