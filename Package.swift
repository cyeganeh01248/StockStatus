// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StockStatus",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "StockStatus",
            targets: ["StockStatus"]
        )
    ],
    targets: [
        .executableTarget(
            name: "StockStatus",
            path: "StockStatus",
            exclude: [
                "Resources/Info.plist",
                "Resources/StockStatus.entitlements"
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        )
    ]
)
