// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AMLogger",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v2)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AMLogger",
            targets: ["AMLogger"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AMLogger",
            dependencies: [
                "Pulse",
                .product(name: "PulseUI", package: "Pulse")
            ]
        ),
        .testTarget(
            name: "AMLoggerTests",
            dependencies: ["AMLogger"]
        ),
    ]
)
