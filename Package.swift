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
            url: "https://github.com/stasel/WebRTC/releases/download/132.0.0/WebRTC-M132.xcframework.zip",
            checksum: "aebe7395dcf40b3b40ac3ab6e3e3d7163611aea7312f26d4161eff3720dd123a"
        ),
    ]
)
