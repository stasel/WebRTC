// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/stasel/WebRTC/releases/download/89.0.0/WebRTC-M89.xcframework.zip",
            checksum: "9360780d30e7b498d3fff0a59e41aef0653e3210f344572a09e3d5a3cde0c3b5"
        ),
    ]
)
