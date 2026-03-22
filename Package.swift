// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RouteTone",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "RouteTone",
            targets: ["RouteTone"]
        )
    ],
    targets: [
        .executableTarget(
            name: "RouteTone",
            path: "Sources/AudioPriority"
        )
    ]
)
