#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG (edit if needed) ======
# Watch the original folder you were using:
INBOX="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/BeyondLogic/incoming_zips"
REPO_DIR="/Users/joshuaporterolds/Projects/BeyondLogic"
PRIMARY_REMOTE="origin"
PRIMARY_BRANCH="main"
STAGING_BRANCH="staging"
MIRROR_REMOTE="mirror"   # optional; if not configured, mirror push is skipped
MIN_AGE_SECONDS=60       # debounce: only process files older than this
LOGFILE="${HOME}/sync_incoming_to_repo.log"
RSYNC_EXCLUDES=(--exclude ".git" --exclude ".DS_Store" --exclude "__MACOSX" --exclude "processed")

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }
log() { echo "$(timestamp) — $*" | tee -a "$LOGFILE"; }

ensure_dirs() {
  mkdir -p "${INBOX}"
  mkdir -p "${INBOX}/processed/zips"
  mkdir -p "${INBOX}/processed/files"
}

is_file_stable() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local now epoch age
  now=$(date +%s)
  epoch=$(stat -f %m "$f" 2>/dev/null || stat -t %s -f %m "$f" 2>/dev/null || echo "$now")
  age=$(( now - epoch ))
  [[ "$age" -ge "$MIN_AGE_SECONDS" ]]
}

process_zips() {
  shopt -s nullglob
  local processed_any=0
  for z in "${INBOX}"/*.zip; do
    if ! is_file_stable "$z"; then
      log "Skipping (too new): $z"
      continue
    fi
    log "Processing ZIP: $z"
    local TMPDIR
    TMPDIR=$(mktemp -d)
    unzip -q "$z" -d "$TMPDIR"
    rsync -av "${RSYNC_EXCLUDES[@]}" "$TMPDIR"/ "$REPO_DIR"/ >>"$LOGFILE" 2>&1
    rm -rf "$TMPDIR"
    mv "$z" "${INBOX}/processed/zips/"
    log "Moved ZIP to processed: $(basename "$z")"
    processed_any=1
  done
  return $processed_any
}

process_plain_files() {
  shopt -s nullglob
  local processed_any=0
  for f in "${INBOX}"/*; do
    [[ -f "$f" ]] || continue
    [[ "${f##*.}" != "zip" ]] || continue
    [[ "$(basename "$f")" == .* ]] && continue
    if ! is_file_stable "$f"; then
      log "Skipping (too new): $f"
      continue
    fi
    log "Copying file into repo: $(basename "$f")"
    rsync -av "${RSYNC_EXCLUDES[@]}" "$f" "$REPO_DIR"/ >>"$LOGFILE" 2>&1
    mv "$f" "${INBOX}/processed/files/"
    log "Moved file to processed: $(basename "$f")"
    processed_any=1
  done
  return $processed_any
}

git_commit_and_push() {
  cd "$REPO_DIR"
  git fetch "$PRIMARY_REMOTE" || true

  if ! git show-ref --verify --quiet "refs/heads/${STAGING_BRANCH}"; then
    log "Creating staging branch ${STAGING_BRANCH}"
    git checkout -b "$STAGING_BRANCH"
  else
    git checkout "$STAGING_BRANCH"
    git pull --rebase "$PRIMARY_REMOTE" "$STAGING_BRANCH" || true
  fi

  if git status --porcelain | grep -q .; then
    export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Auto Commit Bot}"
    export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-bot@local}"
    git add -A
    git commit -m "Auto: ingest from iCloud inbox at $(date +'%Y-%m-%d %H:%M:%S')"
    log "Committed changes on ${STAGING_BRANCH}"
  else
    log "No changes to commit"
  fi

  git push -u "$PRIMARY_REMOTE" "$STAGING_BRANCH"

  if git show-ref --verify --quiet "refs/heads/${PRIMARY_BRANCH}"; then
    git checkout "$PRIMARY_BRANCH"
  else
    git checkout -b "$PRIMARY_BRANCH"
  fi
  git pull --rebase "$PRIMARY_REMOTE" "$PRIMARY_BRANCH" || true

  if git merge --ff-only "$STAGING_BRANCH"; then
    log "Fast-forwarded ${PRIMARY_BRANCH} from ${STAGING_BRANCH}"
    git push "$PRIMARY_REMOTE" "$PRIMARY_BRANCH"
  else
    log "WARNING: Could not fast-forward ${PRIMARY_BRANCH}. Leaving changes on ${STAGING_BRANCH} only."
    git checkout "$STAGING_BRANCH"
  fi

  if git remote get-url "$MIRROR_REMOTE" >/dev/null 2>&1; then
    log "Pushing to mirror remote"
    git push "$MIRROR_REMOTE" "$STAGING_BRANCH" || true
    git push "$MIRROR_REMOTE" "$PRIMARY_BRANCH" || true
  else
    log "Mirror remote not configured; skipping mirror push"
  fi
}

main() {
  ensure_dirs
  log "Starting sync run"
  local changed=0
  process_zips && changed=1
  process_plain_files && changed=1

  if [[ "$changed" -eq 1 ]]; then
    git_commit_and_push
  else
    log "Nothing to sync"
  fi

  log "Done"
}

main "$@"
