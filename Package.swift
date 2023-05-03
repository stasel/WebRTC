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
            url: "https://github.com/stasel/WebRTC/releases/download/113.0.0/WebRTC-M113.xcframework.zip",
            checksum: "8d7afcd3ff5626205784f63765bd7e363eb02be61a6e8c99777771dedcfed319"
        ),
    ]
)
