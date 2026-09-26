#!/bin/sh

## WebRTC library build script
## Created by Stasel
## BSD-3 License
## 
## Example usage (from the repository root):
## BRANCH=branch-heads/7727 MACOS=true IOS=true VISIONOS=true sh scripts/build.sh

# Configs
DEBUG="${DEBUG:-false}"
BRANCH="${BRANCH:-main}"
IOS="${IOS:-false}"
MACOS="${MACOS:-false}"
MAC_CATALYST="${MAC_CATALYST:-false}"
VISIONOS="${VISIONOS:-false}"

ROOT_DIR="$(pwd)"
OUTPUT_DIR="${ROOT_DIR}/out"
XCFRAMEWORK_DIR="${OUTPUT_DIR}/WebRTC.xcframework"
COMMON_GN_ARGS="is_debug=${DEBUG} rtc_libvpx_build_vp9=true is_component_build=false rtc_include_tests=false rtc_build_examples=false rtc_build_tools=false rtc_enable_objc_symbol_export=true enable_stripping=true enable_dsyms=true use_lld=true rtc_system_openh264=true rtc_use_h265=true"
PLISTBUDDY_EXEC="/usr/libexec/PlistBuddy"


build_iOS() {
    local arch=$1
    local environment=$2
    local gen_dir="${OUTPUT_DIR}/ios-${arch}-${environment}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_os=\"ios\" target_environment=\"${environment}\" ios_deployment_target=\"12.0\" ios_enable_code_signing=false rtc_ios_use_opengl_rendering=true"
    gn gen "${gen_dir}" --args="${gen_args}"
    gn args --list ${gen_dir} > ${gen_dir}/gn-args.txt
    ninja -C "${gen_dir}" framework_objc || exit 1
}

build_macOS() {
    local arch=$1
    local gen_dir="${OUTPUT_DIR}/macos-${arch}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_os=\"mac\""
    gn gen "${gen_dir}" --args="${gen_args}"
    gn args --list ${gen_dir} > ${gen_dir}/gn-args.txt
    ninja -C "${gen_dir}" mac_framework_objc || exit 1
}

# Catalyst builds are not working properly yet. 
# See: https://groups.google.com/g/discuss-webrtc/c/VZXS4V4mSY4
# Must link Catalyst with Apple's linker instead of lld (use_lld=false)
build_catalyst() {
    local arch=$1
    local gen_dir="${OUTPUT_DIR}/catalyst-${arch}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_environment=\"catalyst\" target_os=\"ios\" ios_deployment_target=\"14.0\" ios_enable_code_signing=false use_lld=false rtc_ios_use_opengl_rendering=true"
    gn gen "${gen_dir}" --args="${gen_args}"
    gn args --list ${gen_dir} > ${gen_dir}/gn-args.txt
    ninja -C "${gen_dir}" framework_objc || exit 1
}

build_visionOS() {
    local arch=$1
    local environment=$2
    local gen_dir

    if [ "${environment}" = "simulator" ]; then
        gen_dir="${OUTPUT_DIR}/visionos-${arch}-simulator"
    else
        gen_dir="${OUTPUT_DIR}/visionos-arm64-device"
    fi

    local gen_args="${COMMON_GN_ARGS}"
    gen_args="${gen_args} target_cpu=\"${arch}\" target_os=\"ios\""
    gen_args="${gen_args} target_environment=\"${environment}\""
    gen_args="${gen_args} target_platform=\"xros\" xros=true"
    gen_args="${gen_args} ios_deployment_target=\"2.0\""
    gen_args="${gen_args} ios_enable_code_signing=false"
    gen_args="${gen_args} rtc_ios_use_opengl_rendering=false"
    gen_args="${gen_args} rtc_build_libvpx=false"
    gen_args="${gen_args} rtc_libvpx_build_vp9=false"
    gen_args="${gen_args} enable_libaom=false"
    gen_args="${gen_args} rtc_include_dav1d_in_internal_decoder_factory=false"
    gen_args="${gen_args} rtc_use_h264=false rtc_use_h265=false"
    gen_args="${gen_args} use_custom_libcxx=false"
    gen_args="${gen_args} clang_use_chrome_plugins=false use_lld=false"
    gn gen "${gen_dir}" --args="${gen_args}"
    gn args --list ${gen_dir} > ${gen_dir}/gn-args.txt
    ninja -C "${gen_dir}" framework_objc || exit 1
}

