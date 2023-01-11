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
            url: "https://github.com/stasel/WebRTC/releases/download/109.0.0/WebRTC-M109.xcframework.zip",
            checksum: "24f22b7a283e4c37daec64cf030fc356dff27d58e37eb0a604a084b28c5b06d8"
        ),
    ]
)
