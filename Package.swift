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
            url: "https://github.com/stasel/WebRTC/releases/download/104.0.0/WebRTC-M104.xcframework.zip",
            checksum: "cb0c8ed20756b9c7cbfce71a4fae1998e1dca06bdff169ea40588415ed3a545b"
        ),
    ]
)
