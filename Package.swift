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
            url: "https://github.com/stasel/WebRTC/releases/download/128.0.0/WebRTC-M128.xcframework.zip",
            checksum: "468cf792823b2d9e984bdab18311822cc42f34a905145f475ac6132b28061ff0"
        ),
    ]
)
