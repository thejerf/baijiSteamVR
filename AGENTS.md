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
- Steam Frame presentation fixes (SMG2, 2026-10-04): the XR pacing loop does not
  wait for new game content after `xrWaitFrame`; that removed a significant source
  of hitching. StereoScreen also batches both Vulkan eye blits, waits once for GPU
  completion, releases both images, then publishes the quad layers. Submitted but
  unfinished eye writes produced conspicuous doubling/stale-image hiccups on Frame;
  the completed-pair handoff resolved them in headset testing at 2x/120 Hz. Keep
  this completion wait even when timeline semaphores are enabled. It trades some
  CPU/GPU overlap for correct image delivery. `PresentBackbuffer` already advances
  frame resources; the stereo submit must not advance them again.
- `m_video_handoff_mutex` excludes `xrEndFrame` from the video's blit/completion/
  release/publish transaction. The previous atomic flag had a check-to-submit race.
  Keep the handoff -> publish/graphics-queue lock order; never take the handoff
  lock while holding either of those other locks. Do not hold the graphics-queue
  lock during the GPU-completion wait.
- Investigation evidence: 16699 XFB copies showed no detected gameplay source,
  GPU-submit, XR display-time reversal, or eye-ID mismatch, while CPU-side handoff
  locking alone did not cure doubling. SteamVR motion smoothing was already
  ForceOff (`motionSmoothingOverride=2`); reprojection counts did not establish
  temporal blending. GPU readbacks accounted for long waits and 1x improved the
  remaining isolated drops. Keep 120 Hz for comparison; refresh-rate mismatch was
  already investigated. Temporary timing/order captures and analyzers were removed
  after the fix. Desktop mirroring is forced off and its Qt options are hidden.
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
- Frame audio quirk (2026-10-11): AudioCommon sends stereo through Cubeb/PipeWire;
  SteamOS WirePlumber creates a `spatialize_filter_chain` for output streams when the
  built-in speaker sink is default. `node.stream.enable-spatial-audio` is a global
  setting, and the current policy has no per-application opt-out. Do not change this
  global setting for Baiji; leave the UI-position spatialization documented as a quirk
  unless Frame exposes a supported per-stream opt-out.
- Baiji is a Steam Frame-only Dolphin cut; changes may be intentionally more
  aggressive than upstream Dolphin. This branch is temporary and can end once
  upstream incorporates its features. Inspect Baiji data only under
  `~/.config/baiji` and `~/.local/share/baiji`; ignore the separate Dolphin
  installation/config. Legacy INI filenames may remain, but Dolphin installation
  or user-data paths inside Baiji config are suspicious and must not be followed.
- Never modify Frame/SteamOS/SteamVR system or runtime settings as part of Baiji
  development, testing, or deployment, even for temporary experiments. Treat
  `~/.config/openvr/config/steamvr.vrsettings` and other non-Baiji settings as
  read-only; keep testing changes within Baiji-owned code, binaries, and config.
- Frame build: from the repository root run
  `INSTALL_PREFIX=/home/steamos/baiji ./scripts/compile-cross-sdk.sh`, then
  `./scripts/deploy-frame.sh frame`. The build uses Podman, installs the AArch64 KDE SDK
  into ignored `state/` via Flatpak when missing, rebuilds the image when
  `Containerfile.cross` changes, and stages to
  `state/stage-frame/`. Its persistent build/cache are
  `state/build-baiji/` and `state/ccache-cross-sdk/`. It configures
  `ENABLE_TESTS=OFF`; this is not a test build.
- Snapshot release tarballs should use a fresh `STAGE_DIR` with the same Frame cross-SDK
  build, then archive its `home/steamos/baiji` tree so the tarball root is `baiji/`. The
  recipe and upgrade verification are in `docs/build-runbook.md`; do not upload or publish
  without an explicit request.
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
- For binary-only Frame builds, atomically replace
  `~/baiji/bin/baiji` with `state/stage-frame/home/steamos/baiji/bin/baiji`; this is
  the emulator executable launched by `~/baiji/bin/baiji-vr` from the Big Picture /
  Gamescope shortcut. Leave `baiji-vr` in place. Use `deploy-frame.sh` when staged
  libraries/assets also changed.
  The user promoted the current Frame build to known-good on 2026-10-04 despite
  uncertainty about intermittent controller input and reported performance improvement.
  Preserve `~/baiji/bin/baiji-known-good`; only replace it on explicit user promotion.
  To restore the Big Picture shortcut to that build, copy it back to `~/baiji/bin/baiji`.
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
  <https://partner.steamgames.com/doc/steamhardware/steamframe/debugging>; consult it
  before retrieving or processing Frame crash dumps.
- The deploy script copies Baiji-named files under `~/baiji` on the target. CLI
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
- This project is not particularly worried about linting. Don't worry
  about trying to run clang-format. Nor is there any practical way to
  unit test most of the work this project is doing as it is all UI work.

## External technical references

- [Steam Frame developer setup](https://partner.steamgames.com/doc/steamhardware/steamframe/setup)
  covers Developer Mode, SSH/ADB access, and recommended beta channels; consult it
  when setting up or troubleshooting access to a Frame development headset.
- [Steam Frame OpenXR engine integrations](https://partner.steamgames.com/doc/steamhardware/steamframe/engines)
  collects platform-specific OpenXR integration guidance for supported engines.
  Start here when adapting general OpenXR behavior to the Frame runtime.
- [Steam Frame custom engine integration](https://partner.steamgames.com/doc/steamhardware/steamframe/engines/custom)
  is the more direct reference for applications integrating OpenXR without one of
  the documented game engines; check its runtime and extension guidance for
  Frame-specific requirements.
- [Steam Frame Input](https://partner.steamgames.com/doc/steamhardware/steamframe/input)
  documents the headset's controller/input behavior and is useful when investigating
  controller profiles, bindings, or input expectations on-device.
- [Khronos OpenXR Tutorial](https://openxr-tutorial.com/)
  provides practical, API-level examples of initialization, graphics/swapchains,
  actions, and extensions across platforms; use it for implementation patterns, then
  verify runtime-specific support separately.
- [Khronos OpenXR 1.1 Specification](https://registry.khronos.org/OpenXR/specs/1.1/html/xrspec.html)
  is the normative reference for API semantics, synchronization, and extension behavior;
  consult it when tutorial examples leave behavior ambiguous.
- [Khronos OpenXR SDK Source](https://github.com/KhronosGroup/OpenXR-SDK-Source)
  contains the OpenXR loader and SDK source; use it to investigate loader behavior or
  SDK integration details, not as a substitute for checking extensions exposed by the
  Frame runtime.
