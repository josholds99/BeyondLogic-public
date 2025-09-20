#!/bin/bash
set -euo pipefail

# --- Beyond Logic Repo Cleanup (fixed) ---

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

say() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# Create dirs
make_dirs() {
  for d in \
    docs \
    scripts/issue-01 scripts/issue-02 \
    art/pages/issue-01/src art/pages/issue-02/src \
    art/exports/issue-01 art/exports/issue-02 \
    design references production tools
  do
    if [[ $DRY_RUN -eq 1 ]]; then say "mkdir -p $d"; else mkdir -p "$d"; fi
  done
}

# Git LFS (safe if already installed)
setup_lfs() {
  if command -v git >/dev/null && git lfs version >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      say "git lfs track *.png *.jpg *.jpeg *.psd *.clip *.tif *.tiff *.pdf"
    else
      git lfs install || true
      git lfs track "*.png" "*.jpg" "*.jpeg" "*.psd" "*.clip" "*.tif" "*.tiff" "*.pdf" || true
      git add .gitattributes || true
    fi
  else
    say "Git LFS not installed; skipping LFS setup."
  fi
}

# Use git mv if tracked, otherwise mv + git add
move_file() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || return 0
  mkdir -p "$dst"
  local base; base="$(basename "$src")"
  if git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then say "git mv '$src' '$dst/$base'"; else git mv "$src" "$dst/$base"; fi
  else
    if [[ $DRY_RUN -eq 1 ]]; then say "mv '$src' '$dst/$base' && git add '$dst/$base'"; else mv "$src" "$dst/$base"; git add "$dst/$base" || true; fi
  fi
}

# Enable nullglob so empty globs disappear cleanly
shopt -s nullglob

# Rules
move_rules() {
  # Writing
  for f in *issue1*.md *Issue1*.md; do move_file "$f" scripts/issue-01; done
  for f in *issue2*.md *Issue2*.md; do move_file "$f" scripts/issue-02; done
  for f in *.md *.txt *.rtf *.docx;        do move_file "$f" scripts;          done

  # Art exports (jpg/png)
  for f in *issue-01*.jpg *issue-01*.jpeg *issue-01*.png *i01*.jpg *i01*.png *issue1*.jpg *issue1*.png; do
    move_file "$f" art/exports/issue-01
  done
  for f in *issue-02*.jpg *issue-02*.jpeg *issue-02*.png *i02*.jpg *i02*.png *issue2*.jpg *issue2*.png; do
    move_file "$f" art/exports/issue-02
  done
  # Any remaining jpg/png → put in issue-01 exports for now
  for f in *.jpg *.jpeg *.png; do move_file "$f" art/exports/issue-01; done

  # Source art
  for f in *issue-01*.psd *issue1*.psd *i01*.psd; do move_file "$f" art/pages/issue-01/src; done
  for f in *issue-02*.psd *issue2*.psd *i02*.psd; do move_file "$f" art/pages/issue-02/src; done
  for f in *issue-01*.clip *issue1*.clip *i01*.clip; do move_file "$f" art/pages/issue-01/src; done
  for f in *issue-02*.clip *issue2*.clip *i02*.clip; do move_file "$f" art/pages/issue-02/src; done

  # PDFs → production
  for f in *.pdf; do move_file "$f" production; done
}

main() {
  make_dirs
  setup_lfs
  move_rules

  if [[ $DRY_RUN -eq 1 ]]; then
    say "DRY-RUN complete. No changes written."
  else
    say "Staging changes…"
    git add -A || true
    if git status --porcelain | grep -q .; then
      git commit -m "Repo cleanup: structure + organized content"
      say "Committed cleanup."
    else
      say "No changes to commit."
    fi
  fi
}

main "$@"
