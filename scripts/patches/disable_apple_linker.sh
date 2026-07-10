#!/bin/bash

## Patch: keep the Chromium toolchain on LLVM's archiver/linker.
##
## M150 pins src/build to a revision where Chromium briefly defaulted macOS
## arm64 builds to Apple's linker and Apple's libtool for static archives
## (crbug.com/502338406). We still link with LLVM's ld64.lld (use_lld=true),
## which cannot read archives created by the rewritten libtool shipped with
## Xcode 26.5+ ("cctools_ld"): the build fails with "couldn't process child:
## __.SYMDEF has unhandled file type" and then the linker crashes. Appending
## "&& false" to the use_apple_linker formula keeps the toolchain using
## llvm-ar for static archives, matching the linker we use (same behavior as
## M149 and earlier). This assignment lives inside toolchain_args, which
## ignores gn args, so it has to be patched in the source.
##
## Upstream made the Apple linker opt-in again on 2026-06-03 (chromium build
## commit a461b6f9832d) and later removed use_apple_linker entirely, so this
## patch is a no-op once a milestone pins a newer src/build revision and can
## be deleted then.
##
## Usage: disable_apple_linker.sh <path-to-src/build/toolchain/apple/toolchain.gni>

set -e

APPLE_TOOLCHAIN_GNI="$1"

if [ -z "$APPLE_TOOLCHAIN_GNI" ]; then
    echo "error: usage: $0 <path-to-toolchain.gni>" >&2
    exit 1
fi

if [ ! -f "$APPLE_TOOLCHAIN_GNI" ]; then
    echo "error: toolchain file not found: ${APPLE_TOOLCHAIN_GNI}" >&2
    exit 1
fi

sed -i '' 's/!(use_remoteexec && use_system_xcode)$/!(use_remoteexec \&\& use_system_xcode) \&\& false/' "$APPLE_TOOLCHAIN_GNI"

# Guard: if the unpatched formula is still present but our patched form is
# absent, the sed pattern failed to apply (the formula likely changed
# upstream). A newer revision that dropped use_apple_linker leaves neither
# marker, so this correctly no-ops there.
if grep -q 'use_apple_linker =$' "$APPLE_TOOLCHAIN_GNI" && ! grep -q 'use_system_xcode) && false' "$APPLE_TOOLCHAIN_GNI"; then
    echo "error: failed to patch use_apple_linker in ${APPLE_TOOLCHAIN_GNI}, the formula has likely changed upstream" >&2
    exit 1
fi
