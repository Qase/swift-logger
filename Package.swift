// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "logger",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Logger",
            dependencies: []
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]
        ),
    ]
)