plist_add_library() {
    local index=$1
    local identifier=$2
    local platform=$3
    local platform_variant=$4
    "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries: dict"  "${INFO_PLIST}"
    "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries:${index}:LibraryIdentifier string ${identifier}"  "${INFO_PLIST}"
    "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries:${index}:LibraryPath string WebRTC.framework"  "${INFO_PLIST}"
    "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries:${index}:SupportedArchitectures array"  "${INFO_PLIST}"
    "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries:${index}:SupportedPlatform string ${platform}"  "${INFO_PLIST}"
    if [ ! -z "$platform_variant" ]; then
        "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries:${index}:SupportedPlatformVariant string ${platform_variant}" "${INFO_PLIST}"
    fi
}

plist_add_architecture() {
    local index=$1
    local arch=$2
    "$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries:${index}:SupportedArchitectures: string ${arch}"  "${INFO_PLIST}"
}

fix_privacy_manifest() {
    local framework=$1
    local nested="${framework}/Versions/A/Versions"
    if [ -f "${nested}/A/Resources/PrivacyInfo.xcprivacy" ]; then
        mv "${nested}/A/Resources/PrivacyInfo.xcprivacy" "${framework}/Versions/A/Resources/" || exit 1
        rm -rf "${nested}"
    fi
}

fix_visionos_framework_plist() {
    local framework=$1
    local platform=$2
    local sdk_name=$3
    local info_plist="${framework}/Info.plist"

    if [ ! -f "${info_plist}" ]; then
        info_plist="${framework}/Versions/A/Resources/Info.plist"
    fi

    if [ ! -f "${info_plist}" ]; then
        return
    fi

    "$PLISTBUDDY_EXEC" \
        -c "Delete :CFBundleSupportedPlatforms" \
        "${info_plist}" 2>/dev/null
    "$PLISTBUDDY_EXEC" -c "Add :CFBundleSupportedPlatforms array" "${info_plist}"
    "$PLISTBUDDY_EXEC" -c "Add :CFBundleSupportedPlatforms: string ${platform}" "${info_plist}"
    "$PLISTBUDDY_EXEC" \
        -c "Set :DTPlatformName ${sdk_name}" \
        "${info_plist}" 2>/dev/null
    local sdk_version="$(xcrun --sdk "${sdk_name}" --show-sdk-version)"
    "$PLISTBUDDY_EXEC" \
        -c "Set :DTSDKName ${sdk_name}${sdk_version}" \
        "${info_plist}" 2>/dev/null
    "$PLISTBUDDY_EXEC" \
        -c "Set :MinimumOSVersion 2.0" \
        "${info_plist}" 2>/dev/null
    "$PLISTBUDDY_EXEC" \
        -c "Delete :UIDeviceFamily" \
        "${info_plist}" 2>/dev/null
    "$PLISTBUDDY_EXEC" -c "Add :UIDeviceFamily array" "${info_plist}"
    "$PLISTBUDDY_EXEC" -c "Add :UIDeviceFamily: integer 7" "${info_plist}"
}

