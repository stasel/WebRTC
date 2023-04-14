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
            url: "https://github.com/stasel/WebRTC/releases/download/112.0.0/WebRTC-M112.xcframework.zip",
            checksum: "d7e6b2d667a346182803f5d3d80f1487ec1f43ed0a630a96aaedfe746c5780eb"
        ),
    ]
)
