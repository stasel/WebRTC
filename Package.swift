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
            url: "https://github.com/stasel/WebRTC/releases/download/93.0.0/WebRTC-M93.xcframework.zip",
            checksum: "9327632f97003ae20edf2731864a8d93676a6c46f340ef943a16d4007a76c363"
        ),
    ]
)
