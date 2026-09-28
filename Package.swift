// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [.iOS(.v14), .macOS(.v11), .tvOS(.v17)],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/tylerjonesio/WebRTC/releases/download/153.0.1/WebRTC-2026-09-28T21-39-57.xcframework.zip",
            checksum: "2d8039e9f5e703ec96fb88a87838ade7b1840df9e31c352cfea29980304df27a"
        ),
    ]
)
