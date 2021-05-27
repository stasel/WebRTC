#!/bin/sh

## WebRTC library build script
## Created by Stasel
## BSD-3 License
## 
## Example usage: IOS_32_BIT=true IOS_64_BIT=true BUILD_VP9=true sh build.sh

# Configs
DEBUG="${DEBUG:-false}"
BITCODE="${BITCODE:-false}" 
BUILD_VP9="${BUILD_VP9:-false}"
BRANCH="${BRANCH:-master}"
IOS_32_BIT="${IOS_32_BIT:-false}"
IOS_64_BIT="${IOS_64_BIT:-false}"
MACOS="${MACOS:-false}"
MAC_CATALYST="${MAC_CATALYST:-false}"

OUTPUT_DIR="./out"
XCFRAMEWORK_DIR="out/WebRTC.xcframework"
COMMON_GN_ARGS="is_debug=${DEBUG} rtc_libvpx_build_vp9=${BUILD_VP9} is_component_build=false rtc_include_tests=false rtc_enable_symbol_export=true"
PLISTBUDDY_EXEC="/usr/libexec/PlistBuddy"

build_iOS() {
    local arch=$1
    local environment=$2
    local gen_dir="${OUTPUT_DIR}/ios-${arch}-${environment}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" enable_ios_bitcode=${BITCODE} target_os=\"ios\" target_environment=\"${environment}\" ios_deployment_target=\"10.0\" ios_enable_code_signing=false use_xcode_clang=true"
    gn gen "${gen_dir}" --args="${gen_args}"
    ninja -C "${gen_dir}" framework_objc
}

build_macOS() {
    local arch=$1
    local gen_dir="${OUTPUT_DIR}/macos-${arch}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_os=\"mac\""
    gn gen "${gen_dir}" --args="${gen_args}"
    ninja -C "${gen_dir}" mac_framework_objc
}

