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
            url: "https://github.com/stasel/WebRTC/releases/download/131.0.0/WebRTC-M131.xcframework.zip",
            checksum: "475c689cf57893d953acca721ca650cf1aaad886051f75defa6c01157abc3b11"
        ),
    ]
)
