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
            url: "https://github.com/stasel/WebRTC/releases/download/92.0.0/WebRTC-M92.xcframework.zip",
            checksum: "e0824a440766dbe58a06956af72a75eea5fc5b7d154583a46af499cbb11ec40c"
        ),
    ]
)
