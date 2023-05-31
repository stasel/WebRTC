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
            url: "https://github.com/stasel/WebRTC/releases/download/114.0.0/WebRTC-M114.xcframework.zip",
            checksum: "023b2c9fb53ff014607ef2afe87e3a83c2632555562783ced682715e85da0cd9"
        ),
    ]
)
