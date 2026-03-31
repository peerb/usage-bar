// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "UsageBar",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "UsageBar",
            path: "Sources/UsageBar"
        )
    ]
)
