//
//  JSONTests.swift
//  
//
//  Created by Leif on 6/9/23.
//

import XCTest
@testable import Cache

final class JSONTests: XCTestCase {
    func testInitData() throws {
        let jsonString = """
        {
            "text": "Hello, World!",
            "count": 27,
            "isError": false
        }
        """

        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))

        enum Key: String {
            case text
            case count
            case isError
        }

        let json: JSON<Key> = JSON(data: jsonData)

        XCTAssertEqual(json.get(.text), "Hello, World!")
        XCTAssertEqual(json.get(.count), 27)
        XCTAssertEqual(json.get(.isError), false)
    }

    func testInitArray() throws {
        let jsonString = """
        [
            {
                "text": "Hello, World!",
                "count": 27,
                "isError": false,
                "valueThatIsNotKeyed": "!!!"
            }
        ]
        """

        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))

        enum Key: String {
            case text
            case count
            case isError
        }

        let json: [JSON<Key>] = JSON.array(data: jsonData)

        XCTAssertEqual(json.first?.get(.text), "Hello, World!")
        XCTAssertEqual(json.first?.get(.count), 27)
        XCTAssertEqual(json.first?.get(.isError), false)
    }

    func testInitArray_FailureNotArray() throws {
        let jsonString = """
        {
            "text": "Hello, World!",
            "count": 27,
            "isError": false,
            "valueThatIsNotKeyed": "!!!"
        }
        """

        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))

        enum Key: String {
            case text
            case count
            case isError
        }

        let json: [JSON<Key>] = JSON.array(data: jsonData)

        XCTAssertEqual(json.count, 0)
    }

    func testInnerJSON_KeyedDictionary() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let innerJSON: [InnerKey: Any] = [
            .value: Double.pi
        ]

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: innerJSON
            ]
        )

        XCTAssertEqual(
            json.json(.json, keyed: InnerKey.self)?.get(.value, as: Double.self),
            Double.pi
        )
    }

    func testInnerJSON_StringDictionary() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let innerJSON: [String: Any] = [
            "value": Double.pi,
            "missingKey": "missing"
        ]

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: innerJSON
            ]
        )

        XCTAssertEqual(
            json.json(.json, keyed: InnerKey.self)?.get(.value, as: Double.self),
            Double.pi
        )
    }

    func testInnerJSON_Data() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let jsonString = """
        {
            "value": \(Double.pi)
        }
        """

        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: jsonData
            ]
        )

        XCTAssertEqual(
            json.json(.json, keyed: InnerKey.self)?.get(.value, as: Double.self),
            Double.pi
        )
    }

    func testInnerJSON_JSON() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let innerJSON: JSON<InnerKey> = JSON(
            initialValues: [.value: Double.pi]
        )

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: innerJSON
            ]
        )

        XCTAssertEqual(
            json.json(.json, keyed: InnerKey.self)?.get(.value, as: Double.self),
            Double.pi
        )
    }

    func testInnerArray_Data() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let jsonString = """
        [
            {
                "value": "Hello, World!",
                "count": 27,
                "isError": false,
                "valueThatIsNotKeyed": "!!!"
            }
        ]
        """

        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: jsonData
            ]
        )

        let array = try XCTUnwrap(
            json.array(.json, keyed: InnerKey.self)
        )

        XCTAssertEqual(
            array.first?.get(.value, as: String.self),
            "Hello, World!"
        )
    }

    func testInnerArray_StringDictionary() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let innerJSON: [[String: Any]] = [
            [
                "value": "Hello, World!"
            ]
        ]

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: innerJSON
            ]
        )

        let array = try XCTUnwrap(
            json.array(.json, keyed: InnerKey.self)
        )

        XCTAssertEqual(
            array.first?.get(.value, as: String.self),
            "Hello, World!"
        )
    }

    func testInnerArray_KeyedDictionary() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let innerJSON: [[InnerKey: Any]] = [
            [
                .value: "Hello, World!"
            ]
        ]

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: innerJSON
            ]
        )

        let array = try XCTUnwrap(
            json.array(.json, keyed: InnerKey.self)
        )

        XCTAssertEqual(
            array.first?.get(.value, as: String.self),
            "Hello, World!"
        )
    }
    
    func testInnerArray_JSON() throws {
        enum Key: String {
            case json
        }

        enum InnerKey: String {
            case value
        }

        let innerJSON: [JSON<InnerKey>] = [
            JSON<InnerKey>(initialValues: [.value: "Hello, World!"])
        ]

        let json: JSON<Key> = JSON(
            initialValues: [
                .json: innerJSON
            ]
        )

        let array = try XCTUnwrap(
            json.array(.json, keyed: InnerKey.self)
        )

        XCTAssertEqual(
            array.first?.get(.value, as: String.self),
            "Hello, World!"
        )
    }

    func testAllValues() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(json.allValues.count, 1)
    }

    func testGet_Success() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(json.get(.text), "Hello, World!")
    }

    func testGet_MissingKey() {
        enum Key: String {
            case text
            case missingKey
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNil(json.get(.missingKey))
    }

    func testGet_InvalidType() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNil(json.get(.text, as: Int.self))
    }

    func testResolve_Success() throws {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(try json.resolve(.text), "Hello, World!")
    }

    func testResolve_MissingKey() throws {
        enum Key: String {
            case text
            case missingKey
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try json.resolve(.missingKey, as: String.self))
    }

    func testResolve_InvalidType() throws {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try json.resolve(.text, as: Int.self))
    }

    func testSet() {
        enum Key: String {
            case text
        }

        var json: JSON<Key> = JSON()

        json.set(value: "Hello, World!", forKey: .text)

        XCTAssertEqual(json.get(.text), "Hello, World!")
    }

    func testRemove() {
        enum Key: String {
            case text
        }

        var json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertEqual(json.get(.text), "Hello, World!")

        json.remove(.text)

        XCTAssertNil(json.get(.text))
    }

    func testContains() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssert(json.contains(.text))
    }

    func testRequire_Success() throws {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNoThrow(try json.require(.text))
    }

    func testRequire_Missing() throws {
        enum Key: String {
            case text
            case missingKey
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try json.require(.missingKey))
    }

    func testRequireSet_Success() throws {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertNoThrow(try json.require(keys: [.text]))
    }

    func testRequireSet_Missing() throws {
        enum Key: String {
            case text
            case missingKey
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        XCTAssertThrowsError(try json.require(keys: [.text, .missingKey]))
    }

    func testSubscript_Get() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        let jsonValue: String? = json[.text] as? String

        XCTAssertEqual(jsonValue, "Hello, World!")
    }

    func testSubscript_Set() {
        enum Key: String {
            case text
        }

        var json: JSON<Key> = JSON()

        json[.text] = "Hello, World!"

        let jsonValue: String? = json[.text] as? String

        XCTAssertEqual(jsonValue, "Hello, World!")
    }

    func testSubscript_SetNil() {
        enum Key: String {
            case text
        }

        var json: JSON<Key> = JSON()

        json[.text] = nil

        XCTAssertNil(json[.text])
    }

    func testSubscriptDefault_GetSuccess() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON(
            initialValues: [
                .text: "Hello, World!"
            ]
        )

        let jsonValue: String? = json[.text, default: "missing value"] as? String

        XCTAssertEqual(jsonValue, "Hello, World!")
    }

    func testSubscriptDefault_GetFailure() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON()

        let jsonValue: String? = json[.text, default: "missing value"] as? String

        XCTAssertEqual(jsonValue, "missing value")
    }

    func testSubscriptDefault_SetSuccess() {
        enum Key: String {
            case text
        }

        var json: JSON<Key> = JSON()

        json[.text, default: ""] = "Hello, World!"

        let jsonValue: String? = json[.text, default: "missing value"] as? String

        XCTAssertEqual(jsonValue, "Hello, World!")
    }

    func testSubscriptDefault_SetFailure() {
        enum Key: String {
            case text
        }

        let json: JSON<Key> = JSON()

        let jsonValue: String? = json[.text, default: "missing value"] as? String

        XCTAssertEqual(jsonValue, "missing value")
    }

}
