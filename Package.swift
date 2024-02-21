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
            url: "https://github.com/stasel/WebRTC/releases/download/122.0.0/WebRTC-M122.xcframework.zip",
            checksum: "79c63e26621e239f9eebacbe6f21371d8a4a55471a648c093ea4e2c72a7e824b"
        ),
    ]
)