patch_visionos_build_config() {
    [ "$VISIONOS" = true ] || return 0

    python3 - <<'PY'
from pathlib import Path

def replace(path, old, new, count=-1):
    file_path = Path(path)
    text = file_path.read_text()
    if old not in text:
        raise SystemExit(f"pattern not found in {path}")
    file_path.write_text(text.replace(old, new, count))

replace(
    "src/build/config/apple/mobile_config.gni",
    '  # Valid values: "iphoneos" (default), "tvos", "watchos".\n',
    '  # Valid values: "iphoneos" (default), "tvos", "watchos", "xros".\n',
)
replace(
    "src/build/config/apple/mobile_config.gni",
    '      "tvos",\n    ]\n',
    '      "tvos",\n      "xros",\n    ]\n',
)
replace(
    "src/build/config/apple/sdk_info.py",
    '''            'macosx',
            'watchos',
            'watchsimulator',
''',
    '''            'macosx',
            'watchos',
            'watchsimulator',
            'xros',
            'xrsimulator',
''',
)
replace(
    "src/build/config/apple/codesign.py",
    '''        if platform in ('iphoneos', 'iphonesimulator'):
            return 'ios'
''',
    '''        if platform in (
                'iphoneos', 'iphonesimulator', 'xros', 'xrsimulator'):
            return 'ios'
''',
)
replace(
    "src/build/config/ios/ios_sdk.gni",
    '''  } else if (target_platform == "tvos") {
    if (target_environment == "simulator") {
      ios_sdk_name = "appletvsimulator"
      ios_sdk_platform = "AppleTVSimulator"
    } else if (target_environment == "device") {
      ios_sdk_name = "appletvos"
      ios_sdk_platform = "AppleTVOS"
    } else {
      assert(false, "unsupported target_environment=$target_environment")
    }
  } else {
''',
    '''  } else if (target_platform == "tvos") {
    if (target_environment == "simulator") {
      ios_sdk_name = "appletvsimulator"
      ios_sdk_platform = "AppleTVSimulator"
    } else if (target_environment == "device") {
      ios_sdk_name = "appletvos"
      ios_sdk_platform = "AppleTVOS"
    } else {
      assert(false, "unsupported target_environment=$target_environment")
    }
  } else if (target_platform == "xros") {
    if (target_environment == "simulator") {
      ios_sdk_name = "xrsimulator"
      ios_sdk_platform = "XRSimulator"
    } else if (target_environment == "device") {
      ios_sdk_name = "xros"
      ios_sdk_platform = "XROS"
    } else {
      assert(false, "unsupported target_environment=$target_environment")
    }
  } else {
''',
)
replace(
    "src/build/config/ios/BUILD.gn",
    '''  if (target_platform == "iphoneos") {
    triplet_os = "apple-ios"
  } else if (target_platform == "tvos") {
    triplet_os = "apple-tvos"
  }
''',
    '''  if (target_platform == "iphoneos") {
    triplet_os = "apple-ios"
  } else if (target_platform == "tvos") {
    triplet_os = "apple-tvos"
  } else if (target_platform == "xros") {
    triplet_os = "apple-xros"
  }
''',
)
replace(
    "src/build/config/ios/rules.gni",
    '''    if (target_platform == "iphoneos") {
      _build_info_plist = "//build/config/ios/BuildInfo.plist"
    } else if (target_platform == "tvos") {
      _build_info_plist = "//build/config/tvos/BuildInfo.plist"
    }
''',
    '''    if (target_platform == "iphoneos") {
      _build_info_plist = "//build/config/ios/BuildInfo.plist"
    } else if (target_platform == "tvos") {
      _build_info_plist = "//build/config/tvos/BuildInfo.plist"
    } else if (target_platform == "xros") {
      _build_info_plist = "//build/config/ios/BuildInfo.plist"
    }
''',
)
replace(
    "src/sdk/BUILD.gn",
    '''      if (target_platform != "tvos") {
        sources += [
          "objc/helpers/RTCCameraPreviewView.h",
          "objc/helpers/RTCCameraPreviewView.m",
        ]
      }
''',
    '''      if (target_platform != "tvos" && target_platform != "xros") {
        sources += [
          "objc/helpers/RTCCameraPreviewView.h",
          "objc/helpers/RTCCameraPreviewView.m",
        ]
      }
''',
)
replace(
    "src/sdk/BUILD.gn",
    '''      if (is_ios) {
        sources += [
          "objc/components/renderer/metal/RTCMTLVideoView.h",
          "objc/components/renderer/metal/RTCMTLVideoView.m",
        ]
        frameworks += [ "UIKit.framework" ]
      }
''',
    '''      if (is_ios && target_platform != "xros") {
        sources += [
          "objc/components/renderer/metal/RTCMTLVideoView.h",
          "objc/components/renderer/metal/RTCMTLVideoView.m",
        ]
        frameworks += [ "UIKit.framework" ]
      }
''',
)
replace(
    "src/sdk/BUILD.gn",
    '''          "objc/components/capturer/RTCCameraVideoCapturer.h",
          "objc/components/capturer/RTCFileVideoCapturer.h",
          "objc/components/network/RTCNetworkMonitor.h",
          "objc/components/renderer/metal/RTCMTLVideoView.h",
          "objc/components/renderer/opengl/RTCEAGLVideoView.h",
          "objc/components/renderer/opengl/RTCVideoViewShading.h",
''',
    '''          "objc/components/network/RTCNetworkMonitor.h",
''',
)
replace(
    "src/sdk/BUILD.gn",
    '''          "objc/components/video_frame_buffer/RTCCVPixelBuffer.h",
          "objc/helpers/RTCCameraPreviewView.h",
          "objc/helpers/RTCDispatcher.h",
''',
    '''          "objc/components/video_frame_buffer/RTCCVPixelBuffer.h",
          "objc/helpers/RTCDispatcher.h",
''',
)
replace(
    "src/sdk/BUILD.gn",
    '''          ":metal_objc",
          ":native_api",
          ":native_video",
          ":peerconnectionfactory_base_objc",
          ":videocapture_objc",
          ":videocodec_objc",
''',
    '''          ":native_api",
          ":native_video",
          ":peerconnectionfactory_base_objc",
          ":videocodec_objc",
''',
    1,
)
replace(
    "src/sdk/BUILD.gn",
    '''        deps = [
          ":audio_objc",
          ":base_objc",
          ":default_codec_factory_objc",
          ":native_api",
          ":native_video",
          ":peerconnectionfactory_base_objc",
          ":videocodec_objc",
          ":videotoolbox_objc",
        ]
''',
    '''        deps = [
          ":audio_objc",
          ":base_objc",
          ":native_api",
          ":native_video",
          ":peerconnectionfactory_base_objc",
          ":videocodec_objc",
        ]
        if (target_platform != "xros") {
          deps += [
            ":default_codec_factory_objc",
            ":videotoolbox_objc",
          ]
        }
''',
    1,
)
replace(
    "src/sdk/BUILD.gn",
    '''        if (!build_with_chromium) {
          common_objc_headers += [
            "objc/api/logging/RTCCallbackLogger.h",
            "objc/api/peerconnection/RTCFileLogger.h",
          ]
        }
''',
    '''        if (target_platform != "xros") {
          common_objc_headers += [
            "objc/components/capturer/RTCCameraVideoCapturer.h",
            "objc/components/capturer/RTCFileVideoCapturer.h",
            "objc/components/renderer/metal/RTCMTLVideoView.h",
            "objc/components/renderer/opengl/RTCEAGLVideoView.h",
            "objc/components/renderer/opengl/RTCVideoViewShading.h",
            "objc/helpers/RTCCameraPreviewView.h",
          ]
        }

        if (!build_with_chromium) {
          common_objc_headers += [
            "objc/api/logging/RTCCallbackLogger.h",
            "objc/api/peerconnection/RTCFileLogger.h",
          ]
        }
''',
    1,
)
replace(
    "src/sdk/BUILD.gn",
    '''        if (!build_with_chromium) {
          deps += [
            ":callback_logger_objc",
            ":file_logger_objc",
          ]
        }
''',
    '''        if (target_platform != "xros") {
          deps += [
            ":metal_objc",
            ":videocapture_objc",
          ]
        }

        if (!build_with_chromium) {
          deps += [
            ":callback_logger_objc",
            ":file_logger_objc",
          ]
        }
''',
    1,
)
replace(
    "src/sdk/objc/components/audio/RTCAudioSessionConfiguration.m",
    '''#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    _categoryOptions = AVAudioSessionCategoryOptionAllowBluetoothHFP;
#else
    // Use the deprecated option on older SDKs.
    _categoryOptions = AVAudioSessionCategoryOptionAllowBluetooth;
#endif
''',
    '''#if defined(__VISION_OS_VERSION_MAX_ALLOWED) || \
    (defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0)
    _categoryOptions = AVAudioSessionCategoryOptionAllowBluetoothHFP;
#else
    // Use the deprecated option on older SDKs.
    _categoryOptions = AVAudioSessionCategoryOptionAllowBluetooth;
#endif
''',
)
for source_file in (
    "src/sdk/objc/components/video_codec/RTCVideoDecoderH264.mm",
    "src/sdk/objc/components/video_codec/RTCVideoEncoderH264.mm",
):
    replace(
        source_file,
        '''#if defined(WEBRTC_IOS) && (TARGET_OS_MACCATALYST || TARGET_OS_SIMULATOR)
''',
        '''#if defined(WEBRTC_IOS) && \
    (TARGET_OS_MACCATALYST || TARGET_OS_SIMULATOR || \
     defined(__VISION_OS_VERSION_MAX_ALLOWED))
''',
    )
replace(
    "src/third_party/libvpx/BUILD.gn",
    '''if (current_cpu == "x86" || (current_cpu == "x64" && !is_msan)) {
''',
    '''if ((current_cpu == "x86" || (current_cpu == "x64" && !is_msan)) &&
    target_platform != "xros") {
''',
)
replace(
    "src/third_party/libaom/BUILD.gn",
    '''if (current_cpu == "x86" || (current_cpu == "x64" && !is_msan)) {
''',
    '''if ((current_cpu == "x86" || (current_cpu == "x64" && !is_msan)) &&
    target_platform != "xros") {
''',
)
replace(
    "src/third_party/dav1d/BUILD.gn",
    '''enable_nasm = (current_cpu == "x86" || current_cpu == "x64") && !is_msan
''',
    '''enable_nasm = (current_cpu == "x86" || current_cpu == "x64") && !is_msan && target_platform != "xros"
''',
)
replace(
    "src/build/rust/known-target-triples.txt",
    '''aarch64-apple-tvos
aarch64-apple-tvos-sim
''',
    '''aarch64-apple-tvos
aarch64-apple-tvos-sim
aarch64-apple-visionos
aarch64-apple-visionos-sim
x86_64-apple-visionos-sim
''',
)
replace(
    "src/build/config/clang/BUILD.gn",
    '''    } else if (target_platform == "tvos") {
      if (target_environment == "simulator") {
        libname = "tvossim"
      } else if (target_environment == "device") {
        libname = "tvos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else {
''',
    '''    } else if (target_platform == "tvos") {
      if (target_environment == "simulator") {
        libname = "tvossim"
      } else if (target_environment == "device") {
        libname = "tvos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else if (target_platform == "xros") {
      # Chromium's prebuilt Clang toolchain does not currently ship xros
      # compiler-rt archives. Do not add an explicit compiler_builtins
      # library; Apple platforms can resolve compiler runtime support via the
      # active Xcode toolchain during the final framework link.
    } else {
''',
)
replace(
    "src/build/config/rust.gni",
    '''    } else if (target_platform == "tvos") {
      if (target_environment == "simulator") {
        rust_abi_target = "aarch64-apple-tvos-sim"
      } else if (target_environment == "device") {
        rust_abi_target = "aarch64-apple-tvos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else {
''',
    '''    } else if (target_platform == "tvos") {
      if (target_environment == "simulator") {
        rust_abi_target = "aarch64-apple-tvos-sim"
      } else if (target_environment == "device") {
        rust_abi_target = "aarch64-apple-tvos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else if (target_platform == "xros") {
      if (target_environment == "simulator") {
        if (target_cpu == "x64") {
          rust_abi_target = "x86_64-apple-visionos-sim"
        } else {
          rust_abi_target = "aarch64-apple-visionos-sim"
        }
      } else if (target_environment == "device") {
        rust_abi_target = "aarch64-apple-visionos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else {
''',
)
replace(
    "src/build/config/rust.gni",
    '''    } else if (target_platform == "tvos") {
      if (target_environment == "simulator") {
        rust_abi_target = "x86_64-apple-tvos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else {
      assert(false, "unsupported target_platform=$target_platform")
    }
''',
    '''    } else if (target_platform == "tvos") {
      if (target_environment == "simulator") {
        rust_abi_target = "x86_64-apple-tvos"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else if (target_platform == "xros") {
      if (target_environment == "simulator") {
        rust_abi_target = "x86_64-apple-visionos-sim"
      } else {
        assert(false, "unsupported target_environment=$target_environment")
      }
    } else {
      assert(false, "unsupported target_platform=$target_platform")
    }
''',
)
PY
}

