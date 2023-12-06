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
            url: "https://github.com/stasel/WebRTC/releases/download/120.0.0/WebRTC-M120.xcframework.zip",
            checksum: "47f6642cb9cd61da99086f091c0519c12a5641c99626e07344f2510b76ee93c5"
        ),
    ]
)
