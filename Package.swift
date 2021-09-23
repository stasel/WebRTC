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
            url: "https://github.com/stasel/WebRTC/releases/download/94.0.0/WebRTC-M94.xcframework.zip",
            checksum: "8b566fa9afc54da1ab70ce2bdad5b7d86099836732ca46a9962f7536bea0b78b"
        ),
    ]
)
