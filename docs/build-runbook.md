# BaijiSteamVR native Steam Frame build

## Repository layout

The Git repository is the project root (`~/src/baijiSteamVR`). Build inputs live in
the repository; ignored local state and outputs are kept in `state/` and `dist/`.
The old Flatpak application build and deployment scripts are archived in
`legacy/flatpak/` and are not used for Steam Frame builds.

- `scripts/compile-cross-sdk.sh` — cross-build, native install staging, and bundled
  dependency collection for AArch64.
- `scripts/deploy-frame.sh` — transfer only the Baiji executable, library, and data
  paths to a Frame (`frame` by default); it never deletes or replaces old binaries.
- `state/flatpak-home/.../org.kde.Sdk/aarch64/6.10/active/files` — AArch64 KDE SDK
  sysroot used for compilation and Qt plugin/library collection; `compile-cross-sdk.sh`
  installs it via Flatpak if it is missing.
- `state/sdk-overlay/` — generated read-only sysroot view combining SDK paths expected
  under `/usr` without changing the installed SDK.
- `state/build-baiji/`, `state/ccache-cross-sdk/`, and `state/stage-frame/` — local
  ignored build, cache, and staged install.
- `Data/` and `Source/` — project sources, artwork, desktop entry, and man pages.

## Build and deploy

From the project root:

```bash
INSTALL_PREFIX=/home/steamos/baiji ./scripts/compile-cross-sdk.sh
./scripts/deploy-frame.sh frame
```

Steam Frame StereoScreen submits both eye blits together. The submit worker waits for the pair's
GPU fence, then releases both swapchain images and publishes the quad layers; while the pair is
pending, the video thread can advance and the XR pacing thread reprojects the last completed pair.

The build installs locally under `state/stage-frame/home/steamos/baiji` before
deployment. App executables use the `baiji` names. Private dynamic libraries are
installed below `~/baiji/lib/baiji`; application data is in `~/baiji/share/baiji`.
Localized catalogs, when available, are kept under `~/baiji/share/baiji/locale` so the
app never reads the existing install's shared locale directory.
No Dolphin-named executable, last-good binary, or legacy user-data directory is used
or modified.
The Frame's glibc is 2.39, so the dependency collector leaves glibc, `libmvec`, and
`libgpg-error` to the Frame's compatible system copies instead of bundling newer SDK
builds.

## Build a snapshot release tarball

Build the normal Frame targets into a fresh staging directory, then archive the installed
`baiji/` directory. A separate stage prevents files left by an older staged install from
leaking into the release, while the normal CMake build and ccache remain incremental:

```bash
VERSION=v0.2-alpha
STAGE_DIR="$(mktemp -d "$PWD/state/stage-release-$VERSION.XXXXXX")"
INSTALL_PREFIX=/home/steamos/baiji STAGE_DIR="$STAGE_DIR" \
  ./scripts/compile-cross-sdk.sh
ARCHIVE="dist/baiji-$VERSION.tar.bz2"
tar --sort=name -cjf "$ARCHIVE" -C "$STAGE_DIR/home/steamos" baiji
```

The archive's root entry is `baiji/`, matching the snapshot installation and upgrade
commands in `Readme.md`. Check the archive contents and checksum before attaching it to a
GitHub release; release upload/publication is a separate explicit step.

To test an upgrade without touching a Frame install, extract the prior release and then the new
archive into the same temporary home. Confirm the resulting install matches the new archive and
that Baiji user data outside `baiji/` remains present:

```bash
UPGRADE_TEST="$(mktemp -d)"
trap 'rm -rf "$UPGRADE_TEST"' EXIT
mkdir -p "$UPGRADE_TEST/home/.config/baiji" "$UPGRADE_TEST/home/.local/share/baiji"
touch "$UPGRADE_TEST/home/.config/baiji/upgrade-test" \
  "$UPGRADE_TEST/home/.local/share/baiji/upgrade-test"
tar -xjf baiji-v0.1-alpha.tar.bz2 -C "$UPGRADE_TEST/home"
tar -xjf "$ARCHIVE" -C "$UPGRADE_TEST/home"
tar -djf "$ARCHIVE" -C "$UPGRADE_TEST/home"
test -f "$UPGRADE_TEST/home/.config/baiji/upgrade-test"
test -f "$UPGRADE_TEST/home/.local/share/baiji/upgrade-test"
```

Smoke-test the CLI on the Frame:

```bash
ssh frame 'LD_LIBRARY_PATH="$HOME/baiji/lib/baiji" "$HOME/baiji/bin/baiji-tool" --help'
ssh frame 'LD_LIBRARY_PATH="$HOME/baiji/lib/baiji" "$HOME/baiji/bin/baiji-nogui" --help'
```

To launch the Baiji GUI in the nested X11 desktop with the SteamVR runtime:

```bash
ssh frame 'BAIJI_DISPLAY=:0 "$HOME/baiji/bin/baiji-vr"'
```

The launcher preserves the Steam-provided `DISPLAY` (defaulting to `:2` for a direct
nested-desktop launch), uses Qt's XCB platform plugin from Baiji's private library
directory, selects `/opt/steamvr/steamxr_linuxarm64.json`, and writes launcher logs
under `~/.local/share/baiji/Logs/`.

## Steam Frame development access

Enable Developer Mode on the headset, then connect with `ssh steamos@frame`. Steam
Frame's Steamworks debugging guide documents Remote Desktop, Steam Link viewing,
performance overlays, and core-dump debugging:
<https://partner.steamgames.com/doc/steamhardware/steamframe/debugging>.

## Local build notes

- The cross-SDK build uses Podman.
- Before building, `compile-cross-sdk.sh` checks for Podman, its host utilities, and the
  container definition. If the SDK sysroot is missing, it installs `org.kde.Sdk//6.10`
  for AArch64 into ignored `state/` using Flatpak; this does not create a Flatpak app.
- The cross-build image includes `qemu-user`; no host QEMU executable is required or
  bind-mounted. The build helper tracks the `Containerfile.cross` hash and rebuilds the
  image when its configuration changes.
- The SDK does not include libevdev development files, so the build script downloads the
  checksum-pinned libevdev 1.13.4 source, cross-builds a static AArch64 library against
  the SDK sysroot, and keeps the evdev controller backend enabled. Its license is
  included in the staged application data.
- The SDK overlay is mounted as one sysroot view; avoid adding nested binds beneath the
  read-only SDK mount, which Podman/runc cannot create on some systems.
- Debug symbols are off by default. Prefix the build command with `DEBUG_SYMBOLS=1` to
  include them in both Baiji and the bundled libevdev build.
- `scripts/fix-submodules.sh` is for a fresh checkout only. Review its actions before
  running it, especially when any submodule worktree is modified.
- Preserve local changes in OpenXR, Qt, and fmt submodules; do not reset them.
- Do not push or publish from this working tree unless separately requested.
