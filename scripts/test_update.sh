#!/usr/bin/env bash
# test_update.sh
# Creates/updates a heartbeat file and pushes to a **new test branch** to verify GitHub permissions.
# Usage: bash scripts/test_update.sh /path/to/repo "Optional commit message"
set -euo pipefail

REPO="${1:?Provide path to your local repo}"
MESSAGE="${2:-Test update: heartbeat}"
cd "$REPO"

if [[ ! -d ".git" ]]; then
  echo "Error: $REPO is not a git repository"; exit 1
fi

git fetch --all --prune

STAMP="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
BRANCH="update-test/$(date -u +'%Y%m%d-%H%M%S')"

mkdir -p .automation
echo "heartbeat: $STAMP" >> .automation/heartbeat.txt

git checkout -b "$BRANCH"
git add .automation/heartbeat.txt
git commit -m "$MESSAGE ($STAMP)"
git push -u origin "$BRANCH"

echo "✅ Test branch pushed: $BRANCH"
echo "Visit your GitHub repo to confirm the new branch & commit."
