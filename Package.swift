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
            url: "https://github.com/stasel/WebRTC/releases/download/117.0.0/WebRTC-M117.xcframework.zip",
            checksum: "0982983d3918737b9c5c6675ed8fc4ff5afb7d606942eb6e108fdb2b894c9354"
        ),
    ]
)
