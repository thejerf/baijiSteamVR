#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ENGINE="${ENGINE:-podman}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/home/steamos/baiju}"
BUILD_DIR="$PWD/state/build-baiji"
STAGE_DIR="$PWD/state/stage-frame"
SDK="$PWD/state/flatpak-home/.local/share/flatpak/runtime/org.kde.Sdk/aarch64/6.10/active/files"
SDK_INCLUDE_OVERLAY="$PWD/state/sdk-overlay/usr/include"
IMAGE="localhost/baijisteamvr-cross:latest"

mkdir -p "$BUILD_DIR" state/ccache-cross-sdk "$STAGE_DIR" dist
if [[ ! -d "$SDK" ]]; then
  echo "Missing AArch64/KDE SDK sysroot: $SDK" >&2
  exit 1
fi

# The KDE SDK stores headers at /include, while its Qt CMake exports expect
# /usr/include. Build a local read-only symlink overlay without modifying the SDK.
mkdir -p "$SDK_INCLUDE_OVERLAY"
for header in "$SDK/include"/*; do
  [[ -e "$header" ]] || continue
  name="${header##*/}"
  ln -sfn "../../include/$name" "$SDK_INCLUDE_OVERLAY/$name"
done
if [[ -d "$SDK/usr/include/libevdev-1.0" ]]; then
  cp -a "$SDK/usr/include/libevdev-1.0" "$SDK_INCLUDE_OVERLAY/"
fi

export CCACHE_DIR="$PWD/state/ccache-cross-sdk"
mkdir -p "$CCACHE_DIR"

EXTRA_FLAGS="-O3 -mcpu=cortex-x4 -I/sysroot/include -DXR_USE_GRAPHICS_API_OPENGL"

if ! "$ENGINE" image exists "$IMAGE"; then
  "$ENGINE" build --platform linux/amd64 -f Containerfile.cross -t "$IMAGE" .
fi

"$ENGINE" run --rm --platform linux/amd64 \
  -v "$PWD:/work/project:ro,Z" \
  -v "$SDK:/sysroot:ro,Z" \
  -v "$SDK/bin:/sysroot/usr/bin:ro,Z" \
  -v "$SDK/lib/libexec:/sysroot/usr/lib/libexec:ro,Z" \
  -v "$SDK/lib/plugins:/sysroot/usr/lib/plugins:ro,Z" \
  -v "$SDK/mkspecs:/sysroot/usr/mkspecs:ro,Z" \
  -v "$SDK_INCLUDE_OVERLAY:/sysroot/usr/include:ro,Z" \
  -v "$BUILD_DIR:/work/build:Z" \
  -v "$PWD/state/ccache-cross-sdk:/run/ccache:Z" \
  -v "$STAGE_DIR:/work/stage:Z" \
  -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static:ro \
  -e CCACHE_DIR=/run/ccache \
  -e LD_LIBRARY_PATH=/sysroot/lib/aarch64-linux-gnu \
  -e INSTALL_PREFIX="$INSTALL_PREFIX" \
  "$IMAGE" \
  bash -c "
    set -euo pipefail
    export PATH=\"/usr/lib/ccache:\$PATH\"
    cmake -S /work/project -B /work/build -G Ninja \
      -DCMAKE_TOOLCHAIN_FILE=/work/project/scripts/cross-toolchain-sdk.cmake \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_C_FLAGS=\"$EXTRA_FLAGS\" \
      -DCMAKE_CXX_FLAGS=\"$EXTRA_FLAGS\" \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DENABLE_LTO=ON \
      -DENABLE_ALSA=OFF \
      -DENABLE_SDL=ON \
      -DENABLE_EVDEV=ON \
      -DENABLE_TESTS=OFF \
      -DENABLE_VR=ON \
      -DENABLE_VULKAN=ON \
      -DENABLE_OPENGL=OFF \
      -DENABLE_ANALYTICS=OFF \
      -DUSE_DISCORD_PRESENCE=OFF \
      -DENABLE_AUTOUPDATE=OFF \
      -DDOLPHIN_DEFAULT_UPDATE_TRACK= \
      -DUSE_SYSTEM_MBEDTLS=OFF \
      -DUSE_SYSTEM_LIBMGBA=OFF \
      -DUSE_SYSTEM_GLSLANG=OFF \
      -DUSE_SYSTEM_CURL=OFF \
      -DDISTRIBUTOR=BaijiSteamVR \
      -Ddatadir=\"$INSTALL_PREFIX/share/baiji\" \
      -DCMAKE_INSTALL_PREFIX=\"$INSTALL_PREFIX\" \
      -DCMAKE_EXE_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu' \
      -DCMAKE_SHARED_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu' \
      -DCMAKE_MODULE_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu'
    cmake --build /work/build --target dolphin-emu dolphin-nogui dolphin-tool -j12
    DESTDIR=/work/stage cmake --install /work/build

    PLUGIN_ROOT=\"/work/stage\$INSTALL_PREFIX/lib/baiji/plugins\"
    for plugin in \
      /sysroot/lib/plugins/platforms/libqxcb.so \
      /sysroot/lib/plugins/xcbglintegrations/libqxcb-egl-integration.so \
      /sysroot/lib/plugins/xcbglintegrations/libqxcb-glx-integration.so \
      /sysroot/lib/plugins/imageformats/libqsvg.so; do
      if [ -f \"\$plugin\" ]; then
        rel=\${plugin#/sysroot/lib/plugins/}
        mkdir -p \"\$PLUGIN_ROOT/\$(dirname \"\$rel\")\"
        cp -a \"\$plugin\" \"\$PLUGIN_ROOT/\$rel\"
      fi
    done
    test -f \"\$PLUGIN_ROOT/platforms/libqxcb.so\"

    DEPLOY_ROOT=\"/work/stage\$INSTALL_PREFIX\"
    DEST=\"\$DEPLOY_ROOT/lib/baiji\" /work/project/scripts/collect-deps.sh \
      \"\$DEPLOY_ROOT/bin/baiji\" \
      \"\$DEPLOY_ROOT/bin/baiji-nogui\" \
      \"\$DEPLOY_ROOT/bin/baiji-tool\" \
      \"\$PLUGIN_ROOT/platforms/libqxcb.so\" \
      \"\$PLUGIN_ROOT/xcbglintegrations/libqxcb-egl-integration.so\" \
      \"\$PLUGIN_ROOT/xcbglintegrations/libqxcb-glx-integration.so\" \
      \"\$PLUGIN_ROOT/imageformats/libqsvg.so\"
  "

echo "Build and staging complete: $STAGE_DIR (install prefix $INSTALL_PREFIX)"
