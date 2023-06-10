import XCTest

final class DictionaryTests: XCTestCase {
    func testAllValues() {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertEqual(dictionary.allValues.count, 1)
    }
    
    func testGet_Success() {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertEqual(dictionary.get(.text), "Hello, World!")
    }
    
    func testGet_MissingKey() {
        enum Key {
            case text
            case missingKey
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertNil(dictionary.get(.missingKey))
    }
    
    func testGet_InvalidType() {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertNil(dictionary.get(.text, as: Int.self))
    }
    
    func testGet_InvalidWrappedValue() {
        enum Key {
            case text
        }
        
        let value: Any?? = "Hello, World!"
        
        let dictionary: [Key: Any] = [Key: Any](
            initialValues: [
                .text: value as Any
            ]
        )
        
        XCTAssertNotNil(dictionary.get(.text, as: String.self))
    }
    
    func testResolve_Success() throws {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertEqual(try dictionary.resolve(.text), "Hello, World!")
    }
    
    func testResolve_MissingKey() throws {
        enum Key {
            case text
            case missingKey
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        do {
            _ = try dictionary.resolve(.missingKey)
            
            XCTFail("resolve should throw")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                "Missing Required Keys: missingKey"
            )
        }
    }
    
    func testResolve_InvalidType() throws {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        do {
            _ = try dictionary.resolve(.text, as: Double.self)
            
            XCTFail("resolve should throw")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                "Invalid Type: (Expected: Double) got Optional<String>)"
            )
        }
    }
    
    func testSet() {
        enum Key {
            case text
        }
        
        var dictionary: [Key: String] = [Key: String]()
        
        dictionary.set(value: "Hello, World!", forKey: .text)
        
        XCTAssertEqual(dictionary.get(.text), "Hello, World!")
    }
    
    func testRemove() {
        enum Key {
            case text
        }
        
        var dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertEqual(dictionary.get(.text), "Hello, World!")
        
        dictionary.remove(.text)
        
        XCTAssertNil(dictionary.get(.text))
    }
    
    func testContains() {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssert(dictionary.contains(.text))
    }
    
    func testRequire_Success() throws {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertNoThrow(try dictionary.require(.text))
    }
    
    func testRequire_Missing() throws {
        enum Key {
            case text
            case missingKey
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertThrowsError(try dictionary.require(.missingKey))
    }
    
    func testRequireSet_Success() throws {
        enum Key {
            case text
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertNoThrow(try dictionary.require(keys: [.text]))
    }
    
    func testRequireSet_Missing() throws {
        enum Key {
            case text
            case missingKey
        }
        
        let dictionary: [Key: String] = [Key: String](
            initialValues: [
                .text: "Hello, World!"
            ]
        )
        
        XCTAssertThrowsError(try dictionary.require(keys: [.text, .missingKey]))
    }
    
    func testMapDictionary() {
        let expectedDictionary: [String: String] = [
            "1": "1",
            "2": "2",
            "3": "3"
        ]
        
        let initialDictionary: [Int: Int] = [
            1: 1,
            2: 2,
            3: 3
        ]
        
        let mappedDictionary: [String: String] = initialDictionary.mapDictionary { key, value in
            ("\(key)", "\(value)")
        }
        
        XCTAssertEqual(mappedDictionary, expectedDictionary)
    }
    
    func testCompactMapDictionary() {
        let expectedDictionary: [String: String] = [
            "2": "2"
        ]
        
        let initialDictionary: [Int: Int] = [
            1: 1,
            2: 2,
            3: 3
        ]
        
        let mappedDictionary: [String: String] = initialDictionary.compactMapDictionary { key, value in
            guard key.isMultiple(of: 2) else { return nil }
            
            return ("\(key)", "\(value)")
        }
        
        XCTAssertEqual(mappedDictionary, expectedDictionary)
    }
    
    func testMapKeys() {
        let expectedDictionary: [String: Int] = [
            "1": 1,
            "2": 2,
            "3": 3
        ]
        
        let initialDictionary: [Int: Int] = [
            1: 1,
            2: 2,
            3: 3
        ]
        
        let mappedDictionary: [String: Int] = initialDictionary.mapKeys { key in
            "\(key)"
        }
        
        XCTAssertEqual(mappedDictionary, expectedDictionary)
    }
    
    func testCompactMapKeys() {
        let expectedDictionary: [String: Int] = [
            "2": 2
        ]
        
        let initialDictionary: [Int: Int] = [
            1: 1,
            2: 2,
            3: 3
        ]
        
        let mappedDictionary: [String: Int] = initialDictionary.compactMapKeys { key in
            guard key.isMultiple(of: 2) else { return nil }
            
            return "\(key)"
        }
        
        XCTAssertEqual(mappedDictionary, expectedDictionary)
    }
}

