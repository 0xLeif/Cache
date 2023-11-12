//#if !os(Windows)
//import XCTest
//@testable import Cache
//
//final class AnyCacheableTests: XCTestCase {
//    func testAllValues() {
//        enum Key {
//            case text
//        }
//
//        let cacheable: AnyCacheable = AnyCacheable(
//            initialValues: [
//                Key.text: "Hello, World!"
//            ]
//        )
//
//        XCTAssertEqual(cacheable.allValues.count, 1)
//    }
//
//    func testGet_Success() {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertEqual(cacheable.get(Key.text, as: String.self), "Hello, World!")
//    }
//
//    func testGet_MissingKey() {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        let missingKeyValue: Any? = cacheable.get(Key.missingKey)
//
//        XCTAssertNil(missingKeyValue)
//    }
//
//    func testGet_InvalidType() {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertNil(cacheable.get(Key.text, as: Int.self))
//    }
//
//    func testResolve_Success() throws {
//        enum Key: String {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertEqual(try cacheable.resolve(Key.text), "Hello, World!")
//    }
//
//    func testResolve_MissingKey() throws {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertThrowsError(try cacheable.resolve(Key.missingKey, as: Any.self))
//    }
//
//    func testResolve_InvalidType() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertThrowsError(try cacheable.resolve(Key.text, as: Int.self))
//    }
//
//    func testSet() {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache()
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        cacheable.set(value: "Hello, World!", forKey: Key.text)
//
//        XCTAssertEqual(cacheable.get(Key.text), "Hello, World!")
//    }
//
//    func testRemove() {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertEqual(cacheable.get(Key.text), "Hello, World!")
//
//        cacheable.remove(Key.text)
//
//        XCTAssertNil(cacheable.get(Key.text))
//    }
//
//    func testContains() {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssert(cacheable.contains(Key.text))
//    }
//
//    func testRequire_Success() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertNoThrow(try cacheable.require(Key.text))
//    }
//
//    func testRequire_Missing() throws {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertThrowsError(try cacheable.require(Key.missingKey))
//    }
//
//    func testRequireSet_Success() throws {
//        enum Key {
//            case text
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertNoThrow(try cacheable.require(keys: [Key.text]))
//    }
//
//    func testRequireSet_Missing() throws {
//        enum Key {
//            case text
//            case missingKey
//        }
//
//        let cache: Cache<Key, String> = Cache(
//            initialValues: [
//                .text: "Hello, World!"
//            ]
//        )
//
//        let cacheable: AnyCacheable = AnyCacheable(cache)
//
//        XCTAssertThrowsError(try cacheable.require(keys: [Key.text, Key.missingKey]))
//    }
//}
//#endif
