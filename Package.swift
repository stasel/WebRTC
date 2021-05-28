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
            checksum: "3e8406f17956de6ce6b1da27b64fb917ed19cf8e9794df4b96677bcd7b39285a"
        ),
    ]
)
