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
            url: "https://github.com/stasel/WebRTC/releases/download/107.0.0/WebRTC-M107.xcframework.zip",
            checksum: "c59563e5c5e1209bbc4658a665d93da5b55983949ffb68b7e9bc26631a9173b0"
        ),
    ]
)
