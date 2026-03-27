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
            url: "https://github.com/stasel/WebRTC/releases/download/146.0.0/WebRTC-M146.xcframework.zip",
            checksum: "f805abcbe577f838ef86b5ecfd03bd2151dc8709360e720f6ed364a1b7a0bfb2"
        ),
    ]
)
