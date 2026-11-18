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
            url: "https://github.com/stasel/WebRTC/releases/download/158.0.0/WebRTC-M158.xcframework.zip",
            checksum: "dd26ba28fb9c8dbc82f4be3085e8d112a4e2a4e654e1786a9977a748c24c4912"
        ),
    ]
)
