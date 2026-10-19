#!/bin/sh

set -eu

# Flutter currently uses build/native_assets/ios for both iPhoneOS and
# iPhoneSimulator outputs. A simulator run immediately before an Xcode archive
# can therefore leave an arm64 simulator framework for the archive to reuse.
if [ "${ACTION:-}" != "install" ] || [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

native_assets_dir="${PROJECT_DIR}/../build/native_assets/ios"
objective_c_binary="${native_assets_dir}/objective_c.framework/objective_c"

if [ ! -f "${objective_c_binary}" ]; then
  exit 0
fi

if xcrun vtool -show-build "${objective_c_binary}" 2>/dev/null |
    grep -q "platform IOSSIMULATOR"; then
  echo "Removing stale iOS Simulator native assets before device archive."
  rm -rf "${native_assets_dir}"
fi
