// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SCNLine",
    platforms: [.iOS(.v8)],
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
