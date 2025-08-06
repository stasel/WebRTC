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
            url: "https://github.com/stasel/WebRTC/releases/download/139.0.0/WebRTC-M139.xcframework.zip",
            checksum: "c3f041d4e1c0b9b12ae9f45e4e702205ec1cbe7f3146b32bd1621209f7dbae07"
        ),
    ]
)
