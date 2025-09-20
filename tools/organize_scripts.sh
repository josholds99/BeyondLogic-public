#!/bin/bash
set -euo pipefail
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1
say(){ echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
mk(){ [[ $DRY_RUN -eq 1 ]] && say "mkdir -p $1" || mkdir -p "$1"; }
gmove(){ src="$1"; dst="$2"; [[ -e "$src" ]] || return 0; mk "$(dirname "$dst")";
  if git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    [[ $DRY_RUN -eq 1 ]] && say "git mv '$src' '$dst'" || git mv "$src" "$dst"
  else
    [[ $DRY_RUN -eq 1 ]] && say "mv '$src' '$dst' && git add '$dst'" || { mv "$src" "$dst"; git add "$dst" || true; }
  fi
}
mk scripts; mk scripts/outlines; mk scripts/drafts; mk scripts/issue-01; mk scripts/issue-02
shopt -s nullglob
for f in *series*bible*.md *Series*Bible*.md; do gmove "$f" scripts/series-bible.md; done
for f in *issue*01*outline*.md *Issue*01*outline*.md; do gmove "$f" scripts/outlines/issue-01-outline.md; done
for f in *issue*02*outline*.md *Issue*02*outline*.md; do gmove "$f" scripts/outlines/issue-02-outline.md; done
for f in *issue*01*.md *Issue*01*.md; do [[ "$f" == *outline* ]] && continue; gmove "$f" scripts/drafts/issue-01-draft.md; done
for f in *issue*02*.md *Issue*02*.md; do [[ "$f" == *outline* ]] && continue; gmove "$f" scripts/drafts/issue-02-draft.md; done
for f in *.md *.txt *.docx; do [[ -e "$f" ]] || continue; case "$f" in scripts/*|tools/*) continue;; esac; gmove "$f" "scripts/drafts/$f"; done
say "Done organizing. Review with: git status"
