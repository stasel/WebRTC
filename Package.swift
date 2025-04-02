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
            url: "https://github.com/stasel/WebRTC/releases/download/135.0.0/WebRTC-M135.xcframework.zip",
            checksum: "f33336c74d7a5d42a257b0aeca2315b50473c611b74f22dac7e41c38cbe84351"
        ),
    ]
)
