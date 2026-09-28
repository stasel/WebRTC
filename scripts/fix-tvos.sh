#!/bin/bash

set -euo pipefail

GN_OUT_PATH=${1:?"usage: fix-tvos.sh <gn-output-directory>"}
echo "Performing fixes to build tvOS..."

while IFS= read -r -d '' ninja; do
    # Some generated Rust ninja files contain arbitrary bytes in their command
    # lines. Force sed's byte-oriented locale so those files don't abort all of
    # the tvOS substitutions with "RE error: illegal byte sequence".
    LC_ALL=C sed -i '' \
        -e 's|iphoneos-version|appletvos-version|g' \
        -e 's|arm64-apple-ios|arm64-apple-tvos|g' \
        -e 's|x86_64-apple-ios|x86_64-apple-tvos|g' \
        -e 's|swift/iphonesimulator|swift/appletvsimulator|g' \
        -e 's|iphoneos|appletvos|g' \
        -e 's|iphonesimulator|appletvsimulator|g' \
        -e 's|iPhoneOS|AppleTVOS|g' \
        -e 's|iPhoneSimulator|AppleTVSimulator|g' \
        -e 's|libclang_rt\.iossim\.a|libclang_rt.tvossim.a|g' \
        -e 's|libclang_rt\.ios\.a|libclang_rt.tvos.a|g' \
        "$ninja"
done < <(find "$GN_OUT_PATH" -type f -name '*.ninja' -print0)
