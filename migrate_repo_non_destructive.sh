#!/usr/bin/env bash
set -euo pipefail

# Non-destructive repo normalization for BeyondLogic-public
# - Copies legacy files into normalized folders
# - Generates per-domain indexes
# - Adds a single GH Action to auto-update indexes on push
# - Does NOT delete or rename your originals

# --- sanity: must be run at repo root ---
if [ ! -d .git ]; then
  echo "ERROR: Not a git repo root. cd to your repo and re-run." >&2
  exit 1
fi

echo "==> Creating normalized folders (copy-only, non-destructive)…"
mkdir -p scripts/issue-01 storyboards/issue-01 characters canon_refs .github/workflows

copy_if_exists() {
  # $1=src_glob  $2=dst_dir  $3=normalize_page (true|false)
  shopt -s nullglob nocaseglob
  local any=0
  for src in $1; do
    [ -e "$src" ] || continue
    any=1
    local base="$(basename "$src")"
    local dst="$2/$base"
    # Normalize page-XX.md to two digits if requested
    if [ "$3" = "true" ]; then
      # Extract first number, pad to two digits
      num="$(echo "$base" | sed -E 's/[^0-9]*([0-9]+).*/\1/')" || num=""
      if [ -n "${num:-}" ]; then
        printf -v num2 "%02d" "$num"
        dst="$2/page-${num2}.md"
      fi
    fi
    # Only copy if destination doesn't exist or differs
    if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
      mkdir -p "$2"
      cp -f "$src" "$dst"
      git add "$dst" >/dev/null 2>&1 || true
      echo "Copied: $src  ->  $dst"
    fi
  done
  shopt -u nullglob nocaseglob
  return $any
}

echo "==> Copying scripts into scripts/issue-01/ (keeping originals)…"
copy_if_exists "scripts/page-*.md" "scripts/issue-01" true || true
copy_if_exists "scripts/Page-*.md" "scripts/issue-01" true || true
copy_if_exists "scripts/issue-01/page-*.md" "scripts/issue-01" false || true  # already normalized

echo "==> Copying storyboards into storyboards/issue-01/ (keeping originals)…"
copy_if_exists "storyboards/page-*.md" "storyboards/issue-01" true || true
copy_if_exists "storyboards/Page-*.md" "storyboards/issue-01" true || true
copy_if_exists "storyboards/issue-01/page-*.md" "storyboards/issue-01" false || true

echo "==> Copying character refs into characters/ (keeping originals)…"
# Accept common text formats
copy_if_exists "characters/*.md" "characters" false || true
copy_if_exists "Characters/*.md" "characters" false || true
copy_if_exists "characters/*.json" "characters" false || true
copy_if_exists "Characters/*.json" "characters" false || true

echo "==> Copying canon refs into canon_refs/ (keeping originals)…"
copy_if_exists "canon/*.md" "canon_refs" false || true
copy_if_exists "canon_refs/*.md" "canon_refs" false || true
copy_if_exists "Canon/*.md" "canon_refs" false || true

echo "==> Generating local indexes (scripts/_index.md, storyboards/_index.md, characters/_index.md, canon_refs/_index.md)…"
python3 - << 'PY'
import os, re, io

def build_index(root, title, is_pages=False):
    if not os.path.isdir(root): return None
    lines=[f"# {title}\n"]
    if is_pages:
        # Expect subfolders like issue-01 with page-XX.md
        for issue in sorted(d for d in os.listdir(root) if os.path.isdir(os.path.join(root,d)) and d.lower().startswith("issue-")):
            lines.append(f"\n## {issue.replace('-', ' ').title()}")
            ipath=os.path.join(root, issue)
            pages=[]
            for fn in os.listdir(ipath):
                if fn.lower().startswith("page-") and fn.lower().endswith(".md"):
                    m=re.search(r'(\d+)', fn)
                    num=int(m.group(1)) if m else 9999
                    pages.append((num, fn))
            for _, fn in sorted(pages):
                rel=f"{root}/{issue}/{fn}"
                label=fn.replace(".md","").replace("-"," ").title()
                # default to main for local index (Action will overwrite per-branch on push)
                url=f"https://raw.githubusercontent.com/josholds99/BeyondLogic-public/main/{rel}"
                lines.append(f"- {label} — {url}")
    else:
        # Flat list of files
        files=[fn for fn in os.listdir(root) if fn.lower().endswith((".md",".json")) and not fn.startswith("_index")]
        if files:
            for fn in sorted(files, key=str.lower):
                rel=f"{root}/{fn}"
                url=f"https://raw.githubusercontent.com/josholds99/BeyondLogic-public/main/{rel}"
                lines.append(f"- {fn} — {url}")
    return "\n".join(lines)+"\n"

