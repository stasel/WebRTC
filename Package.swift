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
            url: "https://github.com/stasel/WebRTC/releases/download/109.0.1/WebRTC-M109.0.1.xcframework.zip",
            checksum: "28f5fa694cc9ccc36eb5b7ac19305e1fbf0ade03eabfd02cbc0386cda693c9f1"
        ),
    ]
)
