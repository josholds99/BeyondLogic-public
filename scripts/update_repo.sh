#!/usr/bin/env bash
# update_repo.sh
# Pull latest, optionally ingest ZIPs, organize repo, commit, and push.
# Usage:
#   bash scripts/update_repo.sh --repo "/path/to/repo" [--zips "/path/to/zips"] [--branch main] [--message "msg"]
set -euo pipefail

REPO=""
ZIPS=""
BRANCH="main"
MESSAGE="Repo update: unzip + organize + push"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)    REPO="${2:?}"; shift 2;;
    --zips)    ZIPS="${2}"; shift 2;;
    --branch)  BRANCH="${2}"; shift 2;;
    --message) MESSAGE="${2}"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$REPO" ]]; then
  echo "Error: --repo path required"; exit 1
fi

if [[ ! -d "$REPO/.git" ]]; then
  echo "Error: $REPO does not appear to be a git repo"; exit 1
fi

cd "$REPO"

# Ensure branch exists locally
git fetch --all --prune
if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
fi

# Pull latest
git pull --rebase || true

# Optional ZIP ingestion
if [[ -n "${ZIPS}" && -d "${ZIPS}" ]]; then
  echo "Ingesting ZIPs from: ${ZIPS}"
  bash "$(dirname "$0")/unzip_all.sh" "${ZIPS}" "$REPO/import_staging"
fi

# Organize repo
bash "$(dirname "$0")/organize_repo.sh" "$REPO"

# Stage, commit, push
git add -A
if ! git diff --cached --quiet; then
  git commit -m "$MESSAGE"
  git push origin "$BRANCH"
  echo "Pushed changes to $BRANCH."
else
  echo "No changes to commit."
fi
