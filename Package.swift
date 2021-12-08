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
            url: "https://github.com/stasel/WebRTC/releases/download/96.0.0/WebRTC-M96.xcframework.zip",
            checksum: "acc47c83baa30f3ed11847eda09d1a76b9345da7f025e1af08b3eb6da63ca99f"
        ),
    ]
)
