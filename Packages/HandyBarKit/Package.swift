// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HandyBarKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HandyBarUI", targets: ["HandyBarUI"])
    ],
    targets: [
        .target(name: "HandyBarAlarm"),
        .target(name: "HandyBarAutoClick"),
        .target(name: "HandyBarCleanup"),
        .target(
            name: "HandyBarUI",
            dependencies: ["HandyBarAlarm", "HandyBarAutoClick", "HandyBarCleanup"]
        ),
        .testTarget(name: "HandyBarAlarmTests", dependencies: ["HandyBarAlarm"]),
        .testTarget(name: "HandyBarAutoClickTests", dependencies: ["HandyBarAutoClick"]),
        .testTarget(name: "HandyBarCleanupTests", dependencies: ["HandyBarCleanup"]),
        .testTarget(name: "HandyBarUITests", dependencies: ["HandyBarUI"]),
    ]
)
