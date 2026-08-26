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
            url: "https://github.com/stasel/WebRTC/releases/download/152.0.0/WebRTC-M152.xcframework.zip",
            checksum: "3927798a96cd16d35a1dccbc8c9b228b78086c688c06fd65650eed79955f4570"
        ),
    ]
)
