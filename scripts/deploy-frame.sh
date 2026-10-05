#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
FRAME="${1:-frame}"
STAGE="state/stage-frame/home/steamos/baiji"

for file in baiji baiji-nogui baiji-tool baiji-vr; do
  if [[ ! -f "$STAGE/bin/$file" ]]; then
    echo "Missing staged file: $STAGE/bin/$file (run compile-cross-sdk.sh first)" >&2
    exit 1
  fi
done

ssh "$FRAME" 'mkdir -p ~/baiji/bin ~/baiji/lib/baiji ~/baiji/share'
ssh "$FRAME" 'rm -f ~/baiji/lib/baiji/libmvec.so.1 ~/baiji/lib/baiji/libgpg-error.so.0'
scp "$STAGE/bin/baiji" "$STAGE/bin/baiji-nogui" "$STAGE/bin/baiji-tool" \
  "$STAGE/bin/baiji-vr" "$FRAME:baiji/bin/"

tar -C "$STAGE" -cf - \
  lib/baiji \
  share/baiji \
  share/applications/org.baijisteamvr.BaijiSteamVR.desktop \
  share/icons/hicolor/256x256/apps/baiji.png \
  share/man/man6/baiji.6 \
  share/man/man6/baiji-nogui.6 |
  ssh "$FRAME" 'tar -xf - -C "$HOME/baiji"'

echo "BaijiSteamVR files deployed under $FRAME:~/baiji (no existing binaries removed)."
