#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ENGINE="${ENGINE:-podman}"

mkdir -p state/cross-sysroot
rm -rf state/cross-sysroot/*

container="baijisteamvr-arm64-rootfs"
"$ENGINE" rm -f "$container" >/dev/null 2>&1 || true
"$ENGINE" create --name "$container" --platform linux/arm64 baijisteamvr-build:arm64 /bin/true
"$ENGINE" export "$container" | tar -C state/cross-sysroot -xf -
"$ENGINE" rm -f "$container" >/dev/null 2>&1 || true

echo "Sysroot exported to state/cross-sysroot ($(du -sh state/cross-sysroot | cut -f1))"
