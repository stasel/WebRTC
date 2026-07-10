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
            url: "https://github.com/stasel/WebRTC/releases/download/150.0.0/WebRTC-M150.xcframework.zip",
            checksum: "f9890492b0016e4c88ab20f07867b8b420054caedc8a692b2ec6ac041f3cf6b2"
        ),
    ]
)
