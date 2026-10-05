#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ENGINE=podman
INSTALL_PREFIX="${INSTALL_PREFIX:-/home/steamos/baiji}"
BUILD_DIR="$PWD/state/build-baiji"
STAGE_DIR="$PWD/state/stage-frame"
SDK="$PWD/state/flatpak-home/.local/share/flatpak/runtime/org.kde.Sdk/aarch64/6.10/active/files"
SDK_OVERLAY="$PWD/state/sdk-overlay"
SDK_INCLUDE_OVERLAY="$SDK_OVERLAY/usr/include"
IMAGE="localhost/baijisteamvr-cross:latest"
IMAGE_STAMP="$PWD/state/cross-sdk-image-$ENGINE.sha256"
IMAGE_CONFIGURATION_HASH="$(sha256sum Containerfile.cross | cut -d ' ' -f 1)"

mkdir -p "$BUILD_DIR" state/ccache-cross-sdk "$STAGE_DIR" dist
if [[ ! -d "$SDK" ]]; then
  echo "Missing AArch64/KDE SDK sysroot: $SDK" >&2
  exit 1
fi

# Build one complete sysroot view instead of mounting child directories under the read-only SDK
# mount. Podman/runc cannot reliably create those nested mountpoints in a read-only parent mount.
mkdir -p "$SDK_INCLUDE_OVERLAY" "$SDK_OVERLAY/usr/lib"
for entry in "$SDK"/*; do
  [[ -e "$entry" ]] || continue
  name="${entry##*/}"
  [[ "$name" == usr ]] && continue
  ln -sfn "/sdk/$name" "$SDK_OVERLAY/$name"
done

for header in "$SDK/include"/*; do
  [[ -e "$header" ]] || continue
  name="${header##*/}"
  ln -sfn "../../include/$name" "$SDK_INCLUDE_OVERLAY/$name"
done
if [[ -d "$SDK/usr/include/libevdev-1.0" ]]; then
  cp -a "$SDK/usr/include/libevdev-1.0" "$SDK_INCLUDE_OVERLAY/"
fi

for entry in "$SDK/usr"/*; do
  [[ -e "$entry" ]] || continue
  name="${entry##*/}"
  case "$name" in
    bin|include|lib|mkspecs) continue ;;
  esac
  ln -sfn "/sdk/usr/$name" "$SDK_OVERLAY/usr/$name"
done
for entry in "$SDK/usr/lib"/*; do
  [[ -e "$entry" ]] || continue
  name="${entry##*/}"
  case "$name" in
    libexec|plugins) continue ;;
  esac
  ln -sfn "/sdk/usr/lib/$name" "$SDK_OVERLAY/usr/lib/$name"
done
ln -sfn /sdk/bin "$SDK_OVERLAY/usr/bin"
ln -sfn /sdk/mkspecs "$SDK_OVERLAY/usr/mkspecs"
ln -sfn /sdk/lib/libexec "$SDK_OVERLAY/usr/lib/libexec"
ln -sfn /sdk/lib/plugins "$SDK_OVERLAY/usr/lib/plugins"

export CCACHE_DIR="$PWD/state/ccache-cross-sdk"
mkdir -p "$CCACHE_DIR"

EXTRA_FLAGS="-O3 -mcpu=cortex-x4 -I/sysroot/include -DXR_USE_GRAPHICS_API_OPENGL"

if ! "$ENGINE" image exists "$IMAGE" || [[ ! -f "$IMAGE_STAMP" ]] ||
   [[ "$(<"$IMAGE_STAMP")" != "$IMAGE_CONFIGURATION_HASH" ]]; then
  "$ENGINE" build --platform linux/amd64 -f Containerfile.cross -t "$IMAGE" .
  printf '%s\n' "$IMAGE_CONFIGURATION_HASH" > "$IMAGE_STAMP"
fi

"$ENGINE" run --rm --platform linux/amd64 \
  -v "$PWD:/work/project:ro,Z" \
  -v "$SDK:/sdk:ro,Z" \
  -v "$SDK_OVERLAY:/sysroot:ro,Z" \
  -v "$BUILD_DIR:/work/build:Z" \
  -v "$PWD/state/ccache-cross-sdk:/run/ccache:Z" \
  -v "$STAGE_DIR:/work/stage:Z" \
  -e CCACHE_DIR=/run/ccache \
  -e LD_LIBRARY_PATH=/sysroot/lib/aarch64-linux-gnu \
  -e INSTALL_PREFIX="$INSTALL_PREFIX" \
  "$IMAGE" \
  bash -c "
    set -euo pipefail
    export PATH=\"/usr/lib/ccache:\$PATH\"
    mkdir -p /usr/lib/aarch64-linux-gnu
    for target_lib in /sysroot/usr/lib/aarch64-linux-gnu/*; do
      [[ -e \"\$target_lib\" ]] || continue
      target_lib_name=\${target_lib##*/}
      [[ "\$target_lib_name" == libexec ]] && continue
      if [[ ! -e \"/usr/lib/aarch64-linux-gnu/\$target_lib_name\" ]]; then
        ln -s \"\$target_lib\" \"/usr/lib/aarch64-linux-gnu/\$target_lib_name\"
      fi
    done
    for qt_tool in qtpaths androiddeployqt androidtestrunner qmake python3.13; do
      if [[ ! -e \"/usr/bin/\$qt_tool\" && -e \"/sysroot/usr/bin/\$qt_tool\" ]]; then
        ln -s \"/sysroot/usr/bin/\$qt_tool\" \"/usr/bin/\$qt_tool\"
      fi
    done
    ln -sfn /sysroot/lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1
    bash /work/project/scripts/prepare-cross-sdk-qemu-tools.sh
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
      -DCMAKE_EXE_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -L/sysroot/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/usr/lib/aarch64-linux-gnu' \
      -DCMAKE_SHARED_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -L/sysroot/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/usr/lib/aarch64-linux-gnu' \
      -DCMAKE_MODULE_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -L/sysroot/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/usr/lib/aarch64-linux-gnu'
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
