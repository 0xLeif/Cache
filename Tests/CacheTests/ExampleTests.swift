//
//  ExampleTests.swift
//  
//
//  Created by Leif on 6/9/23.
//

import SwiftUI
import XCTest
@testable import Cache

final class ExampleTests: XCTestCase {
    func testCacheImage() throws {
        let cache: Cache<URL, Image> = Cache()

        let imageURL = try XCTUnwrap(URL(string: "test-image"))

        XCTAssertNil(cache.get(imageURL))

        cache.set(value: Image(systemName: "circle"), forKey: imageURL)

        XCTAssertNotNil(cache.get(imageURL))

        cache.remove(imageURL)

        XCTAssertNil(cache.get(imageURL))
    }

    func testCacheObjectInheritance() throws {
        class ParentObject {
            let value: String

            init(value: String) {
                self.value = value
            }
        }

        class SubclassObject: ParentObject { }

        let expectedValue = "subclass"
        let key = UUID()

        let cache: Cache<AnyHashable, ParentObject> = Cache()

        cache.set(value: SubclassObject(value: expectedValue), forKey: key)

        let subclassObject: SubclassObject = try XCTUnwrap(cache.get(key))

        XCTAssertEqual(subclassObject.value, expectedValue)
    }

    func testObservedObjectExample() throws {
        struct ExampleView: View {
            enum Key {
                case isOn
            }

            @ObservedObject var cache = Cache<Key, Bool>()

            var body: some View {
                Toggle("Cache Toggle", isOn: $cache[.isOn, default: false])
            }
        }

        _ = ExampleView().body
    }
}
