#!/usr/bin/env bash
# unzip_all.sh
# Usage: bash scripts/unzip_all.sh /path/to/zips /path/to/destination
set -euo pipefail

SRC="${1:-$PWD}"
DEST="${2:-$PWD/repo_import}"
mkdir -p "$DEST"

shopt -s nullglob
zips=("$SRC"/*.zip)
if (( ${#zips[@]} == 0 )); then
  echo "No .zip files found in: $SRC"
  exit 0
fi

for z in "${zips[@]}"; do
  echo "Unzipping: $z"
  tmp="$(mktemp -d)"
  unzip -qq "$z" -d "$tmp"
  rsync -a --exclude="__MACOSX" "$tmp"/ "$DEST"/
  rm -rf "$tmp"
done

echo "Done. Consolidated contents in: $DEST"