# Stage the dSYM for one XCFramework slice, named after its library identifier.
# Pass a second build directory when the slice's binary is lipo'd from two architectures.
stage_dsym() {
    local identifier=$1
    local build_dir=$2
    local extra_build_dir=$3
    local dsym="${OUTPUT_DIR}/WebRTC-${identifier}.dSYM"
    local dwarf="Contents/Resources/DWARF/WebRTC"
    local relocations="Contents/Resources/Relocations"

    rm -rf "${dsym}"
    cp -r "${OUTPUT_DIR}/${build_dir}/WebRTC.dSYM" "${dsym}" || exit 1

    if [ ! -z "${extra_build_dir}" ]; then
        cp -r "${OUTPUT_DIR}/${extra_build_dir}/WebRTC.dSYM/${relocations}/" "${dsym}/${relocations}/"
        lipo -create -output "${dsym}/${dwarf}" \
            "${OUTPUT_DIR}/${build_dir}/WebRTC.dSYM/${dwarf}" \
            "${OUTPUT_DIR}/${extra_build_dir}/WebRTC.dSYM/${dwarf}" || exit 1
    fi
}

# Step 1: Download and install depot tools
if [ ! -d depot_tools ]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
    cd depot_tools
    git pull origin main
    cd ..
fi
export PATH=$(pwd)/depot_tools:$PATH

