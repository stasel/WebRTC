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
            url: "https://github.com/stasel/WebRTC/releases/download/140.0.0/WebRTC-M140.xcframework.zip",
            checksum: "0d61faf67dd145545bf8a0017bdcdbe7a9a1f3a96cce0d501e526655711d98d2"
        ),
    ]
)
