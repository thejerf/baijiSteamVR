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
INSTALL_PREFIX=/home/steamos/baiju ./scripts/compile-cross-sdk.sh
./scripts/deploy-frame.sh frame
```

The build installs locally under `state/stage-frame/home/steamos/baiju` before
deployment. App executables use the `baiji` names. Private dynamic libraries are
installed below `~/baiju/lib/baiji`; application data is in `~/baiju/share/baiji`.
Localized catalogs, when available, are kept under `~/baiju/share/baiji/locale` so the
app never reads the existing install's shared locale directory.
No Dolphin-named executable, last-good binary, or legacy user-data directory is used
or modified.
The Frame's glibc is 2.39, so the dependency collector leaves glibc, `libmvec`, and
`libgpg-error` to the Frame's compatible system copies instead of bundling newer SDK
builds.

Smoke-test the CLI on the Frame:

```bash
ssh frame 'LD_LIBRARY_PATH="$HOME/baiju/lib/baiji" "$HOME/baiju/bin/baiji-tool" --help'
ssh frame 'LD_LIBRARY_PATH="$HOME/baiju/lib/baiji" "$HOME/baiju/bin/baiji-nogui" --help'
```

To launch the Baiji GUI in the nested X11 desktop with the SteamVR runtime:

```bash
ssh frame 'BAIJI_DISPLAY=:0 "$HOME/baiju/bin/baiji-vr"'
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
