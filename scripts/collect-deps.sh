#!/bin/bash
set -euo pipefail
SYSROOT="${SYSROOT:-/sysroot}"
DEST="${DEST:-/work/dest/home/steamos/baiji/lib/baiji}"
mkdir -p "$DEST"
# Steam Frame runs glibc 2.39; use its glibc vector and gpg-error libraries rather
# than the newer SDK copies (which require GLIBC_2.41/2.42).
rm -f "$DEST/libmvec.so.1" "$DEST/libgpg-error.so.0"

# Directories to search for libraries
LIBDIRS=(
  "$SYSROOT/lib/aarch64-linux-gnu"
  "$SYSROOT/lib/aarch64-linux-gnu/pulseaudio"
  "$SYSROOT/usr/lib/aarch64-linux-gnu"
  "$SYSROOT/usr/lib/aarch64-linux-gnu/pulseaudio"
  "$SYSROOT/usr/lib/pulseaudio"
  "$SYSROOT/lib/pulseaudio"
  "$SYSROOT/usr/lib"
  "$SYSROOT/lib"
)

find_lib() {
  local name="$1"
  for d in "${LIBDIRS[@]}"; do
    if [ -e "$d/$name" ]; then
      echo "$d/$name"
      return 0
    fi
  done
  return 1
}

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 executable-or-shared-library [...]" >&2
  exit 2
fi

NEEDED_STACK=()
for binary in "$@"; do
  while read -r dep; do
    [ -z "$dep" ] && continue
    NEEDED_STACK+=("$dep")
  done < <(aarch64-linux-gnu-readelf -d "$binary" | awk '/NEEDED/ {dep=$NF; sub(/^\[/,"",dep); sub(/\]$/,"",dep); print dep}')
done
COPIED=()
MISSING=()
declare -A VISITED=()
while [ ${#NEEDED_STACK[@]} -gt 0 ]; do
  NEEDED="${NEEDED_STACK[-1]}"
  unset 'NEEDED_STACK[-1]'
  [ -n "$NEEDED" ] || continue
  [[ -n "${VISITED[$NEEDED]:-}" ]] && continue
  VISITED["$NEEDED"]=1
  # Skip glibc/system libs
  case "$NEEDED" in
    libc.so.6|libm.so.6|libmvec.so.1|libpthread.so.0|libdl.so.2|librt.so.1|ld-linux-aarch64.so.1|libgpg-error.so.0) continue ;;
  esac
  if [ -e "$DEST/$NEEDED" ]; then
    SRC="$DEST/$NEEDED"
  else
    SRC=$(find_lib "$NEEDED") || { echo "missing dependency: $NEEDED" >&2; MISSING+=("$NEEDED"); continue; }
    cp -aL "$SRC" "$DEST/$NEEDED"
    COPIED+=("$NEEDED")
    SRC="$DEST/$NEEDED"
  fi
  # Recurse on deps
  while read -r dep; do
    [ -z "$dep" ] && continue
    NEEDED_STACK+=("$dep")
  done < <(aarch64-linux-gnu-readelf -d "$SRC" | awk '/NEEDED/ {dep=$NF; sub(/^\[/,"",dep); sub(/\]$/,"",dep); print dep}')
done

echo "Copied ${#COPIED[@]} libraries"
if [ ${#MISSING[@]} -gt 0 ]; then
  printf 'Unresolved dependencies: %s\n' "${MISSING[*]}" >&2
  exit 1
fi
