# Repository guidance

- This is a CMake-based Dolphin/OpenXR fork. Native Steam Frame (AArch64) builds
  use `scripts/compile-cross-sdk.sh`; the maintained build/deploy workflow and
  local SDK details are in `docs/build-runbook.md`. Flatpak files under
  `legacy/flatpak/` are archived, not the active Frame workflow.
- Recent `openxr-work` changes focus on Steam Frame OpenXR presentation and input.
  `OpenXRPresentationMode` (Vulkan, Immersive, StereoScreen, or legacy settings)
  is resolved in `VideoCommon/VideoConfig.cpp`; keep its config/UI and backend
  paths in sync. StereoScreen reuses the SBS presenter path but submits separate
  OpenXR quad layers; its shared submission/pose logic is in `VideoCommon/Present.*`
  and `VideoCommon/VR/OpenXRManager.*`, with swapchain work in video backends.
  OpenXR reference-space events are polled on the XR pacing thread; flat-screen pose
  invalidation is deferred until `LocateViews` refreshes the video-thread view snapshot.
  Preserve this ordering and the cache synchronization when changing recenter behavior.
- Config defaults are declared in `Source/Core/Core/Config/GraphicsSettings.cpp`;
  the VR mode is `GFX_VR_PRESENTATION_MODE` (`Graphics.VR.PresentationMode`). Keep
  its choices aligned with `DolphinQt/Config/VRConfigWidget.cpp` and
  `DolphinQt/Settings/VRPane.cpp`; runtime mode resolution is in
  `VideoCommon/VideoConfig.cpp`.
- XR heartbeat is `GFX_VR_EAGER_HEARTBEAT` (`Graphics.VR.EagerHeartbeat`), declared
  in `GraphicsSettings.cpp` and loaded in `VideoConfig.cpp`. `true` is Eager (submit
  each HMD refresh, reusing the last frame); `false` is Lazy (pace submissions to game
  frames so PC runtime motion smoothing can engage).
- Frame controller changes span `Common/VR/OpenXRInputState.h`,
  `InputCommon/ControllerInterface/OpenXR/OpenXR.cpp`, Vulkan/OpenXR session setup,
  the Qt mapping UI, and `Data/Sys/Profiles/`. For Frame controllers, Flat Vulkan
  uses SDL/Steam Input; StereoScreen and Immersive VR use OpenXR controller actions.
  Preserve this mode-dependent split. Keep profile defaults and UI/controller
  loading order aligned.
- Open issue (tabled while focusing on StereoScreen): Flat-mode orientation pointing
  through SDL is unresolved. The Frame's `SDL/0/Steam Frame Controllers` provides
  button/axis inputs, but the diagnostic trace found no SDL Accel/Gyro inputs and
  sensor values stayed zero while the user rotated the controller. The captured trace
  did show d-pad, trigger, and stick events, so it did not reproduce total SDL input
  loss. Keep the thumbstick IR fallback; do not assume SDL sensor support.
- Baiji is a Steam Frame-only Dolphin cut; changes may be intentionally more
  aggressive than upstream Dolphin. This branch is temporary and can end once
  upstream incorporates its features. Inspect Baiji data only under
  `~/.config/baiji` and `~/.local/share/baiji`; ignore the separate Dolphin
  installation/config. Legacy INI filenames may remain, but Dolphin installation
  or user-data paths inside Baiji config are suspicious and must not be followed.
- Frame build: from the repository root run
  `INSTALL_PREFIX=/home/steamos/baiju ./scripts/compile-cross-sdk.sh`, then
  `./scripts/deploy-frame.sh frame`. The build uses Podman by default (`ENGINE=docker`
  selects Docker), needs the existing SDK under `state/`, reuses the image if already
  built, and stages to `state/stage-frame/`. Its persistent build/cache are
  `state/build-baiji/` and `state/ccache-cross-sdk/`. It configures
  `ENABLE_TESTS=OFF`; this is not a test build.
