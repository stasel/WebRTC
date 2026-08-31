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
            url: "https://github.com/stasel/WebRTC/releases/download/152.0.0/WebRTC-M152.xcframework.zip",
            checksum: "c591189fa8dfed97f15ffc6d132defd426480a2809e05938d8b6797295455534"
        ),
    ]
)
