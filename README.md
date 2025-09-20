# Beyond Repo Update Pack

This pack gives you **ready-to-run scripts** to test and perform repo updates on macOS/Linux.
All scripts are **POSIX shell (bash)**.

## Contents
- `scripts/test_update.sh` — creates/updates a heartbeat file and pushes a **test branch** to confirm Git permissions.
- `scripts/update_repo.sh` — pulls latest, optionally ingests ZIPs, organizes files, commits, and pushes to `main` (configurable).
- `scripts/unzip_all.sh` — batch-unzips archives from a folder and consolidates contents.
- `scripts/organize_repo.sh` — sorts common Beyond assets into a clean structure.
- `scripts/init_and_push.sh` — bootstraps a new repo and pushes it to GitHub.
- `.gitignore` — sane defaults for art/code projects.

## Quick Start (recommended test flow)
```bash
# 1) Unzip this pack, then make scripts executable:
chmod +x scripts/*.sh

# 2) Run a **dry test** that creates a commit on a new test branch:
#    (Replace /path/to/your/repo with your local repo path)
bash scripts/test_update.sh /path/to/your/repo "Test update from pack"
```

If that works (branch is created and visible on GitHub), your Git creds are good.
Then try a full update run:

```bash
# Optional: stage incoming ZIPs from a download folder
# (Skips if the folder has no .zip files)
bash scripts/update_repo.sh \
  --repo "/path/to/your/repo" \
  --zips "/path/to/Downloads/beyond_zips" \
  --branch main \  --message "Daily sync: unzip + organize"

# Or no ZIPs:
bash scripts/update_repo.sh --repo "/path/to/your/repo" --message "Organize + push"
```

### Notes
- If your remote uses SSH, make sure your SSH key is configured (`ssh -T git@github.com`).
- These scripts **won’t delete** your files; they move and commit changes. Review diffs before pushing if you’d like.
- Organization rules are conservative; they can be tuned in `organize_repo.sh`.
- macOS users: you can double-click `.command` wrappers if you want—ask and I’ll add them.

---

**Created:** 2025-09-20T01:46:58
