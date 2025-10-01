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
            url: "https://github.com/stasel/WebRTC/releases/download/141.0.0/WebRTC-M141.xcframework.zip",
            checksum: "e3b9bc1aed7a6f3f747a62567680ac7837bdbb74d1fae8f0f543131bc1bf8a5f"
        ),
    ]
)