# Bootstrap depot_tools before running any of its tools.
ensure_bootstrap || exit 1

# Step 2 - Download and build WebRTC
if [ ! -d src ]; then
    fetch --nohooks webrtc_ios || exit 1
fi
cd src
git fetch --all || exit 1
git checkout "$BRANCH" || exit 1
cd ..
gclient sync --with_branch_heads --with_tags || exit 1
patch_visionos_build_config || exit 1

# Step 2.5 - Temp patch for macOS arm64 builds
# bash "${ROOT_DIR}/scripts/patches/disable_apple_linker.sh" "${ROOT_DIR}/src/build/toolchain/apple/toolchain.gni" || exit 1

cd src

# Step 3 - Compile and build all frameworks
rm -rf $OUTPUT_DIR  

if [ "$IOS" = true ]; then
    build_iOS "x64" "simulator"
    build_iOS "arm64" "simulator"
    build_iOS "arm64" "device"
fi

if [ "$MACOS" = true ]; then
    build_macOS "x64"
    build_macOS "arm64"
fi

if [ "$MAC_CATALYST" = true ]; then
    build_catalyst "x64"
    build_catalyst "arm64"
fi

if [ "$VISIONOS" = true ]; then
    build_visionOS "arm64" "device"
    build_visionOS "arm64" "simulator"
