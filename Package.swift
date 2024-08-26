// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GIFImage",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "GIFImage",
            targets: ["GIFImage"]
        )
    ],
    targets: [
        .target(
            name: "GIFImage",
            path: "Sources"
        ),
        .testTarget(
            name: "GIFImageTests",
            dependencies: [
                "GIFImage"
            ],
            path: "Tests",
            resources: [
                .process("test.gif"),
                .process("non_gif.jpg"),
                .process("TextFile.md")
            ]
        )
    ]
)
