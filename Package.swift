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
            url: "https://github.com/stasel/WebRTC/releases/download/124.0.0/WebRTC-M124.xcframework.zip",
            checksum: "682e40eb2d32a5214228759c07293977e90818aeb957f622f95b76dc1bc7b8f2"
        ),
    ]
)
