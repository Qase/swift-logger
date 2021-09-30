// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "logger",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMinor(from: "2.1.0"))
    ],
    targets: [
        .target(
            name: "Logger",
            dependencies: [
                "Zip"
            ]
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]
        ),
    ]
)
