#!/bin/sh

## WebRTC library build script
## Created by Stasel
## BSD-3 License
## 
## Example usage (from the repository root): BRANCH=branch-heads/7727 MACOS=true IOS=true sh scripts/build.sh

# Configs
DEBUG="${DEBUG:-false}"
BRANCH="${BRANCH:-main}"
IOS="${IOS:-false}"
MACOS="${MACOS:-false}"
MAC_CATALYST="${MAC_CATALYST:-false}"

ROOT_DIR="$(pwd)"
OUTPUT_DIR="${ROOT_DIR}/out"
XCFRAMEWORK_DIR="${OUTPUT_DIR}/WebRTC.xcframework"
COMMON_GN_ARGS="is_debug=${DEBUG} rtc_libvpx_build_vp9=true is_component_build=false rtc_include_tests=false rtc_enable_objc_symbol_export=true enable_stripping=true enable_dsyms=false use_lld=true rtc_ios_use_opengl_rendering=true rtc_system_openh264=true rtc_use_h265=true"
PLISTBUDDY_EXEC="/usr/libexec/PlistBuddy"


die() {
    echo "error: $*" >&2
    exit 1
}

build_iOS() {
    local arch=$1
    local environment=$2
    local gen_dir="${OUTPUT_DIR}/ios-${arch}-${environment}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_os=\"ios\" target_environment=\"${environment}\" ios_deployment_target=\"12.0\" ios_enable_code_signing=false"
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
build_catalyst() {
    local arch=$1
    local gen_dir="${OUTPUT_DIR}/catalyst-${arch}"
    local gen_args="${COMMON_GN_ARGS} target_cpu=\"${arch}\" target_environment=\"catalyst\" target_os=\"ios\" ios_deployment_target=\"14.0\" ios_enable_code_signing=false"
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

# Some generated framework targets have invalid versioned-framework structure,
# contain only the umbrella header, or contain public headers with source-tree
# imports. Repair copied frameworks before adding them to the xcframework so
# every slice is valid and importable on its own.
framework_headers_dir() {
    local framework=$1
    if [ -d "${framework}/Versions/A/Headers" ]; then
        echo "${framework}/Versions/A/Headers"
    else
        echo "${framework}/Headers"
    fi
}

framework_binary_path() {
    local framework=$1
    if [ -f "${framework}/Versions/A/WebRTC" ]; then
        echo "${framework}/Versions/A/WebRTC"
    else
        echo "${framework}/WebRTC"
    fi
}

repair_framework_layout() {
    local framework=$1
    local version_dir="${framework}/Versions/A"
    local nested_versions_dir="${version_dir}/Versions"
    local nested_privacy_info="${nested_versions_dir}/A/Resources/PrivacyInfo.xcprivacy"
    local resources_dir="${version_dir}/Resources"

    if [ ! -d "${version_dir}" ]; then
        return 0
    fi

    if [ -f "${nested_privacy_info}" ]; then
        mkdir -p "${resources_dir}"
        mv -f "${nested_privacy_info}" "${resources_dir}/PrivacyInfo.xcprivacy"
    fi

    if [ -d "${nested_versions_dir}" ]; then
        rm -rf "${nested_versions_dir}"
    fi
}

validate_framework_layout() {
    local framework=$1
    local version_dir="${framework}/Versions/A"
    local unexpected_paths

    if [ ! -d "${version_dir}" ]; then
        return 0
    fi

    unexpected_paths=$(find "${version_dir}" -mindepth 1 -maxdepth 1 ! \( -name Headers -o -name Modules -o -name Resources -o -name WebRTC \) -print)
    [ -z "${unexpected_paths}" ] || die "${framework} contains unexpected files in Versions/A:
${unexpected_paths}"

    [ -L "${framework}/Headers" ] || die "${framework} is missing top-level Headers symlink"
    [ -L "${framework}/Modules" ] || die "${framework} is missing top-level Modules symlink"
    [ -L "${framework}/Resources" ] || die "${framework} is missing top-level Resources symlink"
    [ -L "${framework}/WebRTC" ] || die "${framework} is missing top-level WebRTC symlink"
    [ -L "${framework}/Versions/Current" ] || die "${framework} is missing Versions/Current symlink"
}

first_complete_headers_dir() {
    local framework
    local headers_dir
    local rtc_header_count
    for framework in \
        "${OUTPUT_DIR}/ios-arm64-device/WebRTC.framework" \
        "${OUTPUT_DIR}/ios-x64-simulator/WebRTC.framework" \
        "${OUTPUT_DIR}/ios-arm64-simulator/WebRTC.framework" \
        "${OUTPUT_DIR}/catalyst-x64/WebRTC.framework" \
        "${OUTPUT_DIR}/catalyst-arm64/WebRTC.framework" \
        "${OUTPUT_DIR}/macos-x64/WebRTC.framework" \
        "${OUTPUT_DIR}/macos-arm64/WebRTC.framework"; do
        if [ -d "${framework}" ]; then
            headers_dir=$(framework_headers_dir "${framework}")
            if [ -f "${headers_dir}/WebRTC.h" ]; then
                rtc_header_count=$(find "${headers_dir}" -maxdepth 1 -name 'RTC*.h' | wc -l | tr -d ' ')
                if [ "${rtc_header_count}" -gt 0 ]; then
                    echo "${headers_dir}"
                    return 0
                fi
            fi
        fi
    done
    return 1
}

normalize_framework_header_imports() {
    local headers_dir=$1

    find "${headers_dir}" -maxdepth 1 -name '*.h' -exec perl -0pi -e '
        s/#(import|include)(\s+)["<]sdk\/objc\/(?:[^">\/]+\/)*([^">\/]+\.h)[">]/#$1$2<WebRTC\/$3>/g;
        s/#(import|include)(\s+)"(RTC[^"\/]+\.h)"/#$1$2<WebRTC\/$3>/g;
    ' {} \;
}

copy_missing_imported_headers() {
    local headers_dir=$1
    local canonical_headers_dir=$2
    local copied_header
    local imported_header
    local imported_headers
    local source_header

    while true; do
        copied_header=false
        imported_headers=$(grep -hE '^[[:space:]]*#(import|include)[[:space:]]+[<"]WebRTC/RTC[^>"]+\.h[>"]' "${headers_dir}"/*.h | sed -E 's#.*WebRTC/([^>"]+\.h).*#\1#' | sort -u)
        for imported_header in ${imported_headers}; do
            if [ ! -f "${headers_dir}/${imported_header}" ]; then
                source_header=""
                if [ -n "${canonical_headers_dir}" ] && [ -f "${canonical_headers_dir}/${imported_header}" ]; then
                    source_header="${canonical_headers_dir}/${imported_header}"
                elif [ -d "sdk/objc" ]; then
                    source_header=$(find sdk/objc \
                        -type f \
                        -name "${imported_header}" \
                        ! -path '*/test/*' \
                        ! -path '*/tests/*' \
                        ! -path '*/unittest/*' \
                        ! -path '*/unittests/*' | head -n 1)
                fi
                if [ -n "${source_header}" ]; then
                    cp "${source_header}" "${headers_dir}"
                    copied_header=true
                fi
            fi
        done

        if [ "${copied_header}" = true ]; then
            normalize_framework_header_imports "${headers_dir}"
        else
            break
        fi
    done
}

validate_framework_headers() {
    local framework=$1
    local headers_dir
    local rtc_header_count
    local imported_header
    local imported_headers
    local stale_imports
    local missing_headers=""

    headers_dir=$(framework_headers_dir "${framework}")
    [ -f "${headers_dir}/WebRTC.h" ] || die "${framework} is missing WebRTC.h"

    rtc_header_count=$(find "${headers_dir}" -maxdepth 1 -name 'RTC*.h' | wc -l | tr -d ' ')
    [ "${rtc_header_count}" -gt 0 ] || die "${framework} has no packaged RTC*.h public headers"

    stale_imports=$(grep -R -nE '["<]sdk/objc/' "${headers_dir}" || true)
    [ -z "${stale_imports}" ] || die "${framework} contains stale sdk/objc header imports:
${stale_imports}"

    imported_headers=$(grep -hE '^[[:space:]]*#(import|include)[[:space:]]+[<"]WebRTC/RTC[^>"]+\.h[>"]' "${headers_dir}"/*.h | sed -E 's#.*WebRTC/([^>"]+\.h).*#\1#' | sort -u)
    for imported_header in ${imported_headers}; do
        if [ ! -f "${headers_dir}/${imported_header}" ]; then
            missing_headers="${missing_headers} ${imported_header}"
        fi
    done

    [ -z "${missing_headers}" ] || die "${framework} is missing imported public headers:${missing_headers}"
}

repair_framework_headers() {
    local framework=$1
    local canonical_headers_dir=$2
    local headers_dir

    repair_framework_layout "${framework}"

    headers_dir=$(framework_headers_dir "${framework}")
    mkdir -p "${headers_dir}"

    if [ ! -f "${headers_dir}/WebRTC.h" ] && [ -n "${canonical_headers_dir}" ] && [ -f "${canonical_headers_dir}/WebRTC.h" ]; then
        cp "${canonical_headers_dir}/WebRTC.h" "${headers_dir}"
    fi
    normalize_framework_header_imports "${headers_dir}"
    copy_missing_imported_headers "${headers_dir}" "${canonical_headers_dir}"
    validate_framework_layout "${framework}"
    validate_framework_headers "${framework}"
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

# Step 2 - Download and build WebRTC
if [ ! -d src ]; then
    fetch --nohooks webrtc_ios
fi
cd src
git fetch --all
git checkout $BRANCH
cd ..
gclient sync --with_branch_heads --with_tags
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
CANONICAL_HEADERS_DIR=$(first_complete_headers_dir || true)
if [ -z "${CANONICAL_HEADERS_DIR}" ]; then
    echo "warning: no complete generated framework headers found; falling back to sdk/objc headers"
fi

if [ "$IOS" = true ]; then

    IOS_LIB_IDENTIFIER="ios-arm64"
    IOS_SIM_LIB_IDENTIFIER="ios-x86_64_arm64-simulator"

    mkdir "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}"
    mkdir "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}"
    LIB_IOS_INDEX=0
    LIB_IOS_SIMULATOR_INDEX=1
    plist_add_library $LIB_IOS_INDEX $IOS_LIB_IDENTIFIER "ios"
    plist_add_library $LIB_IOS_SIMULATOR_INDEX $IOS_SIM_LIB_IDENTIFIER "ios" "simulator"

    cp -r "${OUTPUT_DIR}/ios-arm64-device/WebRTC.framework" "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}"
    cp -r "${OUTPUT_DIR}/ios-x64-simulator/WebRTC.framework" "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}"
    repair_framework_headers "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}/WebRTC.framework" "${CANONICAL_HEADERS_DIR}"
    repair_framework_headers "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}/WebRTC.framework" "${CANONICAL_HEADERS_DIR}"

    LIPO_IOS_FLAGS=$(framework_binary_path "${OUTPUT_DIR}/ios-arm64-device/WebRTC.framework")
    LIPO_IOS_SIM_X64=$(framework_binary_path "${OUTPUT_DIR}/ios-x64-simulator/WebRTC.framework")
    LIPO_IOS_SIM_ARM64=$(framework_binary_path "${OUTPUT_DIR}/ios-arm64-simulator/WebRTC.framework")
    LIPO_IOS_OUTPUT=$(framework_binary_path "${XCFRAMEWORK_DIR}/${IOS_LIB_IDENTIFIER}/WebRTC.framework")
    LIPO_IOS_SIM_OUTPUT=$(framework_binary_path "${XCFRAMEWORK_DIR}/${IOS_SIM_LIB_IDENTIFIER}/WebRTC.framework")

    plist_add_architecture $LIB_IOS_INDEX "arm64"
    plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "arm64"
    plist_add_architecture $LIB_IOS_SIMULATOR_INDEX "x86_64"

    lipo -create -output  "${LIPO_IOS_OUTPUT}" "${LIPO_IOS_FLAGS}"
    lipo -create -output "${LIPO_IOS_SIM_OUTPUT}" "${LIPO_IOS_SIM_X64}" "${LIPO_IOS_SIM_ARM64}"

    # codesign simulator framework for local development.
    # This makes it possible for Swift Packages to run Unit Tests and show SwiftUI Previews.
    xcrun codesign -s - "${LIPO_IOS_SIM_OUTPUT}"

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
    repair_framework_headers "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}/WebRTC.framework" "${CANONICAL_HEADERS_DIR}"
    lipo -create -output "$(framework_binary_path "${XCFRAMEWORK_DIR}/${MAC_LIB_IDENTIFIER}/WebRTC.framework")" "$(framework_binary_path "${OUTPUT_DIR}/macos-x64/WebRTC.framework")" "$(framework_binary_path "${OUTPUT_DIR}/macos-arm64/WebRTC.framework")"
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
    repair_framework_headers "${XCFRAMEWORK_DIR}/${CATALYST_LIB_IDENTIFIER}/WebRTC.framework" "${CANONICAL_HEADERS_DIR}"
    lipo -create -output "$(framework_binary_path "${XCFRAMEWORK_DIR}/${CATALYST_LIB_IDENTIFIER}/WebRTC.framework")" "$(framework_binary_path "${OUTPUT_DIR}/catalyst-x64/WebRTC.framework")" "$(framework_binary_path "${OUTPUT_DIR}/catalyst-arm64/WebRTC.framework")"
    LIB_COUNT=$((LIB_COUNT+1))
fi

# Step 6 - Add license file to the framework
cp LICENSE ${XCFRAMEWORK_DIR}

# Step 7 - archive the framework
cd "${OUTPUT_DIR}"
NOW=$(date -u +"%Y-%m-%dT%H-%M-%S")
OUTPUT_NAME=WebRTC-$NOW.xcframework.zip
zip --symlinks -r $OUTPUT_NAME WebRTC.xcframework/

# Step 8 calculate SHA256 checksum
CHECKSUM=$(shasum -a 256 $OUTPUT_NAME | awk '{ print $1 }')
COMMIT_HASH=$(git rev-parse HEAD)

echo "{ \"file\": \"${OUTPUT_NAME}\", \"checksum\": \"${CHECKSUM}\", \"commit\": \"${COMMIT_HASH}\", \"branch\": \"${BRANCH}\" }" > metadata.json
cat metadata.json
