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
            url: "https://github.com/stasel/WebRTC/releases/download/126.0.0/WebRTC-M126.xcframework.zip",
            checksum: "344d805dacc5576317fc50942672126054da03fb395e4fce378b20bb845106d7"
        ),
    ]
)
