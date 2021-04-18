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
            url: "https://github.com/stasel/WebRTC/releases/download/91.0.0/WebRTC-M91.xcframework.zip",
            checksum: "2f2ef9c1b1802ccde0a27de3978c8673b3b12c07698a95607e8c0aa30c81c544"
        ),
    ]
)
