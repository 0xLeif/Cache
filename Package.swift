// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cache",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v11),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Cache",
            targets: ["Cache"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Cache"),
        .testTarget(
            name: "CacheTests",
            dependencies: ["Cache"]
        )
    ]
)
