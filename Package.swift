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
            url: "https://github.com/stasel/WebRTC/releases/download/157.0.0/WebRTC-M157.xcframework.zip",
            checksum: "ffb1221be2138ecc6bc92300ae4f0157e18694d652db9921e4251992ea91a328"
        ),
    ]
)
