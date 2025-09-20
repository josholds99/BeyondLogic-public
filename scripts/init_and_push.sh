#!/usr/bin/env bash
# init_and_push.sh
# Usage: bash scripts/init_and_push.sh /path/to/repo your-github-username/new-repo
set -euo pipefail
ROOT="${1:-$PWD}"
REMOTE_REPO="${2:?Provide user/repo}"
cd "$ROOT"

if [ ! -d ".git" ]; then
  git init
fi

git branch -M main || true
git add .
git commit -m "Initial import: Beyond project structure" || true

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "https://github.com/$REMOTE_REPO.git"
fi

git push -u origin main
