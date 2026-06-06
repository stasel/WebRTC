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
            url: "https://github.com/stasel/WebRTC/releases/download/149.0.0/WebRTC-M149.xcframework.zip",
            checksum: "9726f1db0c99e69806257a7166fb16f79a41035240384a04803902a509f0fc8c"
        ),
    ]
)
