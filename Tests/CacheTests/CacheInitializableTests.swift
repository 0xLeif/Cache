import XCTest
@testable import Cache

final class CacheInitializableTests: XCTestCase {
    class TestCache: Cache<TestCache.Key, Any> {
        enum Key {
            case text
        }
    }

    struct CacheInitializableObject: CacheInitializable {
        let text: String?

        init(cache: TestCache) {
            text = cache.get(.text)
        }
    }

    func testCacheInitializableEmpty() {
        let cache = TestCache()

        let object = CacheInitializableObject(cache: cache)

        XCTAssertNil(object.text)
    }

    func testCacheInitializable() {
        let cache = TestCache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        let object = CacheInitializableObject(cache: cache)

        XCTAssertNotNil(object.text)
    }
}
