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
            url: "https://github.com/stasel/WebRTC/releases/download/106.0.0/WebRTC-M106.xcframework.zip",
            checksum: "ed096da17e91236393c2d714655dda60567062c4ba8095d0df71e5e2154c29b9"
        ),
    ]
)
