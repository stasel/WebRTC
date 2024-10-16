// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [.iOS(.v10), .macOS(.v10_11)],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/stasel/WebRTC/releases/download/130.0.0/WebRTC-M130.xcframework.zip",
            checksum: "3b09833ae2b3aaa3755dc21f194dcba7564cf26de6af04876e2737c4927a8703"
        ),
    ]
)
