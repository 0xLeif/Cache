import XCTest
@testable import Cache

#if canImport(OSLog)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class LoggingTests: XCTestCase {
    func testLogging() {
        struct CachedValueObject {
            enum Key {
                case pi
                case value
            }

            static let cache = RequiredKeysCache<Key, Logger>()

            @Logging(key: Key.value, using: cache)
            var someValue: Logger
        }

        CachedValueObject.cache.set(value: Logger(subsystem: "subsystem", category: "category"), forKey: .value)

        let object = CachedValueObject()

        object.someValue.log("Success")
    }

    func testGloballyLogger() {
        struct CachedValueObject {
            enum Key {
                case pi
                case value
            }

            @Logging(key: Key.value, using: Global.loggers)
            var someValue: Logger
        }

        Global.loggers.set(
            value: Logger(subsystem: "subsystem", category: "category"),
            forKey: CachedValueObject.Key.value
        )

        let object = CachedValueObject()

        object.someValue.log("Success")
    }
}
#endif