fi

# Step 4 - Manually create XCFramework.
# Unfortunately we cannot use xcodebuild `-xcodebuild -create-xcframework` because of an error:
# "Both ios-arm64-simulator and ios-x86_64-simulator represent two equivalent library definitions."
# Therefore, we craft the XCFramework manually with multi architecture binaries created by lipo.
# We also use plistbuddy to create the plist for the XCFramework

INFO_PLIST="${XCFRAMEWORK_DIR}/Info.plist"
rm -rf "${XCFRAMEWORK_DIR}"
mkdir -p "${XCFRAMEWORK_DIR}"
"$PLISTBUDDY_EXEC" -c "Add :CFBundlePackageType string XFWK"  "${INFO_PLIST}"
"$PLISTBUDDY_EXEC" -c "Add :XCFrameworkFormatVersion string 1.0"  "${INFO_PLIST}"
"$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries array" "${INFO_PLIST}"

# Step 5.1 - Add iOS libs to XCFramework
LIB_COUNT=0
if [[ "$IOS" = true ]]; then

    IOS_LIB_IDENTIFIER="ios-arm64"
    IOS_SIM_LIB_IDENTIFIER="ios-x86_64_arm64-simulator"

    mkdir -p "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}"
    mkdir -p "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}"
    LIB_IOS_INDEX=0
    LIB_IOS_SIMULATOR_INDEX=1
    plist_add_library $LIB_IOS_INDEX $IOS_LIB_IDENTIFIER "ios"
    plist_add_library $LIB_IOS_SIMULATOR_INDEX $IOS_SIM_LIB_IDENTIFIER "ios" "simulator"

    cp -r "${OUTPUT_DIR}/ios-x64-simulator/WebRTC.framework" "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}"
    cp -r "${OUTPUT_DIR}/ios-arm64-device/WebRTC.framework" "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}"
    stage_dsym "${IOS_LIB_IDENTIFIER}" "ios-arm64-device"
    stage_dsym "${IOS_SIM_LIB_IDENTIFIER}" "ios-x64-simulator" "ios-arm64-simulator"

    LIPO_IOS_FLAGS="${OUTPUT_DIR}/ios-arm64-device/WebRTC.framework/WebRTC"
    LIPO_IOS_SIM_FLAGS="${OUTPUT_DIR}/ios-x64-simulator/WebRTC.framework/WebRTC ${OUTPUT_DIR}/ios-arm64-simulator/WebRTC.framework/WebRTC"

    plist_add_architecture $LIB_IOS_INDEX "arm64"
    plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "arm64"
    plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "x86_64"

    lipo -create -output  "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}/WebRTC.framework/WebRTC" ${LIPO_IOS_FLAGS}
    lipo -create -output "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}/WebRTC.framework/WebRTC" ${LIPO_IOS_SIM_FLAGS}

    # codesign simulator framework for local development.
    # This makes it possible for Swift Packages to run Unit Tests and show SwiftUI Previews.
    xcrun codesign -s - "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}/WebRTC.framework/WebRTC"

    LIB_COUNT=$((LIB_COUNT+2))
