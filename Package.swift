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
            url: "https://github.com/stasel/WebRTC/releases/download/125.0.0/WebRTC-M125.xcframework.zip",
            checksum: "4da2f9c7b7481a82249ea61dfcceae7caac6890e0a0412389684765435113ae8"
        ),
    ]
)
