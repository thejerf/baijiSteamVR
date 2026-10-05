#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ENGINE="${ENGINE:-podman}"

mkdir -p state/build-cross state/ccache-cross dist

# Build the cross toolchain image if it doesn't exist.
if ! "$ENGINE" image exists localhost/baijisteamvr-cross:latest; then
  echo "==> Building cross toolchain image..."
  "$ENGINE" build --platform linux/amd64 -t localhost/baijisteamvr-cross:latest -f Containerfile.cross .
fi

# Sysroot must have been exported from the arm64 build image first.
if [ ! -d state/cross-sysroot/usr/include ]; then
  echo "ERROR: state/cross-sysroot is missing. Run scripts/export-sysroot.sh first." >&2
  exit 1
fi

# ccache cross prefix to avoid clobbering the emulated aarch64 cache.
export CCACHE_DIR="$PWD/state/ccache-cross"
mkdir -p "$CCACHE_DIR"

"$ENGINE" run --rm --platform linux/amd64 \
  -v "$PWD:/work/project:Z" \
  -v "$PWD/state/cross-sysroot:/sysroot:Z" \
  -v "$PWD/state/build-cross:/work/build:Z" \
  -v "$PWD/state/ccache-cross:/run/ccache:Z" \
  -v "$PWD/scripts/cross-toolchain.cmake:/work/cross-toolchain.cmake:Z" \
  -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static:ro \
  -e CCACHE_DIR=/run/ccache \
  localhost/baijisteamvr-cross:latest \
  bash -c '
    export PATH="/usr/lib/ccache:$PATH"
    cd /work/build
    cmake -G Ninja \
      -DCMAKE_TOOLCHAIN_FILE=/work/cross-toolchain.cmake \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_C_FLAGS="-O3 -mcpu=cortex-x4" \
      -DCMAKE_CXX_FLAGS="-O3 -mcpu=cortex-x4" \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DENABLE_LTO=ON \
      -DENABLE_ALSA=OFF \
      -DENABLE_SDL=ON \
      -DENABLE_EVDEV=ON \
      -DENABLE_VR=ON \
      -DENABLE_VULKAN=ON \
      -DUSE_SYSTEM_MBEDTLS=OFF \
      -DUSE_SYSTEM_LIBMGBA=OFF \
      -DDISTRIBUTOR=BaijiSteamVR \
      -DDOLPHIN_DEFAULT_UPDATE_TRACK= \
      -DENABLE_ANALYTICS=OFF \
      -DUSE_DISCORD_PRESENCE=OFF \
      -DENABLE_AUTOUPDATE=OFF \
      /work/project
    cmake --build . -j12
  '
