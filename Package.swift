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
            url: "https://github.com/stasel/WebRTC/releases/download/146.0.0/WebRTC-M146.xcframework.zip",
            checksum: "fb7e2dcadfb8f7052f35135369eee890c47c0e9d1972ae3cab21bc100bf939b4"
        ),
    ]
)