fi

# Step 5.2 - Add macOS libs to XCFramework
if [ "$MACOS" = true ]; then

    MAC_LIB_IDENTIFIER="macos-x86_64_arm64"

    mkdir "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}"
    plist_add_library $LIB_COUNT "${MAC_LIB_IDENTIFIER}" "macos"
    plist_add_architecture $LIB_COUNT "x86_64"
    plist_add_architecture $LIB_COUNT "arm64"

    cp -RP "${OUTPUT_DIR}/macos-x64/WebRTC.framework" "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}"
    stage_dsym "${MAC_LIB_IDENTIFIER}" "macos-x64" "macos-arm64"

    # The generated macOS framework bundle contains only the umbrella header:
    # since M141 the other public headers are left behind in the intermediate
    # gen/ directory and never staged into the bundle, which makes the
    # framework unusable (https://github.com/stasel/WebRTC/issues/132).
    # Copy them in until this is fixed upstream.
    cp "${OUTPUT_DIR}/macos-x64/gen/sdk/WebRTC.framework/Headers/"*.h "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}/WebRTC.framework/Versions/A/Headers/" || exit 1
    fix_privacy_manifest "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}/WebRTC.framework"

    lipo -create -output "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}/WebRTC.framework/Versions/A/WebRTC" "${OUTPUT_DIR}/macos-x64/WebRTC.framework/WebRTC" "${OUTPUT_DIR}/macos-arm64/WebRTC.framework/WebRTC"
    LIB_COUNT=$((LIB_COUNT+1))
fi

# Step 5.3 - macOS catalyst libs to XCFramework
if [ "$MAC_CATALYST" = true ]; then

    CATALYST_LIB_IDENTIFIER="ios-x86_64_arm64-maccatalyst"

    mkdir "${XCFRAMEWORK_DIR}/${CATALYST_LIB_IDENTIFIER}"
    plist_add_library $LIB_COUNT "${CATALYST_LIB_IDENTIFIER}" "ios" "maccatalyst"
    plist_add_architecture $LIB_COUNT "x86_64"
    plist_add_architecture $LIB_COUNT "arm64"

    cp -RP "${OUTPUT_DIR}/catalyst-x64/WebRTC.framework" "${XCFRAMEWORK_DIR}/${CATALYST_LIB_IDENTIFIER}"
    stage_dsym "${CATALYST_LIB_IDENTIFIER}" "catalyst-x64" "catalyst-arm64"

    fix_privacy_manifest "${XCFRAMEWORK_DIR}/${CATALYST_LIB_IDENTIFIER}/WebRTC.framework"
    lipo -create -output "${XCFRAMEWORK_DIR}/${CATALYST_LIB_IDENTIFIER}/WebRTC.framework/Versions/A/WebRTC" "${OUTPUT_DIR}/catalyst-x64/WebRTC.framework/WebRTC" "${OUTPUT_DIR}/catalyst-arm64/WebRTC.framework/WebRTC"
    LIB_COUNT=$((LIB_COUNT+1))