- `scripts/compile.sh [native|aarch64] [target...]` is the general container build
  helper; it defaults to `native` and `dolphin-emu`. It uses cached local Podman
  images `baijisteamvr-build:amd64` and `baijisteamvr-build:arm64` and does not rebuild
  the container environment for each code build. Run `scripts/build-env.sh` for a
  missing image or after changing `Containerfile.build`; normal `compile.sh` builds
  reuse the tagged images and ignored `state/build-*` CMake build directories.
  `state/ccache/` also persists between builds and is wired through CMake compiler
  launchers. Do not clear either cache for normal edits; a changed compiler/image may
  cause one full rebuild, but later builds should be incremental. Use
  `compile-cross-sdk.sh` for the maintained Steam Frame SDK/staging workflow above.
- `scripts/compile.sh aarch64 dolphin-emu` builds an arm64 executable at
  `state/build-aarch64/Binaries/baiji`, but this uses the Ubuntu 26.04 build image
  (glibc 2.43). The Frame has glibc 2.39, so do not copy that raw executable there;
  use `compile-cross-sdk.sh` and its Frame-compatible SDK/staging output instead.
- For a binary-only Frame debug iteration, copy
  `state/stage-frame/home/steamos/baiju/bin/baiji` to
  `frame:baiju/bin/baiji`; use `deploy-frame.sh` when staged libraries/assets also
  changed. The Big Picture shortcut launches `~/baiju/bin/baiji-vr`, which runs
  `~/baiju/bin/baiji`, so keep replacing that binary path to reuse the shortcut.
  The user promoted the current Frame build to known-good on 2026-10-04 despite
  uncertainty about intermittent controller input and reported performance improvement.
  Preserve `~/baiju/bin/baiji-known-good`; only replace it on explicit user promotion.
  To restore the Big Picture shortcut to that build, copy it back to `~/baiju/bin/baiji`.
  We cannot test headset controls directly from the development host: collaborate with
  the user on debug runs and retrieve logs over SSH.
- On the Frame, creating `~/.config/baiji/debug-logging` makes the existing
  `baiji-vr` shortcut enable verbose Video/OpenXR/Controller Interface (`CI`) logging.
  Retrieve `~/.local/share/baiji/Logs/dolphin.log` and
  `~/.local/share/baiji/Logs/baiji-launcher.log` over SSH; remove the marker to
  return to normal logging. Collaborate with the user for headset input tests, then
  inspect the resulting logs.
- The configured SSH alias is `frame`. If it is absent on a development machine,
  ask the user to create it; it makes build transfer and device debugging much easier.
- Steam Frame debugging guidance, especially core-dump access and processing, is at
  <https://partner.steamgames.com/doc/steamhardware/steamframe/debugging>.
- The deploy script copies Baiji-named files under `~/baiju` on the target. CLI
  smoke tests are documented in `docs/build-runbook.md`; the GUI launcher is
  `baiji-vr`.
- For a host Linux VR build, configure with
  `cmake -S . -B Build -DENABLE_VR=ON -DENABLE_VULKAN=ON`, then build with
  `cmake --build Build --target dolphin-emu -j "$(nproc)"`.
- Unit tests are enabled by default in the root CMake configuration, but the
  Frame cross-build disables them. In a test-enabled build, use
  `cmake --build <build-dir> --target unittests`; to run a focused GoogleTest,
  build `tests` and invoke `<build-dir>/Binaries/Tests/tests --gtest_filter=<filter>`.
- `Tools/lint.sh` checks changed/staged source files and requires clang-format
  19.1. See `Contributing.md` for formatting details.
- Before changing submodules, inspect their worktrees and preserve local edits.
  `scripts/fix-submodules.sh` force-checks out fmt and OpenXR revisions; the
  runbook marks it for reviewed use on a fresh checkout only.
- Keep build/cache/staging outputs in ignored `state/` and `dist/`. Do not deploy
  or alter unrelated existing Frame binaries, user data, or Steam shortcuts;
  follow the runbook's Baiji-only paths. Do not publish from this checkout unless
  explicitly requested.
