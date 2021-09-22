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
            url: "https://github.com/stasel/WebRTC/releases/download/94.0.0/WebRTC-M94.xcframework.zip",
            checksum: "0cfdef2b632518de31507fcf401811ed1cfff7765fc1a9251e601e9e8c9c6e6c"
        ),
    ]
)
