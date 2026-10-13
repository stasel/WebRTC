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

apply_visionos_build_config_patches() {
    [ "$VISIONOS" = true ] || return 0

    for patch_file in "${ROOT_DIR}"/scripts/patches/visionos/*.patch; do
        [ -f "${patch_file}" ] || continue
        git -C "${ROOT_DIR}/src" apply --whitespace=nowarn "${patch_file}" || exit 1
    done
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
apply_visionos_build_config_patches || exit 1

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
