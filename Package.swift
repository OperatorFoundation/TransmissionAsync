// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TransmissionAsync",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TransmissionAsync",
            targets: ["TransmissionAsync"]),
        .executable(name: "TransmissionAsyncTester", targets: ["TransmissionAsyncTester"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.5.3"),
        .package(url: "https://github.com/OperatorFoundation/BlueSocket", from: "1.1.2"),
        .package(url: "https://github.com/OperatorFoundation/Chord", from: "0.1.4"),
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "4.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Straw", from: "1.0.1"),
        .package(url: "https://github.com/OperatorFoundation/SwiftHexTools", from: "1.2.6"),
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
