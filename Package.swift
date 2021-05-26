// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/stasel/WebRTC/releases/download/91.0.0/WebRTC-M91.xcframework.zip",
            checksum: "bb709f5db920b2d515ed07d4a279c67f711857896d0c9158ce907eae9930d060"
        ),
    ]
)
