// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Markway",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MarkwayCore", targets: ["MarkwayCore"]),
        .executable(name: "markway", targets: ["MarkwayCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .target(name: "MarkwayCore"),
        .executableTarget(
            name: "MarkwayCLI",
            dependencies: [
                "MarkwayCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "MarkwayCoreTests",
            dependencies: ["MarkwayCore"]
        )
    ]
)
