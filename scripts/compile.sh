#!/usr/bin/env bash
# Usage: compile.sh [native|aarch64] [target...]
set -euo pipefail

cd "$(dirname "$0")/.."
ENGINE="${ENGINE:-podman}"
ARCH="${1:-native}"
shift || true

if [[ "$ARCH" == "native" ]]; then
  PLATFORM="linux/amd64"
  BUILD_DIR="state/build-x86_64"
  IMAGE="baijisteamvr-build:amd64"
  ARCH_FLAGS="-O3 -march=x86-64-v3"
elif [[ "$ARCH" == "aarch64" ]]; then
  PLATFORM="linux/arm64"
  BUILD_DIR="state/build-aarch64"
  IMAGE="baijisteamvr-build:arm64"
  ARCH_FLAGS="-O3 -mcpu=cortex-x4"
else
  echo "usage: $0 [native|aarch64] [cmake targets...]" >&2
  exit 1
fi

TARGETS=("$@")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(dolphin-emu)
fi

mkdir -p "$BUILD_DIR" state/ccache

$ENGINE run --rm --platform="$PLATFORM" \
  -v "$PWD:/src:Z" \
  -v "$PWD/$BUILD_DIR:/build:Z" \
  -v "$PWD/state/ccache:/ccache:Z" \
  -e CCACHE_DIR=/ccache \
  "$IMAGE" \
  bash -c "
    export PATH=\"/usr/lib/ccache:\$PATH\"
    cmake -S /src -B /build -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_C_FLAGS='$ARCH_FLAGS' \
      -DCMAKE_CXX_FLAGS='$ARCH_FLAGS' \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DENABLE_VR=ON \
      -DENABLE_VULKAN=ON \
      -DENABLE_LTO=OFF \
      -DUSE_SYSTEM_MBEDTLS=OFF \
      -DUSE_SYSTEM_LIBMGBA=OFF \
      -DENABLE_ALSA=OFF \
      -DENABLE_SDL=ON \
      -DENABLE_EVDEV=ON \
      -DDISTRIBUTOR=BaijiSteamVR \
      -DDOLPHIN_DEFAULT_UPDATE_TRACK= \
      -DENABLE_ANALYTICS=OFF \
      -DUSE_DISCORD_PRESENCE=OFF \
      -DENABLE_AUTOUPDATE=OFF &&
    cmake --build /build --target ${TARGETS[*]} -j\$(nproc)
  "
