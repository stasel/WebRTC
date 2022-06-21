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
            url: "https://github.com/stasel/WebRTC/releases/download/103.0.0/WebRTC-M103.xcframework.zip",
            checksum: "532f162f16fc7105d5d8299b486c96fe21ca3b4b70a0cf20a4d8895d8d14d39c"
        ),
    ]
)