indexes = [
    ("scripts", "Scripts Index", True),
    ("storyboards", "Storyboards Index", True),
    ("characters", "Characters Index", False),
    ("canon_refs", "Canon References Index", False),
]
for root, title, is_pages in indexes:
    content = build_index(root, title, is_pages)
    if content:
        with open(os.path.join(root, "_index.md"), "w", encoding="utf-8") as f:
            f.write(content)
PY

git add scripts/_index.md storyboards/_index.md characters/_index.md canon_refs/_index.md >/dev/null 2>&1 || true

echo "==> Adding a single GitHub Action to auto-update all indexes on push to main/staging…"
cat > .github/workflows/build-indexes.yml <<'YAML'
name: Build Content Indexes
on:
  push:
    branches: [ main, staging ]
    paths:
      - 'scripts/**'
      - 'storyboards/**'
      - 'characters/**'
      - 'canon_refs/**'
  workflow_dispatch:

jobs:
  build-indexes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate indexes
        run: |
          python3 - << 'PY'
import os, re

def raw(branch, rel): return f'https://raw.githubusercontent.com/josholds99/BeyondLogic-public/{branch}/{rel}'
branch=os.environ.get('GITHUB_REF_NAME','main')

def write_index(root, title, is_pages=False):
    if not os.path.isdir(root): return
    lines=[f"# {title}\n"]
    if is_pages:
        for issue in sorted(d for d in os.listdir(root) if os.path.isdir(os.path.join(root,d)) and d.lower().startswith('issue-')):
            lines.append(f"\n## {issue.replace('-',' ').title()}")
            ip=os.path.join(root, issue)
            pages=[]
            for fn in os.listdir(ip):
                if fn.lower().startswith('page-') and fn.lower().endswith('.md'):
                    m=re.search(r'(\\d+)', fn); n=int(m.group(1)) if m else 9999
                    pages.append((n, fn))
            for _, fn in sorted(pages):
                rel=f"{root}/{issue}/{fn}"
                pretty=fn.replace('.md','').replace('-',' ').title()
                lines.append(f"- {pretty} — {raw(branch, rel)}")
    else:
        files=[fn for fn in os.listdir(root) if fn.lower().endswith(('.md','.json')) and not fn.startswith('_index')]
        for fn in sorted(files, key=str.lower):
            rel=f"{root}/{fn}"
            lines.append(f"- {fn} — {raw(branch, rel)}")
    with open(os.path.join(root, "_index.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines)+"\n")

write_index("scripts", "Scripts Index", True)
write_index("storyboards", "Storyboards Index", True)
write_index("characters", "Characters Index", False)
write_index("canon_refs", "Canon References Index", False)
PY
      - name: Commit updated indexes
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            git config user.name "repo-bot"
            git config user.email "repo-bot@users.noreply.github.com"
            git add scripts/_index.md storyboards/_index.md characters/_index.md canon_refs/_index.md
            git commit -m "chore: auto-update indexes"
            git push
          else
            echo "No index changes."
          fi
YAML

git add .github/workflows/build-indexes.yml >/dev/null 2>&1 || true

echo "==> Committing non-destructive migration changes…"
git commit -m "chore(repo): non-destructive normalization + auto indexes (scripts/storyboards/characters/canon_refs)" || echo "Nothing to commit."

echo
echo "✅ Done. Now run:  git push"
echo "After push, GH Action will maintain _index.md files for main & staging."
