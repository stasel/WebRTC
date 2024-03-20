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
            url: "https://github.com/stasel/WebRTC/releases/download/123.0.0/WebRTC-M123.xcframework.zip",
            checksum: "a40a1299d41af76451c0316a54dc05f7e7fa2032a02bd240cacbf3545c7359fe"
        ),
    ]
)
