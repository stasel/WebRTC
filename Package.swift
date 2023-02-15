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
            url: "https://github.com/stasel/WebRTC/releases/download/110.0.0/WebRTC-M110.0.0.xcframework.zip",
            checksum: "9a74ee5412f8ee5d6b407ea51c44c17484c05d0b3d346d737fbb1fb9ff278a80"
        ),
    ]
)
