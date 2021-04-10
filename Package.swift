// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/stasel/WebRTC/releases/download/90.0.0/WebRTC-M90.xcframework.zip",
            checksum: "a9c4162321e1a94c11f6e7913a32d58c647ee7909371dca2df0b0ba3a0bbc50f"
        ),
    ]
)
