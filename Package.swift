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
            url: "https://github.com/stasel/WebRTC/releases/download/107.0.0/WebRTC-M107.xcframework.zip",
            checksum: "dc7fa330c84ab56f8ec74531bb3a493adfde1fcf7cacf3074a6297e7883e46be"
        ),
    ]
)
