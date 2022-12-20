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
            url: "https://github.com/stasel/WebRTC/releases/download/108.0.0/WebRTC-M108.xcframework.zip",
            checksum: "163d30aff3d84d9fc74cf75aaacb84546d857f86330a78b566ab8e0eccf86e65"
        ),
    ]
)
