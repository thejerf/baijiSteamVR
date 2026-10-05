#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ENGINE="${ENGINE:-podman}"

$ENGINE build --platform linux/amd64 -f Containerfile.build -t baijisteamvr-build:amd64 .
$ENGINE build --platform linux/arm64 -f Containerfile.build -t baijisteamvr-build:arm64 .
