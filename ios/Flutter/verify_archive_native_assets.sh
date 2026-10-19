#!/bin/sh

set -eu

if [ "${ACTION:-}" != "install" ] || [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

framework_name="objective_c"
framework_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/${framework_name}.framework"
framework_binary="${framework_dir}/${framework_name}"

if [ ! -f "${framework_binary}" ]; then
  exit 0
fi

build_platform="$(
  xcrun vtool -show-build "${framework_binary}" 2>/dev/null |
    awk '/platform / { print $2; exit }'
)"

if [ "${build_platform}" != "IOS" ]; then
  echo "error: ${framework_name}.framework targets ${build_platform:-an unknown platform}; expected IOS."
  echo "error: Run flutter clean, then archive again for Any iOS Device."
  exit 1
fi

# Native-assets frameworks are produced outside Xcode's normal framework
# targets, so Xcode does not create their dSYMs automatically.
dsym_path="${DWARF_DSYM_FOLDER_PATH}/${framework_name}.framework.dSYM"
rm -rf "${dsym_path}"
xcrun dsymutil "${framework_binary}" -o "${dsym_path}"

binary_uuid="$(dwarfdump --uuid "${framework_binary}" | awk '{ print $2; exit }')"
dsym_binary="${dsym_path}/Contents/Resources/DWARF/${framework_name}"
dsym_uuid="$(dwarfdump --uuid "${dsym_binary}" | awk '{ print $2; exit }')"

if [ -z "${binary_uuid}" ] || [ "${binary_uuid}" != "${dsym_uuid}" ]; then
  echo "error: ${framework_name}.framework dSYM UUID does not match its binary."
  exit 1
fi

echo "Validated ${framework_name}.framework for iOS and generated dSYM ${binary_uuid}."
