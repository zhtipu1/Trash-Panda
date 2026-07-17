// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppManager",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "AppManager",
            path: "Sources/AppManager"
        )
    ]
)
