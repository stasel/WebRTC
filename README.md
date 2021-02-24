# WebRTC Binaries for iOS
This repository contains unofficial distribution of WebRTC framework binaries for iOS.

Since version M80, Google has [deprecated](https://groups.google.com/g/discuss-webrtc/c/Ozvbd0p7Q1Y/m/M4WN2cRKCwAJ?pli=1) their mobile binary libraries distributions (Was officially using the [GoogleWebRTC pod](https://cocoapods.org/pods/GoogleWebRTC)). To get the most up to date WebRTC library, you can compile it on your own, or you can use precompiled binaries from other sources.

## Releases
The binary releases correspond with official Chromium releases and branches as specified in the [Chromium dashboard](https://chromiumdash.appspot.com/branches).

## 💡 Things to know
* All binaries in this repository are compiled from the official WebRTC [source code](https://webrtc.googlesource.com/src/) without any modifications to the sources code or to the output binaries.
* Static framework (xcframework format) which contains binaries for both arm64 and x68_x64.
* 32-bit binaries are not included.
* Bitcode is included and this is the reason for the larger file size.

## Installation

### Swift package manager
TBD

### Manual
TBD

## Compile your own WebRTC Frameworks
If you wish to compile your own WebRTC binary framework, please refer to the following official guide:
https://webrtc.googlesource.com/src/+/refs/heads/master/docs/native-code/ios/index.md

## License
* BSD 3-Clause License
* WebRTC License: https://webrtc.org/support/license
