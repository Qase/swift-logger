// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Logger",
    platforms: [
        .iOS(.v14),
//        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMinor(from: "2.1.0")),
        .package(name: "core-networking", url: "https://github.com/Qase/swift-core-networking.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "Logger",
            dependencies: [
                "Zip",
                .product(name: "CoreNetworking", package: "core-networking"),
            ]
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]
        ),
    ]
)
