#! /bin/sh

# Script modified from https://github.com/jedisct1/libsodium/blob/stable/dist-build/apple-xcframework.sh
# Original Author of Script:- https://github.com/jedisct1/libsodium/

# ENV/Variables
export PREFIX="$(pwd)/libsodium-apple"
export MACOS_ARM64_PREFIX="${PREFIX}/tmp/macos-arm64"
export MACOS_ARM64E_PREFIX="${PREFIX}/tmp/macos-arm64e"
export MACOS_X86_64_PREFIX="${PREFIX}/tmp/macos-x86_64"
export LOG_FILE="${PREFIX}/tmp/build_log"
export XCODEDIR="$(xcode-select -p)"

export MACOS_VERSION_MIN=${MACOS_VERSION_MIN-"10.10"}

echo
echo "Warnings related to headers being present but not usable are due to functions"
echo "that didn't exist in the specified minimum iOS version level."
echo "They can be safely ignored."
echo
echo "Define the LIBSODIUM_MINIMAL_BUILD environment variable to build a"
echo "library without deprecated/undocumented/low-level functions."
echo
echo

if [ "$LIBSODIUM_MINIMAL_BUILD" ]; then
  export LIBSODIUM_ENABLE_MINIMAL_FLAG="--enable-minimal"
else
  export LIBSODIUM_ENABLE_MINIMAL_FLAG=""
fi

build_macos() {
  export BASEDIR="${XCODEDIR}/Platforms/MacOSX.platform/Developer"
  export PATH="${BASEDIR}/usr/bin:$BASEDIR/usr/sbin:$PATH"

  ## macOS arm64
  export CFLAGS="-O3 -arch arm64 -mmacosx-version-min=${MACOS_VERSION_MIN}"
  export LDFLAGS="-arch arm64 -mmacosx-version-min=${MACOS_VERSION_MIN}"

  make distclean >/dev/null 2>&1
  ./configure --host=aarch64-apple-darwin23 --prefix="$MACOS_ARM64_PREFIX" \
    ${LIBSODIUM_ENABLE_MINIMAL_FLAG} || exit 1
  make -j${PROCESSORS} install || exit 1

  ## macOS arm64e
  export CFLAGS="-O3 -arch arm64e -mmacosx-version-min=${MACOS_VERSION_MIN}"
  export LDFLAGS="-arch arm64e -mmacosx-version-min=${MACOS_VERSION_MIN}"

  make distclean >/dev/null 2>&1
  ./configure --host=aarch64-apple-darwin23 --prefix="$MACOS_ARM64E_PREFIX" \
    ${LIBSODIUM_ENABLE_MINIMAL_FLAG} || exit 1
  make -j${PROCESSORS} install || exit 1

  ## macOS x86_64
  export CFLAGS="-O3 -arch x86_64 -mmacosx-version-min=${MACOS_VERSION_MIN}"
  export LDFLAGS="-arch x86_64 -mmacosx-version-min=${MACOS_VERSION_MIN}"

  make distclean >/dev/null 2>&1
  ./configure --host=x86_64-apple-darwin23 --prefix="$MACOS_X86_64_PREFIX" \
    ${LIBSODIUM_ENABLE_MINIMAL_FLAG} || exit 1
  make -j${PROCESSORS} install || exit 1
}

mkdir -p "${PREFIX}/tmp"

echo "Building for macOS..."
build_macos >"$LOG_FILE" 2>&1 || exit 1

echo "listing files after building for macOS..."

echo "x86_64 listed files:"

ls -l "${MACOS_X86_64_PREFIX}/lib/"

echo "arm64 listed files:"

ls -l "${MACOS_ARM64_PREFIX}/lib/"

echo "arm64e listed files:"

ls -l "${MACOS_ARM64E_PREFIX}/lib/"

echo "listed all files ✅, moving on...."

echo "Bundling macOS targets..."

mkdir -p "${PREFIX}/macos/lib"
cp -a "${MACOS_X86_64_PREFIX}/include" "${PREFIX}/macos/"
echo "copying specific Arch binaries just incase"
# lipo creates a universal binary for MacOS
for ext in a dylib; do
  echo "extension: ${ext}"
  cp -P "${MACOS_ARM64_PREFIX}/lib/libsodium.${ext}" "${PREFIX}/macos/lib/libsodium_ARM64.${ext}"
  cp -P "${MACOS_X86_64_PREFIX}/lib/libsodium.${ext}" "${PREFIX}/macos/lib/libsodium_X86_64.${ext}"
  cp -P "${MACOS_ARM64E_PREFIX}/lib/libsodium.${ext}" "${PREFIX}/macos/lib/libsodium_ARM64E.${ext}"
  lipo -create \
    "${MACOS_ARM64_PREFIX}/lib/libsodium.${ext}" \
    "${MACOS_ARM64E_PREFIX}/lib/libsodium.${ext}" \
    "${MACOS_X86_64_PREFIX}/lib/libsodium.${ext}" \
    -output "${PREFIX}/macos/lib/libsodium_universal.${ext}"
done

echo "Done!"

# cp -a "${MACOS_ARM64_PREFIX}/lib/libsodium.dylib" "${PREFIX}/macos/lib/libsodium_ARM64.dylib"
# cp -a "${MACOS_ARM64E_PREFIX}/lib/libsodium.dylib" "${PREFIX}/macos/lib/libsodium_ARM64E.dylib"
# cp -a "${MACOS_X86_64_PREFIX}/lib/libsodium.dylib" "${PREFIX}/macos/lib/libsodium_X86_64.dylib"

echo "copyed specific Arch files to ${PREFIX}/macos/lib directory"

echo "copying logs to macos directory"

cp -a "${LOG_FILE}" "${PREFIX}/macos/"
cp -a "${PREFIX}/tmp/debug_log" "${PREFIX}/macos/"

echo "Listing Final Built Files"

ls -l "${PREFIX}/macos/lib/"

echo "Cleaning up..."

# Cleanup
rm -rf -- "$PREFIX/tmp"
make distclean >/dev/null

echo "Cleanup Done! Built files are in ${PREFIX}/macos/lib. \n logs are in ${PREFIX}/macos/"