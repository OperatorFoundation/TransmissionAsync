// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
// DO NOT UPDATE TO 5.8, IT BREAKS CONCURRENCY ON LINUX

import PackageDescription

let package = Package(
    name: "TransmissionAsync",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TransmissionAsync",
            targets: ["TransmissionAsync"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
        .package(url: "https://github.com/OperatorFoundation/BlueSocket", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Datable", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Straw", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TransmissionAsync",
            dependencies: [
                "Datable",
                "Straw",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Socket", package: "BlueSocket"),
            ]
        ),
        .testTarget(
            name: "TransmissionAsyncTests",
            dependencies: ["TransmissionAsync"]),
    ],
    swiftLanguageVersions: [.v5]
)
