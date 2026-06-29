// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "hovr_app_update",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "hovr-app-update", targets: ["hovr_app_update"]),
    ],
    targets: [
        .target(
            name: "hovr_app_update",
            path: "Sources/hovr_app_update"
        ),
        .testTarget(
            name: "VersionCompareTests",
            dependencies: ["hovr_app_update"],
            path: "Tests"
        ),
    ]
)
