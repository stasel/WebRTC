#!/bin/sh

set -eu

assert_contains() {
    file=$1
    pattern=$2
    description=$3

    if ! rg -q "$pattern" "$file"; then
        echo "Missing ${description} in ${file}" >&2
        exit 1
    fi
}

assert_not_contains() {
    file=$1
    pattern=$2
    description=$3

    if rg -q "$pattern" "$file"; then
        echo "Unexpected ${description} in ${file}" >&2
        exit 1
    fi
}

assert_contains scripts/build.sh 'TVOS="\$\{TVOS:-false\}"' "TVOS build toggle"
assert_contains scripts/build.sh 'build_tvOS\(\)' "tvOS build function"
assert_contains scripts/build.sh 'apply_tvOS_patches\(\)' "tvOS source patch function"
assert_contains scripts/build.sh 'patches/tvos/\*.patch' "tvOS source patch glob"
assert_contains scripts/build.sh 'target_platform=\\"tvos\\"' "tvOS GN target platform"
assert_contains scripts/build.sh 'use_blink=true' "tvOS GN use_blink override"
assert_contains scripts/build.sh 'TVOS_LIB_IDENTIFIER="tvos-arm64"' "tvOS device XCFramework library"
assert_contains scripts/build.sh 'TVOS_SIM_LIB_IDENTIFIER="tvos-arm64-simulator"' "tvOS simulator XCFramework library"
assert_not_contains scripts/build.sh 'build_tvOS "x64" "simulator"' "x86_64 tvOS simulator build"
assert_not_contains scripts/build.sh 'tvos-x64-simulator' "x86_64 tvOS simulator packaging"
assert_contains .github/workflows/webrtc-build.yml 'tvos:' "manual workflow tvOS input"
assert_contains .github/workflows/webrtc-build.yml 'TVOS: \$\{\{ inputs.tvos \}\}' "manual workflow TVOS env"
assert_contains scripts/release.py 'os.environ\["TVOS"\] = "true"' "release TVOS env"
assert_contains Package.swift '\.tvOS\(\.v12\)' "SwiftPM tvOS platform"
assert_contains WebRTC-lib.podspec "spec.tvos.deployment_target = '12.0'" "CocoaPods tvOS deployment target"
assert_contains README.md 'tvOS 12\+' "README tvOS requirement"
assert_contains README.md '\*\*tvOS \(device\)\*\*' "README tvOS device binary row"
assert_contains README.md '\*\*tvOS \(simulator\)\*\*' "README tvOS simulator binary row"
assert_contains patches/tvos/RTCAudioSessionConfiguration.patch 'TARGET_OS_TV' "tvOS audio session availability guard"
assert_contains patches/tvos/RTCAudioSessionConfiguration.patch 'AVAudioSessionCategoryOptionAllowBluetooth' "tvOS Bluetooth option patch context"
assert_contains patches/tvos/VoiceProcessingAudioUnit.patch 'tvOS 17' "tvOS muted speech listener availability guard"
assert_contains patches/tvos/VoiceProcessingAudioUnit.patch 'AUVoiceIOMutedSpeechActivityEventListener' "tvOS muted speech listener patch context"
assert_contains patches/tvos/RTCMTLRenderer.patch 'TARGET_OS_IPHONE' "tvOS Metal renderer UIKit gate"
assert_contains patches/tvos/RTCMTLRenderer.patch 'addRenderingDestination' "tvOS Metal renderer patch context"
assert_contains patches/tvos/BUILD.gn.patch 'target_platform != "tvos"' "tvOS camera capturer build exclusion"
assert_contains patches/tvos/BUILD.gn.patch 'RTCCameraVideoCapturer.h' "tvOS camera capturer header exclusion"

echo "tvOS support metadata is present"
