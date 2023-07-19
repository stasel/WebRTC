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
            url: "https://github.com/stasel/WebRTC/releases/download/115.0.0/WebRTC-M115.xcframework.zip",
            checksum: "91513f2f926c6b660a58690042cefe4ebd73710e2bec475906923bb9599b0df3"
        ),
    ]
)
