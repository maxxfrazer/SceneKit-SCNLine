// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SCNLine",
    platforms: [.iOS(.v9), .macOS(.v11)], // Support for iOS 9 and macOS Big Sur.
    products: [
        .library(
            name: "SCNLine",
            targets: ["SCNLine"])
    ],
    targets: [
        .target(
            name: "SCNLine",
            dependencies: []),
        .testTarget(
            name: "SCNLineTests",
            dependencies: ["SCNLine"])
    ],
    swiftLanguageVersions: [.v5]
)
