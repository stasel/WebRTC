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
            url: "https://github.com/stasel/WebRTC/releases/download/134.0.0/WebRTC-M134.xcframework.zip",
            checksum: "c714c65f5405b38762f94208b0ee2e9fdc3bb4ba5c503fedf52944a73fe179d8"
        ),
    ]
)
