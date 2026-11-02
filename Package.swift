// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "Requestly",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Requestly", targets: ["RequestlyApp"]),
        .library(name: "RequestlyCore", targets: ["RequestlyCore"])
    ],
    targets: [
        .target(
            name: "RequestlyCore",
            path: "Sources/RequestlyCore",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .executableTarget(
            name: "RequestlyApp",
            dependencies: ["RequestlyCore"],
            path: "Sources/RequestlyApp"
        ),
        .testTarget(
            name: "RequestlyTests",
            dependencies: ["RequestlyCore"],
            path: "Tests/RequestlyTests"
        )
    ]
)
