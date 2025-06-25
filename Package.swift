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
            url: "https://github.com/stasel/WebRTC/releases/download/138.0.0/WebRTC-M138.xcframework.zip",
            checksum: "75ef1aa5b05c83ecf7fe4d020c0133c04c9817165225f66a473e5850b168f79b"
        ),
    ]
)
