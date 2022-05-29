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
            url: "https://github.com/stasel/WebRTC/releases/download/102.0.0/WebRTC-M102.xcframework.zip",
            checksum: "67167669e6ca4530c901ac53decc197137ffae0302aa369e86d601c08a4eaf21"
        ),
    ]
)
