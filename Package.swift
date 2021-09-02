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
            url: "https://github.com/stasel/WebRTC/releases/download/93.0.0/WebRTC-M93.xcframework.zip",
            checksum: "b1b71cb7a02a371d449782e2d7918f9324ffe5ee9ec2d249cc12640b8edae5ad"
        ),
    ]
)
