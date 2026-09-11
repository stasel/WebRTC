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
            url: "https://github.com/stasel/WebRTC/releases/download/153.0.0/WebRTC-M153.xcframework.zip",
            checksum: "3e3a8946f27510133e3feed04d05fa23505bbe366e977620503bfc7986c2b78f"
        ),
    ]
)
