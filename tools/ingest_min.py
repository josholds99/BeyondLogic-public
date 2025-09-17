#!/usr/bin/env python3
# ingest_folder_runner.py — stable folder ingester (no zipfile)

import shutil, time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

# 👇 EDIT this line to point to your unzipped folder name in archives/
SRC_DIR = REPO_ROOT / "archives" / "BeyondLogic_Super_Baseline_2025-09-17_repo_ready"

# Map keywords to target repo folders
ROUTES = {
    "characters": ["collin","josh","everett","bailey","rebel","hero"],
    "environments": ["house","garage","field","hallway","kitchen","dining","bath","env_"],
    "storyboards": ["storyboard","thumb","page"],
    "assets/emblems": ["emblem"],
    "props": ["prop","device","gadget"],
}

def infer_category(name: str) -> str:
    n = name.lower()
    for cat, keys in ROUTES.items():
        if any(k in n for k in keys):
            return cat
    return "environments"  # fallback

def copy_into_repo(src_file: Path):
    cat = infer_category(src_file.name)
    dest = REPO_ROOT / cat / src_file.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src_file, dest)
    print(f"copy {src_file.name} -> {cat}/")

def main():
    if not SRC_DIR.exists():
        raise SystemExit(f"❌ Source folder not found: {SRC_DIR}")

    count = 0
    for f in SRC_DIR.rglob("*"):
        if f.is_file() and f.suffix.lower() in {".png",".jpg",".jpeg",".pdf",".md"}:
            copy_into_repo(f); count += 1

    log = REPO_ROOT/"docs"/"reports"/"CHANGELOG.md"
    log.parent.mkdir(parents=True, exist_ok=True)
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(log,"a",encoding="utf-8") as fh:
        fh.write(f"- {ts}: ingest_folder_runner copied {count} file(s) from {SRC_DIR.name}\n")

    print(f"✔ Ingest complete ({count} files).")

if __name__ == "__main__":
    main()
