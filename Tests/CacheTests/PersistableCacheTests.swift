#if !os(Linux) && !os(Windows)
#if os(macOS)
import AppKit
#else
import UIKit
#endif

import XCTest
@testable import Cache

final class PersistableCacheTests: XCTestCase {
    func testPersistableCacheInitialValues() throws {
        enum Key: String {
            case text
            case author
        }

        let cache: PersistableCache<Key, String, String> = PersistableCache(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(cache.allValues.count, 1)

        try cache.save()


        enum SomeOtherKey: String {
            case text
        }

        let failedLoadedCache: PersistableCache<SomeOtherKey, String, String> = PersistableCache()

        XCTAssertEqual(failedLoadedCache.allValues.count, 0)
        XCTAssertEqual(failedLoadedCache.url, cache.url)
        XCTAssertNotEqual(failedLoadedCache.name, cache.name)

        let loadedCache: PersistableCache<Key, String, String> = PersistableCache(
            initialValues: [
                .author: "Leif"
            ]
        )

        XCTAssertEqual(loadedCache.allValues.count, 2)

        try loadedCache.delete()

        let loadedDeletedCache: PersistableCache<Key, String, String> = PersistableCache()

        XCTAssertEqual(loadedDeletedCache.allValues.count, 0)

        let expectedName = "PersistableCache<Key, String, String>"
        let expectedURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        XCTAssertEqual(
            [cache.name, loadedCache.name, loadedDeletedCache.name],
            [String](repeating: expectedName, count: 3)
        )

        XCTAssertEqual(
            [cache.url, loadedCache.url, loadedDeletedCache.url],
            [URL](repeating: expectedURL, count: 3)
        )
    }

    func testPersistableCacheName() throws {
        enum Key: String {
            case text
            case author
        }

        let cache: PersistableCache<Key, String, String> = PersistableCache(name: "test")

        cache[.text] = "Hello, World!"

        XCTAssertEqual(cache.allValues.count, 1)

        try cache.save()

        let loadedCache: PersistableCache<Key, String, String> = PersistableCache(name: "test")

        loadedCache[.author] = "Leif"

        XCTAssertEqual(loadedCache.allValues.count, 2)

        try loadedCache.save()

        enum SomeOtherKey: String {
            case text
        }

        let otherKeyedLoadedCache: PersistableCache<SomeOtherKey, String, String> = PersistableCache(name: "test")

        XCTAssertEqual(otherKeyedLoadedCache.allValues.count, 1)
        XCTAssertEqual(otherKeyedLoadedCache.url, cache.url)
        XCTAssertEqual(otherKeyedLoadedCache.name, cache.name)

        XCTAssertEqual(otherKeyedLoadedCache[.text], loadedCache[.text])

        try loadedCache.delete()

        let loadedDeletedCache: PersistableCache<Key, String, String> = PersistableCache(name: "test")

        XCTAssertEqual(loadedDeletedCache.allValues.count, 0)

        let expectedName = "test"
        let expectedURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        XCTAssertEqual(
            [cache.name, loadedCache.name, otherKeyedLoadedCache.name, loadedDeletedCache.name],
            [String](repeating: expectedName, count: 4)
        )

        XCTAssertEqual(
            [cache.url, loadedCache.url, otherKeyedLoadedCache.url, loadedDeletedCache.url],
            [URL](repeating: expectedURL, count: 4)
        )
    }

    #if os(macOS)
    func testImage() throws {
        enum Key: String {
            case image
        }

        let cache: PersistableCache<Key, NSImage, String> = PersistableCache(
            initialValues: [
                .image: try XCTUnwrap(NSImage(systemSymbolName: "circle", accessibilityDescription: nil))
            ],
            persistedValueMap: { image in
                image.tiffRepresentation?.base64EncodedString()
            },
            cachedValueMap: { string in
                guard let data = Data(base64Encoded: string) else {
                    return nil
                }

                return NSImage(data: data)
            }
        )

        XCTAssertEqual(cache.allValues.count, 1)

        try cache.save()

        let loadedCache: PersistableCache<Key, NSImage, String> = PersistableCache(
            persistedValueMap: { image in
                image.tiffRepresentation?.base64EncodedString()
            },
            cachedValueMap: { string in
                guard let data = Data(base64Encoded: string) else {
                    return nil
                }

                return NSImage(data: data)
            }
        )

        XCTAssertEqual(loadedCache.allValues.count, 1)
    }
    #else
    func testImage() throws {
        enum Key: String {
            case image
        }

        let cache: PersistableCache<Key, UIImage, String> = PersistableCache(
            initialValues: [
                .image: try XCTUnwrap(UIImage(systemName: "circle"))
            ],
            persistedValueMap: { image in
                image.pngData()?.base64EncodedString()
            },
            cachedValueMap: { string in
                guard let data = Data(base64Encoded: string) else {
                    return nil
                }

                return UIImage(data: data)
            }
        )

        XCTAssertEqual(cache.allValues.count, 1)

        try cache.save()

        let loadedCache: PersistableCache<Key, UIImage, String> = PersistableCache(
            persistedValueMap: { image in
                image.pngData()?.base64EncodedString()
            },
            cachedValueMap: { string in
                guard let data = Data(base64Encoded: string) else {
                    return nil
                }

                return UIImage(data: data)
            }
        )

        XCTAssertEqual(loadedCache.allValues.count, 1)
    }
    #endif
}
#endif
