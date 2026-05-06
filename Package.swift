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
            url: "https://github.com/stasel/WebRTC/releases/download/148.0.0/WebRTC-M148.xcframework.zip",
            checksum: "605ae20773b0fd6ee337d18d8e741336d5de427684d40cfd83bb8582daf285de"
        ),
    ]
)