# Catalyst builds are not working properly yet. 
# See: https://groups.google.com/g/discuss-webrtc/c/VZXS4V4mSY4
build_catalyst() {
    local arch=$1
    local gen_dir="${OUTPUT_DIR}/catalyst-${arch}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_environment=\"catalyst\" target_os=\"ios\" ios_deployment_target=\"13.0\" ios_enable_code_signing=false use_xcode_clang=true treat_warnings_as_errors=false"
    gn gen "${gen_dir}" --args="${gen_args}"
    ninja -C "${gen_dir}" framework_objc
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

# Step 1: Download and install depot tools
if [ ! -d depot_tools ]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
    cd depot_tools
    git pull origin master
    cd ..
fi
export PATH=$(pwd)/depot_tools:$PATH

# Step 2 - Download and build WebRTC
if [ ! -d src ]; then
	fetch --nohooks webrtc_ios
fi
cd src
git checkout $BRANCH
cd ..
gclient sync --with_branch_heads --with_tags
cd src


# Step 3 - Compile and build all frameworks
rm -rf $OUTPUT_DIR
if [ "$IOS_32_BIT" = true ]; then
    build_iOS "x86" "simulator"
    build_iOS "arm" "device"
fi

if [ "$IOS_64_BIT" = true ]; then
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

# Step 4 - Manually create XCFramework.
# Unfortunately we cannot use xcodebuild `-xcodebuild -create-xcframework` because of an error:
# "Both ios-arm64-simulator and ios-x86_64-simulator represent two equivalent library definitions."
# Therefore, we craft the XCFramework manually with multi architecture binaries created by lipo.
# We also use plistbuddy to create the plist for the XCFramework

INFO_PLIST="${XCFRAMEWORK_DIR}/Info.plist"
rm -rf "${XCFRAMEWORK_DIR}"
mkdir "${XCFRAMEWORK_DIR}"
"$PLISTBUDDY_EXEC" -c "Add :CFBundlePackageType string XFWK"  "${INFO_PLIST}"
"$PLISTBUDDY_EXEC" -c "Add :XCFrameworkFormatVersion string 1.0"  "${INFO_PLIST}"
"$PLISTBUDDY_EXEC" -c "Add :AvailableLibraries array" "${INFO_PLIST}"

# Step 5.1 - Add iOS libs to XCFramework
LIB_COUNT=0
if [[ "$IOS_32_BIT" = true || "$IOS_64_BIT" = true ]]; then
    mkdir "${XCFRAMEWORK_DIR}/ios"
    mkdir "${XCFRAMEWORK_DIR}/ios-simulator"
    LIB_IOS_INDEX=0
    LIB_IOS_SIMULATOR_INDEX=1
    plist_add_library $LIB_IOS_INDEX "ios" "ios"
    plist_add_library $LIB_IOS_SIMULATOR_INDEX "ios-simulator" "ios" "simulator"

    if [ "$IOS_32_BIT" = true ]; then
        cp -r out/ios-arm-device/WebRTC.framework "${XCFRAMEWORK_DIR}/ios"
        cp -r out/ios-x86-simulator/WebRTC.framework "${XCFRAMEWORK_DIR}/ios-simulator"
    elif [ "$IOS_64_BIT" = true ]; then
        cp -r out/ios-arm64-device/WebRTC.framework "${XCFRAMEWORK_DIR}/ios"
        cp -r out/ios-x64-simulator/WebRTC.framework "${XCFRAMEWORK_DIR}/ios-simulator"
    fi

    LIPO_IOS_FLAGS=""
    LIPO_IOS_SIM_FLAGS=""
    if [ "$IOS_32_BIT" = true ]; then
        LIPO_IOS_FLAGS="out/ios-arm-device/WebRTC.framework/WebRTC"
        LIPO_IOS_SIM_FLAGS="out/ios-x86-simulator/WebRTC.framework/WebRTC"
        plist_add_architecture $LIB_IOS_INDEX "armv7"
        plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "i386"
    fi

    if [ "$IOS_64_BIT" = true ]; then
        LIPO_IOS_FLAGS="${LIPO_IOS_FLAGS} out/ios-arm64-device/WebRTC.framework/WebRTC"
        LIPO_IOS_SIM_FLAGS="${LIPO_IOS_SIM_FLAGS} out/ios-x64-simulator/WebRTC.framework/WebRTC out/ios-arm64-simulator/WebRTC.framework/WebRTC"
        plist_add_architecture $LIB_IOS_INDEX "arm64"
        plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "arm64"
        plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "x86_64"
    fi

    lipo -create -output  "${XCFRAMEWORK_DIR}/ios/WebRTC.framework/WebRTC" ${LIPO_IOS_FLAGS}
    lipo -create -output "${XCFRAMEWORK_DIR}/ios-simulator/WebRTC.framework/WebRTC" ${LIPO_IOS_SIM_FLAGS}

    LIB_COUNT=$((LIB_COUNT+2))
fi

# Step 5.2 - Add macOS libs to XCFramework
if [ "$MACOS" = true ]; then
    mkdir "${XCFRAMEWORK_DIR}/macos"
    plist_add_library $LIB_COUNT "macos" "macos"
    plist_add_architecture $LIB_COUNT "x86_64"
    plist_add_architecture $LIB_COUNT "arm64"

    cp -RP out/macos-x64/WebRTC.framework "${XCFRAMEWORK_DIR}/macos"
    lipo -create -output "${XCFRAMEWORK_DIR}/macos/WebRTC.framework/Versions/A/WebRTC" out/macos-x64/WebRTC.framework/WebRTC out/macos-arm64/WebRTC.framework/WebRTC
    LIB_COUNT=$((LIB_COUNT+1))
fi

# Step 5.3 - macOS catalyst libs to XCFramework
if [ "$MAC_CATALYST" = true ]; then
    mkdir "${XCFRAMEWORK_DIR}/macos-catalyst"
    plist_add_library $LIB_COUNT "macos-catalyst" "ios" "maccatalyst"
    plist_add_architecture $LIB_COUNT "x86_64"
    plist_add_architecture $LIB_COUNT "arm64"
    cp -r out/catalyst-x64/WebRTC.framework "${XCFRAMEWORK_DIR}/macos-catalyst"
    lipo -create -output "${XCFRAMEWORK_DIR}/macos-catalyst/WebRTC.framework/WebRTC" out/catalyst-x64/WebRTC.framework/WebRTC out/catalyst-arm64/WebRTC.framework/WebRTC
    LIB_COUNT=$((LIB_COUNT+1))
fi

# Step 6 - archive the framework
cd out
NOW=$(date -u +"%Y-%m-%dT%H-%M-%S")
OUTPUT_NAME=WebRTC-$NOW.xcframework.zip
zip -r $OUTPUT_NAME WebRTC.xcframework/

# Step 7 calculate SHA256 checksum
CHECKSUM=$(shasum -a 256 $OUTPUT_NAME | awk '{ print $1 }')
COMMIT_HASH=$(git rev-parse HEAD)

echo "{ \"file\": \"${OUTPUT_NAME}\", \"checksum\": \"${CHECKSUM}\", \"commit\": \"${COMMIT_HASH}\", \"branch\": \"${BRANCH}\" }" > metadata.json
cat metadata.json

