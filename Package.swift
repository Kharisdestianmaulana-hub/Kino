// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Kino",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "Kino", targets: ["Kino"]),
    ],
    targets: [
        .target(
            name: "Kino",
            dependencies: [],
            path: "Kino",
            exclude: ["App", "UI", "Kino.entitlements", "Assets.xcassets", "Preview Content"]
        ),
        .testTarget(
            name: "KinoTests",
            dependencies: ["Kino"],
            path: "KinoTests"
        ),
    ]
)
