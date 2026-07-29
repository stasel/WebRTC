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
            url: "https://github.com/stasel/WebRTC/releases/download/151.0.0/WebRTC-M151.xcframework.zip",
            checksum: "64a218fad3d84a0d783321aa9a1eec58ca266ac7879123f86b0b44b703b7d8dc"
        ),
    ]
)
