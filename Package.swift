// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PriorityUpdater",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PriorityUpdaterCore",
            targets: ["PriorityUpdaterCore"]
        ),
        .executable(
            name: "priority-updater",
            targets: ["PriorityUpdaterCLI"]
        )
    ],
    targets: [
        .target(
            name: "PriorityUpdaterCore"
        ),
        .executableTarget(
            name: "PriorityUpdaterCLI",
            dependencies: ["PriorityUpdaterCore"]
        )
    ]
)
