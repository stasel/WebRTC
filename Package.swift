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
            url: "https://github.com/stasel/WebRTC/releases/download/127.0.0/WebRTC-M127.xcframework.zip",
            checksum: "8a2fd917c8d7a9aecb78677beb981b7e7ce146c6dbdc5cdab94494e74d476b69"
        ),
    ]
)
