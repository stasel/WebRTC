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
            url: "https://github.com/stasel/WebRTC/releases/download/129.0.0/WebRTC-M129.xcframework.zip",
            checksum: "2e93f0fca76095909399540766cc1382d687646231e530ecb40b8e1ba275f2b9"
        ),
    ]
)
