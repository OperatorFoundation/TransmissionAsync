// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TransmissionAsync",
    platforms: [
        .macOS(.v14), 
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TransmissionAsync",
            targets: ["TransmissionAsync"]),
        .executable(name: "TransmissionAsyncTester", targets: ["TransmissionAsyncTester"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.5.2"),

        .package(url: "https://github.com/OperatorFoundation/BlueSocket", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Chord", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Datable", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Straw", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftHexTools", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TransmissionAsync",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Socket", package: "BlueSocket"),

                "Chord",
                "Datable",
                "Straw",
                "SwiftHexTools",
            ]
        ),
        .executableTarget(
            name: "TransmissionAsyncTester",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),

                "TransmissionAsync",
            ]
        ),
        .testTarget(
            name: "TransmissionAsyncTests",
            dependencies: [
                .product(name: "Socket", package: "BlueSocket"),

                "Chord",
                "TransmissionAsync"
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
