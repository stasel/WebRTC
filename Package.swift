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
            url: "https://github.com/stasel/WebRTC/releases/download/150.0.0/WebRTC-M150.xcframework.zip",
            checksum: "fcaa3358b0d5929a8dcde12259ae82444201a7a88649329a3ad685518cf8d18e"
        ),
    ]
)
