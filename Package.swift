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
            url: "https://github.com/stasel/WebRTC/releases/download/105.0.0/WebRTC-M105.xcframework.zip",
            checksum: "051e8eb50942a127064d7986bf278fc34f1ac38a1d079f9b08deb5d9f6e68780"
        ),
    ]
)
