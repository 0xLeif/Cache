//#if !os(Windows)
//import XCTest
//@testable import Cache
//
//final class ComposableCacheTests: XCTestCase {
//    func testComplexComposableCache() {
//        enum Key {
//            case a
//            case b
//            case c
//            case d
//        }
//
//        let lruCache: LRUCache<Key, Any> = LRUCache(capacity: 3)
//        let expiringCache: ExpiringCache<Key, Any> = ExpiringCache(duration: .seconds(1))
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                lruCache,       // First Cache
//                // ...          // Other Caches
//                expiringCache   // Last Cache
//            ]
//        )
//
//        XCTAssertNil(cache.get(.a))
//
//        cache.set(value: "Hello, A!", forKey: .a)
//
//        XCTAssertNotNil(cache.get(.a))
//        XCTAssertNotNil(lruCache.get(.a))
//        XCTAssertNotNil(expiringCache.get(.a))
//
//        cache.set(value: "Hello, B!", forKey: .b)
//        cache.set(value: "Hello, C!", forKey: .c)
//        cache.set(value: "Hello, D!", forKey: .d)
//
//        XCTAssertNil(lruCache.get(.a))
//        XCTAssertNotNil(cache.get(.a))
//        XCTAssertNotNil(expiringCache.get(.a))
//
//        XCTAssertNotNil(cache.get(.b))
//        XCTAssertNotNil(cache.get(.c))
//        XCTAssertNotNil(cache.get(.d))
//
//        sleep(2)
//
//        // Check ComposableCache
//
//        XCTAssertNil(cache.get(.a))
//        XCTAssertNotNil(cache.get(.b))
//        XCTAssertNotNil(cache.get(.c))
//        XCTAssertNotNil(cache.get(.d))
//
//        // Check LRUCache
//
//        XCTAssertNil(lruCache.get(.a))
//        XCTAssertNotNil(lruCache.get(.b))
//        XCTAssertNotNil(lruCache.get(.c))
//        XCTAssertNotNil(lruCache.get(.d))
//
//        // Check ExpiringCache
//
//        XCTAssertNil(expiringCache.get(.a))
//        XCTAssertNil(expiringCache.get(.b))
//        XCTAssertNil(expiringCache.get(.c))
//        XCTAssertNil(expiringCache.get(.d))
//    }
//
//    func testAllValues() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        XCTAssertEqual(cache.allValues.count, 1)
//    }
//
//    func testAllValues_None() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            initialValues: [:]
//        )
//
//        XCTAssertEqual(cache.allValues.count, 0)
//    }
//
//    func testGet_Success() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertEqual(cache.get(.text), "Hello, World!")
//    }
//
//    func testGet_MissingKey() {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertNil(cache.get(.missingKey))
//    }
//
//    func testGet_InvalidType() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertNil(cache.get(.text, as: Int.self))
//    }
//
//    func testResolve_Success() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertEqual(try cache.resolve(.text), "Hello, World!")
//    }
//
//    func testResolve_MissingKey() throws {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertThrowsError(try cache.resolve(.missingKey, as: Any.self))
//    }
//
//    func testResolve_InvalidType() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertThrowsError(try cache.resolve(.text, as: Int.self))
//    }
//
//    func testSet() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>()
//            ]
//        )
//
//        cache.set(value: "Hello, World!", forKey: .text)
//
//        XCTAssertEqual(cache.get(.text), "Hello, World!")
//    }
//
//    func testRemove() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertEqual(cache.get(.text), "Hello, World!")
//
//        cache.remove(.text)
//
//        XCTAssertNil(cache.get(.text))
//    }
//
//    func testContains_Success() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssert(cache.contains(.text))
//    }
//
//    func testContains_Failure() {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>()
//            ]
//        )
//
//        XCTAssertFalse(cache.contains(.text))
//    }
//
//    func testRequire_Success() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertNoThrow(try cache.require(.text))
//    }
//
//    func testRequire_Missing() throws {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertThrowsError(try cache.require(.missingKey))
//    }
//
//    func testRequireSet_Success() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertNoThrow(try cache.require(keys: [.text]))
//    }
//
//    func testRequireSet_Missing() throws {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: ComposableCache = ComposableCache<Key>(
//            caches: [
//                Cache<Key, String>(
//                    initialValues: [
//                        .text: "Hello, World!"
//                    ]
//                )
//            ]
//        )
//
//        XCTAssertThrowsError(try cache.require(keys: [.text, .missingKey]))
//    }
//}
//#endif
