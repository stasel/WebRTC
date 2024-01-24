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
            url: "https://github.com/stasel/WebRTC/releases/download/121.0.0/WebRTC-M121.xcframework.zip",
            checksum: "eb5d48c81ebed1575daed3b7f62487e98dca1dff4379b8614dca2a1a4d9e799e"
        ),
    ]
)
