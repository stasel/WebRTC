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
            url: "https://github.com/stasel/WebRTC/releases/download/133.0.0/WebRTC-M133.xcframework.zip",
            checksum: "47036116bb0478613adc003c6b6a2df6ed3339c63037543ffa89a5dd90d6a313"
        ),
    ]
)
