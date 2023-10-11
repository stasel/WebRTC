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
            url: "https://github.com/stasel/WebRTC/releases/download/118.0.0/WebRTC-M118.xcframework.zip",
            checksum: "3b1e5da6f78c2a7b97c9d2d1e3a725e8c09caa49d5880023a537d6c98e9c8eee"
        ),
    ]
)
