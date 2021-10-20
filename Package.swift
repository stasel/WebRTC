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
            url: "https://github.com/stasel/WebRTC/releases/download/95.0.0/WebRTC-M95.xcframework.zip",
            checksum: "11f6442c43aaee3e24075c43bd3282e3d01832edf2214aaf222f670a3ef74d62"
        ),
    ]
)
