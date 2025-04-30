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
            url: "https://github.com/stasel/WebRTC/releases/download/136.0.0/WebRTC-M136.xcframework.zip",
            checksum: "1d6f76b91ca6d40a143cec093781e3cc954a6754edced4662851aaead96e19ef"
        ),
    ]
)
