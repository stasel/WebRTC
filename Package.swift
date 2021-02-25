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
            url: "https://github.com/stasel/WebRTC/releases/download/88.0.0/WebRTC-M88.xcframework.zip",
            checksum: "e58092c72e1f64f9981ad1a2626a63f07c957a6ebaf6fc70f47bcf5b9114ce14"
        ),
    ]
)
