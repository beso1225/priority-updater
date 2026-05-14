// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PriorityUpdater",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PriorityUpdater",
            path: "./"
        )
    ]
)
