<<<<<<< HEAD
=======

>>>>>>> 6c9b948 (Add cleanup script (prep))
#!/usr/bin/env bash
set -euo pipefail

# =======================
# Beyond Logic Repo Cleanup
<<<<<<< HEAD
# - Creates standard structure
# - Enables Git LFS for heavy assets
# - Moves files based on extension & simple name patterns
# - Supports --dry-run to preview actions
=======
>>>>>>> 6c9b948 (Add cleanup script (prep))
# =======================

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

<<<<<<< HEAD
# ---------- Helpers ----------
say() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# Move using git mv if tracked, else plain mv then git add later.
move_file() {
  local src="$1" dst_dir="$2"
  [[ -e "$src" ]] || return 0  # skip missing
  mkdir -p "$dst_dir"
  local base
  base="$(basename "$src")"

  if git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      say "DRY-RUN git mv '$src' '$dst_dir/$base'"
    else
      git mv "$src" "$dst_dir/$base"
    fi
  else
    if [[ $DRY_RUN -eq 1 ]]; then
      say "DRY-RUN mv '$src' '$dst_dir/$base' && git add '$dst_dir/$base'"
    else
      mv "$src" "$dst_dir/$base"
      git add "$dst_dir/$base" || true
      # Try to remove empty parent dirs
      rmdir -p "$(dirname "$src")" 2>/dev/null || true
    fi
  fi
}

move_glob() {
  local pattern="$1" dst_dir="$2"
  shopt -s nullglob
  # restrict search to repo (skip .git and tools/cleanup itself)
  while IFS= read -r -d '' f; do
    # skip .git and tools/launchd/ etc from moves unless they match on purpose
    [[ "$f" == ./.git/* ]] && continue
    [[ "$f" == ./tools/* ]] && continue
    move_file "$f" "$dst_dir"
  done < <(find . -type f -name "$pattern" -print0)
}

# ---------- Ensure structure ----------
say "Ensuring folder structure…"
dirs=(
  "docs"
  "scripts/issue-01" "scripts/issue-02"
  "art/characters" "art/environments"
  "art/pages/issue-01/src" "art/pages/issue-02/src"
  "art/exports/issue-01" "art/exports/issue-02"
  "design/hero-emblem" "design/brand"
  "references"
  "production"
  "tools/launchd"
)
for d in "${dirs[@]}"; do
  if [[ $DRY_RUN -eq 1 ]]; then
    say "DRY-RUN mkdir -p '$d'"
  else
    mkdir -p "$d"
  fi
done

# ---------- Git LFS setup ----------
say "Configuring Git LFS for big assets…"
if [[ $DRY_RUN -eq 1 ]]; then
  say "DRY-RUN git lfs install"
  say "DRY-RUN git lfs track '*.png' '*.jpg' '*.jpeg' '*.psd' '*.clip' '*.tif' '*.tiff' '*.pdf'"
else
  git lfs install || true
  git lfs track "*.png" "*.jpg" "*.jpeg" "*.psd" "*.clip" "*.tif" "*.tiff" "*.pdf" || true
  git add .gitattributes || true
fi

# ---------- .gitignore (append common ignores if missing) ----------
if [[ ! -f .gitignore ]] || ! grep -q "### beyond-logic ###" .gitignore; then
  say "Adding common .gitignore entries…"
  if [[ $DRY_RUN -eq 1 ]]; then
    say "DRY-RUN update .gitignore"
  else
    cat >> .gitignore <<'IGN'
### beyond-logic ###
.DS_Store
Thumbs.db
*.swp
*.tmp
*/cache/
*/temp/
__MACOSX/
IGN
    git add .gitignore || true
  fi
fi

# ---------- Move WRITING (scripts) ----------
# Heuristics: markdown/txt/docx -> scripts; split by issue if filename hints exist
say "Moving WRITING files to scripts/…"
# Issue 1 markers
move_glob "*issue*1*.*" "scripts/issue-01"
move_glob "*Issue*1*.*" "scripts/issue-01"
# Issue 2 markers
move_glob "*issue*2*.*" "scripts/issue-02"
move_glob "*Issue*2*.*" "scripts/issue-02"

# Generic script extensions (no issue hint) → scripts root for manual filing
move_glob "*.md"  "scripts"
move_glob "*.txt" "scripts"
move_glob "*.rtf" "scripts"
move_glob "*.docx" "scripts"

# ---------- Move ART exports (small shareables) ----------
say "Moving exported art to art/exports/…"
# Try to infer issue from names like issue-01, i01, i1, etc.
move_glob "*issue-01*.[jp][pn]g" "art/exports/issue-01"
move_glob "*i01*.[jp][pn]g"     "art/exports/issue-01"
move_glob "*issue1*.[jp][pn]g"  "art/exports/issue-01"

move_glob "*issue-02*.[jp][pn]g" "art/exports/issue-02"
move_glob "*i02*.[jp][pn]g"      "art/exports/issue-02"
move_glob "*issue2*.[jp][pn]g"   "art/exports/issue-02"

# Generic exports (no issue hint) → art/exports (choose 01 for now; you can relocate)
move_glob "*.[jp][pn]g" "art/exports/issue-01"

# ---------- Move ART source (PSDs/CLIP) ----------
say "Moving source art to art/pages/*/src…"
move_glob "*issue-01*.psd"  "art/pages/issue-01/src"
move_glob "*issue1*.psd"    "art/pages/issue-01/src"
move_glob "*i01*.psd"       "art/pages/issue-01/src"
move_glob "*issue-02*.psd"  "art/pages/issue-02/src"
move_glob "*issue2*.psd"    "art/pages/issue-02/src"
move_glob "*i02*.psd"       "art/pages/issue-02/src"

move_glob "*issue-01*.clip" "art/pages/issue-01/src"
move_glob "*issue1*.clip"   "art/pages/issue-01/src"
move_glob "*i01*.clip"      "art/pages/issue-01/src"
move_glob "*issue-02*.clip" "art/pages/issue-02/src"
move_glob "*issue2*.clip"   "art/pages/issue-02/src"
move_glob "*i02*.clip"      "art/pages/issue-02/src"

# ---------- Design & references ----------
say "Moving design/references…"
move_glob "*emblem*.*"       "design/hero-emblem"
move_glob "*logo*.*"         "design/brand"
move_glob "*reference*.*"    "references"
move_glob "*refs*.*"         "references"
move_glob "*mood*board*.*"   "references"

# ---------- Production PDFs ----------
say "Moving production PDFs…"
move_glob "*issue-01*.pdf" "production"
move_glob "*issue1*.pdf"   "production"
move_glob "*issue-02*.pdf" "production"
move_glob "*issue2*.pdf"   "production"

# ---------- Done ----------
if [[ $DRY_RUN -eq 1 ]]; then
  say "DRY-RUN complete. No changes were made."
  exit 0
fi

say "Staging changed files…"
git add -A

# Only commit if there are changes
if git status --porcelain | grep -q .; then
  git commit -m "Repo cleanup: structure, LFS, and organized content"
  say "Committed cleanup."
else
  say "No changes to commit."
fi

say "Tip: push to origin and mirror when ready:"
say "  git push origin main && git push mirror main"
=======
say() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# (…full script content from earlier message goes here…)

nano tools/cleanup_repo.sh
>>>>>>> 6c9b948 (Add cleanup script (prep))
