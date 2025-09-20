#!/usr/bin/env bash
# organize_repo.sh
# Usage: bash scripts/organize_repo.sh /path/to/repo
set -euo pipefail
ROOT="${1:-$PWD}"

mkdir -p "$ROOT"/{scripts,art/{pages,panels,concepts,characters},refs,exports,docs}

# Move common code/scripts
find "$ROOT" -maxdepth 1 -type f \( -iname "*.py" -o -iname "*.sh" -o -iname "*.js" -o -iname "*.ts" \) -exec mv -n {} "$ROOT/scripts/" \;

# Move layered art project files
find "$ROOT" -type f \( -iname "*.psd" -o -iname "*.clip" -o -iname "*.kra" -o -iname "*.procreate" \) -exec mv -n {} "$ROOT/art/" \;

# Move images with heuristics
find "$ROOT" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.tif" -o -iname "*.tiff" \) -print0 | while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  low="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
  if [[ "$low" == *concept* || "$low" == *turnaround* || "$low" == *sheet* ]]; then
    mv -n "$f" "$ROOT/art/concepts/"
  elif [[ "$low" == *page* || "$low" =~ p[0-9][0-9] || "$low" == *panel* ]]; then
    mv -n "$f" "$ROOT/art/pages/"
  elif [[ "$low" == *ref* || "$low" == *reference* || "$low" == *mood* || "$low" == *palette* ]]; then
    mv -n "$f" "$ROOT/refs/"
  else
    mv -n "$f" "$ROOT/art/"
  fi
done

# Documents
find "$ROOT" -type f \( -iname "*.pdf" -o -iname "*.md" -o -iname "*.docx" -o -iname "*.txt" \) -exec mv -n {} "$ROOT/docs/" \;

echo "Organized repo at: $ROOT"
