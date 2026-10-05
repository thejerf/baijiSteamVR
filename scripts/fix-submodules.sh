#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# The OpenXR commit in the upstream SDK that the DolphinXR patch targets.
OPENXR_COMMIT="f2448a8797c85814aa892efc1ab8707900fbcc78"

# Known-good fallback tag for submodules whose recorded commit has disappeared.
FMT_TAG="11.0.2"

# Submodules we fix manually (recorded commit missing upstream or not needed on Linux).
git config submodule.Externals/OpenXR.update none
git config submodule.Externals/fmt/fmt.update none
git config submodule.Externals/Qt.update none
git config submodule.Externals/FFmpeg-bin.update none

# Initialize everything else.
echo "Initializing submodules..."
git submodule update --init --recursive

# Fix fmt to a fallback tag.
echo "Fixing fmt submodule to $FMT_TAG..."
cd Externals/fmt/fmt
git fetch --tags origin
git checkout -f "$FMT_TAG"
cd ../../..

# Fix OpenXR: known commit + local patches.
echo "Fixing OpenXR submodule to $OPENXR_COMMIT + patches..."
cd Externals/OpenXR
git checkout -f "$OPENXR_COMMIT"
apply_if_clean() {
  if git apply --check "$1" 2>/dev/null; then
    git apply "$1"
    echo "    applied $(basename "$1")"
  else
    echo "    $(basename "$1") already applied or not applicable"
  fi
}
apply_if_clean ../../OpenXR.patch
apply_if_clean ../../patches/openxr-destructor.patch
apply_if_clean ../../patches/openxr-loader-exceptions.patch
cd ../..

echo ""
echo "Submodule summary:"
git submodule status | head -50
