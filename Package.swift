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
            url: "https://github.com/stasel/WebRTC/releases/download/116.0.0/WebRTC-M116.xcframework.zip",
            checksum: "64ad62a44714a115a65c071925f94000e5df06f03eed7a407ba10947ab0e7b34"
        ),
    ]
)