fi

# Step 5.4 - visionOS libs to XCFramework
if [ "$VISIONOS" = true ]; then

    VISIONOS_LIB_IDENTIFIER="xros-arm64"
    VISIONOS_SIM_LIB_IDENTIFIER="xros-arm64-simulator"

    mkdir "${XCFRAMEWORK_DIR}/${VISIONOS_LIB_IDENTIFIER}"
    mkdir "${XCFRAMEWORK_DIR}/${VISIONOS_SIM_LIB_IDENTIFIER}"
    plist_add_library $LIB_COUNT "${VISIONOS_LIB_IDENTIFIER}" "xros"
    plist_add_architecture $LIB_COUNT "arm64"
    LIB_COUNT=$((LIB_COUNT+1))
    plist_add_library $LIB_COUNT "${VISIONOS_SIM_LIB_IDENTIFIER}" "xros" "simulator"
    plist_add_architecture $LIB_COUNT "arm64"

    cp -RP \
        "${OUTPUT_DIR}/visionos-arm64-device/WebRTC.framework" \
        "${XCFRAMEWORK_DIR}/${VISIONOS_LIB_IDENTIFIER}"
    cp -RP \
        "${OUTPUT_DIR}/visionos-arm64-simulator/WebRTC.framework" \
        "${XCFRAMEWORK_DIR}/${VISIONOS_SIM_LIB_IDENTIFIER}"
    stage_dsym "${VISIONOS_LIB_IDENTIFIER}" "visionos-arm64-device"
    stage_dsym "${VISIONOS_SIM_LIB_IDENTIFIER}" "visionos-arm64-simulator"

    fix_visionos_framework_plist \
        "${XCFRAMEWORK_DIR}/${VISIONOS_LIB_IDENTIFIER}/WebRTC.framework" \
        "XROS" \
        "xros"
    fix_visionos_framework_plist \
        "${XCFRAMEWORK_DIR}/${VISIONOS_SIM_LIB_IDENTIFIER}/WebRTC.framework" \
        "XRSimulator" \
        "xrsimulator"
    xcrun codesign -s - \
        "${XCFRAMEWORK_DIR}/${VISIONOS_SIM_LIB_IDENTIFIER}/WebRTC.framework/WebRTC"

    LIB_COUNT=$((LIB_COUNT+1))
fi

# Step 6 - Add license file to the framework
cp LICENSE ${XCFRAMEWORK_DIR}

# Step 7 - archive the framework
cd "${OUTPUT_DIR}"
NOW=$(date -u +"%Y-%m-%dT%H-%M-%S")
OUTPUT_NAME=WebRTC-$NOW.xcframework.zip
zip --symlinks -rq $OUTPUT_NAME WebRTC.xcframework/

# Step 8 - archive the dSYM files
DSYM_OUTPUT_NAME=WebRTC-$NOW-dSYM.zip
zip -rmq $DSYM_OUTPUT_NAME WebRTC-*.dSYM

# Step 9 - calculate SHA256 checksum
CHECKSUM=$(shasum -a 256 $OUTPUT_NAME | awk '{ print $1 }')
COMMIT_HASH=$(git -C ${ROOT_DIR}/src rev-parse HEAD)

echo "{ \"file\": \"${OUTPUT_NAME}\", \"checksum\": \"${CHECKSUM}\", \"commit\": \"${COMMIT_HASH}\", \"branch\": \"${BRANCH}\", \"dsym\": \"${DSYM_OUTPUT_NAME}\" }" > metadata.json
cat metadata.json
