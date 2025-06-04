#if canImport(SwiftUI)
import SwiftUI

extension Global {
    #if os(macOS)
    /// A typealias for `NSImage`.
    public typealias CacheImage = NSImage
    #else
    /// A typealias for `UIImage`.
    public typealias CacheImage = UIImage
    #endif

    /// The global cache for storing images.
    public static let images: Cache<URL, CacheImage> = Cache()
}
#endif
