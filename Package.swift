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
            url: "https://github.com/stasel/WebRTC/releases/download/156.0.0/WebRTC-M156.xcframework.zip",
            checksum: "43c2a6f7a650185bbc911d7605a979589671886e8fc0ac283f54fdf3f511dc46"
        ),
    ]
)
