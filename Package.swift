// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SCNLine",
    platforms: [.iOS(.v11), .macOS(.v11)], // Support for iOS 11 and macOS Big Sur.
    products: [.library(name: "SCNLine", targets: ["SCNLine"])],
    targets: [
        .target(name: "SCNLine"),
        .testTarget(
            name: "SCNLineTests",
            dependencies: ["SCNLine"])
    ],
    swiftLanguageVersions: [.v5]
)
