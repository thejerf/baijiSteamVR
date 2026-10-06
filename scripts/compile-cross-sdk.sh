#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
if [[ "$SCRIPT_DIR" == "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR=.
fi
case "$SCRIPT_DIR" in
  /*) cd "$SCRIPT_DIR/.." ;;
  *) cd "./$SCRIPT_DIR/.." ;;
esac
ENGINE=podman
DEBUG_SYMBOLS="${DEBUG_SYMBOLS:-0}"
case "$DEBUG_SYMBOLS" in
  0)
    DEBUG_FLAGS=""
    MESON_DEBUG_SYMBOLS=false
    ;;
  1)
    DEBUG_FLAGS=" -g"
    MESON_DEBUG_SYMBOLS=true
    ;;
  *)
    echo "DEBUG_SYMBOLS must be 0 (default) or 1." >&2
    exit 2
    ;;
esac
INSTALL_PREFIX="${INSTALL_PREFIX:-/home/steamos/baiji}"
BUILD_DIR="$PWD/state/build-baiji"
STAGE_DIR="$PWD/state/stage-frame"
SDK="$PWD/state/flatpak-home/.local/share/flatpak/runtime/org.kde.Sdk/aarch64/6.10/active/files"
FLATPAK_USER_DIR="$PWD/state/flatpak-home/.local/share/flatpak"
SDK_OVERLAY="$PWD/state/sdk-overlay"
SDK_INCLUDE_OVERLAY="$SDK_OVERLAY/usr/include"
IMAGE="localhost/baijisteamvr-cross:latest"
IMAGE_STAMP="$PWD/state/cross-sdk-image-$ENGINE.sha256"

PREFLIGHT_ERRORS=()
for required_command in podman sha256sum cut mkdir ln cp; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    PREFLIGHT_ERRORS+=("Required command '$required_command' was not found in PATH.")
  fi
done
if [[ ! -d "$SDK" ]] && ! command -v flatpak >/dev/null 2>&1; then
  PREFLIGHT_ERRORS+=("The AArch64 KDE SDK is missing and Flatpak is required to install org.kde.Sdk//6.10.")
fi
if [[ ! -f Containerfile.cross ]]; then
  PREFLIGHT_ERRORS+=("Missing cross-build container definition: $PWD/Containerfile.cross")
fi
if (( ${#PREFLIGHT_ERRORS[@]} > 0 )); then
  printf 'Error: %s\n' "${PREFLIGHT_ERRORS[@]}" >&2
  printf 'Aborting cross-SDK build after %d preflight error(s).\n' "${#PREFLIGHT_ERRORS[@]}" >&2
  exit 1
fi

if [[ ! -d "$SDK" ]]; then
  printf 'Installing the AArch64 KDE SDK runtime (org.kde.Sdk//6.10) into %s\n' \
    "$FLATPAK_USER_DIR"
  mkdir -p "$FLATPAK_USER_DIR"
  FLATPAK_USER_DIR="$FLATPAK_USER_DIR" flatpak remote-add --user --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
  FLATPAK_USER_DIR="$FLATPAK_USER_DIR" flatpak install --user --arch=aarch64 --noninteractive \
    --assumeyes flathub \
    org.kde.Sdk//6.10
fi
if [[ ! -d "$SDK" ]]; then
  echo "The AArch64 KDE SDK runtime was not installed at the expected path: $SDK" >&2
  exit 1
fi
if [[ ! -x "$SDK/lib/libexec/syncqt" ]]; then
  echo "The KDE SDK is missing Qt's AArch64 syncqt tool: $SDK/lib/libexec/syncqt" >&2
  exit 1
fi

IMAGE_CONFIGURATION_HASH="$(sha256sum Containerfile.cross | cut -d ' ' -f 1)"
mkdir -p "$BUILD_DIR" state/ccache-cross-sdk "$STAGE_DIR" dist

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

EXTRA_FLAGS="-O3 -mcpu=cortex-x4 -I/sysroot/include -DXR_USE_GRAPHICS_API_OPENGL$DEBUG_FLAGS"

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
    if [[ ! -e /usr/mkspecs ]]; then
      ln -s /sysroot/usr/mkspecs /usr/mkspecs
    fi
    for sdk_header in /sysroot/usr/include/Qt*; do
      [[ -e \"\$sdk_header\" ]] || continue
      sdk_header_name=\${sdk_header##*/}
      if [[ ! -e \"/usr/include/\$sdk_header_name\" ]]; then
        ln -s \"\$sdk_header\" \"/usr/include/\$sdk_header_name\"
      fi
    done
    for target_lib in /sysroot/lib/aarch64-linux-gnu/* /sysroot/usr/lib/aarch64-linux-gnu/*; do
      [[ -e \"\$target_lib\" ]] || continue
      target_lib_name=\${target_lib##*/}
      [[ "\$target_lib_name" == libexec ]] && continue
      if [[ ! -e \"/usr/lib/aarch64-linux-gnu/\$target_lib_name\" ]]; then
        ln -sfn \"\$target_lib\" \"/usr/lib/aarch64-linux-gnu/\$target_lib_name\"
      fi
    done
    for sdk_tool in /sysroot/usr/bin/*; do
      [[ -x \"\$sdk_tool\" ]] || continue
      sdk_tool_name=\${sdk_tool##*/}
      if [[ ! -e \"/usr/bin/\$sdk_tool_name\" ]]; then
        ln -s /usr/local/bin/qemu-aarch64-wrapper \"/usr/bin/\$sdk_tool_name\"
      fi
    done
    mkdir -p /usr/lib/libexec
    for sdk_tool in /sysroot/usr/lib/libexec/*; do
      [[ -x \"\$sdk_tool\" ]] || continue
      sdk_tool_name=\${sdk_tool##*/}
      if [[ ! -e \"/usr/lib/libexec/\$sdk_tool_name\" ]]; then
        ln -s /usr/local/bin/qemu-aarch64-wrapper \"/usr/lib/libexec/\$sdk_tool_name\"
      fi
    done
    for sdk_tool in /sysroot/usr/lib/aarch64-linux-gnu/libexec/kf6/*; do
      [[ -x \"\$sdk_tool\" ]] || continue
      sdk_tool_name=\${sdk_tool##*/}
      if [[ ! -e \"/usr/lib/aarch64-linux-gnu/libexec/kf6/\$sdk_tool_name\" ]]; then
        mkdir -p /usr/lib/aarch64-linux-gnu/libexec/kf6
        ln -s /usr/local/bin/qemu-aarch64-wrapper \"/usr/lib/aarch64-linux-gnu/libexec/kf6/\$sdk_tool_name\"
      fi
    done
    ln -sfn /sysroot/lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1
    LIBEVDEV_VERSION=1.13.4
    LIBEVDEV_SOURCE_HASH=0cfa48d1dddac26988ae9ce16282eff97683f1adcd3f5d4312f86d714565d890
    LIBEVDEV_DIR=/work/build/_deps/libevdev
    LIBEVDEV_ARCHIVE=\$LIBEVDEV_DIR/libevdev-\$LIBEVDEV_VERSION.tar.gz
    LIBEVDEV_SOURCE_DIR=\$LIBEVDEV_DIR/src/libevdev-libevdev-\$LIBEVDEV_VERSION
    LIBEVDEV_BUILD_DIR=\$LIBEVDEV_DIR/build
    LIBEVDEV_INSTALL_DIR=\$LIBEVDEV_DIR/install
    LIBEVDEV_SOURCE_URL=https://gitlab.freedesktop.org/libevdev/libevdev/-/archive/libevdev-\$LIBEVDEV_VERSION/libevdev-libevdev-\$LIBEVDEV_VERSION.tar.gz
    mkdir -p \$LIBEVDEV_DIR/src
    if [[ ! -f \$LIBEVDEV_ARCHIVE ]] || ! printf '%s  %s\\n' \$LIBEVDEV_SOURCE_HASH \$LIBEVDEV_ARCHIVE | sha256sum --check --status; then
      curl --fail --location --retry 3 \$LIBEVDEV_SOURCE_URL --output \$LIBEVDEV_ARCHIVE
    fi
    printf '%s  %s\\n' \$LIBEVDEV_SOURCE_HASH \$LIBEVDEV_ARCHIVE | sha256sum --check
    if [[ ! -f \$LIBEVDEV_SOURCE_DIR/meson.build ]]; then
      tar --extract --gzip --file \$LIBEVDEV_ARCHIVE --directory \$LIBEVDEV_DIR/src
    fi
    if [[ ! -f \$LIBEVDEV_BUILD_DIR/build.ninja ]]; then
      meson setup \$LIBEVDEV_BUILD_DIR \$LIBEVDEV_SOURCE_DIR \\
        --cross-file /work/project/scripts/cross-meson-sdk.txt \\
        --prefix \$LIBEVDEV_INSTALL_DIR \\
        --libdir lib/aarch64-linux-gnu \\
        --buildtype=release \\
        -Ddebug=$MESON_DEBUG_SYMBOLS \\
        -Ddefault_library=static \\
        -Dtests=disabled \\
        -Dtools=disabled \\
        -Ddocumentation=disabled
    else
      meson configure \$LIBEVDEV_BUILD_DIR --buildtype=release -Ddebug=$MESON_DEBUG_SYMBOLS
    fi
    meson compile -C \$LIBEVDEV_BUILD_DIR
    meson install -C \$LIBEVDEV_BUILD_DIR
    cmake -S /work/project -B /work/build -G Ninja \
      -DCMAKE_TOOLCHAIN_FILE=/work/project/scripts/cross-toolchain-sdk.cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_FLAGS=\"$EXTRA_FLAGS\" \
      -DCMAKE_CXX_FLAGS=\"$EXTRA_FLAGS\" \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DLIBEVDEV_INCLUDE_DIR=/work/build/_deps/libevdev/install/include/libevdev-1.0 \
      -DLIBEVDEV_LIBRARY=/work/build/_deps/libevdev/install/lib/aarch64-linux-gnu/libevdev.a \
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
      -DCMAKE_EXE_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -L/sysroot/lib/aarch64-linux-gnu/pulseaudio -L/sysroot/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu/pulseaudio -Wl,-rpath-link,/sysroot/usr/lib/aarch64-linux-gnu' \
      -DCMAKE_SHARED_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -L/sysroot/lib/aarch64-linux-gnu/pulseaudio -L/sysroot/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu/pulseaudio -Wl,-rpath-link,/sysroot/usr/lib/aarch64-linux-gnu' \
      -DCMAKE_MODULE_LINKER_FLAGS='-L/sysroot/lib/aarch64-linux-gnu -L/sysroot/lib/aarch64-linux-gnu/pulseaudio -L/sysroot/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu -Wl,-rpath-link,/sysroot/lib/aarch64-linux-gnu/pulseaudio -Wl,-rpath-link,/sysroot/usr/lib/aarch64-linux-gnu'
    cmake --build /work/build --target dolphin-emu dolphin-nogui dolphin-tool -j12
    DESTDIR=/work/stage cmake --install /work/build
    install -D -m 644 /work/build/_deps/libevdev/src/libevdev-libevdev-1.13.4/COPYING /work/stage\$INSTALL_PREFIX/share/baiji/licenses/libevdev-COPYING

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
