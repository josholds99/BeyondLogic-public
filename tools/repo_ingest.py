#!/usr/bin/env python3
"""
repo_ingest.py — ingest assets (zip or folder) into BeyondLogic repo structure,
update CHANGELOG.md, and refresh inventory.json if available.
"""
import argparse, os, sys, shutil, zipfile, tempfile, time
from pathlib import Path

CATEGORIES = {
    "characters": ["character", "collin", "josh", "everett", "bailey", "rebel", "hero"],
    "environments": ["environment", "house", "garage", "field", "hallway", "kitchen", "dining", "bath", "classroom", "cafeteria"],
    "props": ["prop", "emblem", "device", "gadget"],
    "storyboards": ["storyboard", "thumb", "thumbnail", "boards", "page"],
    "assets/emblems": ["emblem"],
}

def infer_category(path: Path) -> str | None:
    name = path.name.lower()
    for cat, keys in CATEGORIES.items():
        if any(k in name for k in keys):
            return cat
    return None

def copy_file(src: Path, dst: Path, apply: bool, overwrite: bool, actions: list[str]):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() and not overwrite:
        if dst.stat().st_mtime >= src.stat().st_mtime:
            actions.append(f"skip {dst}")
            return
    if apply:
        shutil.copy2(src, dst)
        actions.append(f"copy {src} -> {dst}")
    else:
        actions.append(f"[DRY] copy {src} -> {dst}")

def walk_and_ingest(src_root: Path, repo_root: Path, apply: bool, overwrite: bool, actions: list[str]):
    count = 0
    for f in src_root.rglob("*"):
        if not f.is_file():
            continue
        if f.suffix.lower() not in [".png",".jpg",".jpeg",".pdf",".md"]:
            continue
        cat = infer_category(f.relative_to(src_root)) or "environments"
        dst = repo_root / cat / f.name if "/" not in cat else repo_root / cat / f.name
        copy_file(f, dst, apply, overwrite, actions)
        count += 1
    return count

def update_changelog(repo_root: Path, note: str, apply: bool, actions: list[str]):
    path = repo_root/"docs"/"reports"/"CHANGELOG.md"
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    entry = f"- {ts}: {note}\n"
    if apply:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path,"a",encoding="utf-8") as f:
            f.write(entry)
        actions.append(f"CHANGELOG += {entry.strip()}")
    else:
        actions.append(f"[DRY] CHANGELOG += {entry.strip()}")

def run_inventory(repo_root: Path, apply: bool, actions: list[str]):
    tool = repo_root/"tools"/"inventory_report.py"
    if tool.exists() and apply:
        rc = os.system(f'python3 "{tool}"')
        actions.append("inventory_report.py run")
    else:
        actions.append("[SKIP] inventory_report.py")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--overwrite", action="store_true")
    ap.add_argument("--note", default="ingest assets")
    args = ap.parse_args()

    src = Path(args.src).expanduser().resolve()
    repo = Path(args.repo).expanduser().resolve()
    actions = []

    if src.suffix.lower() == ".zip":
        tmp = Path(tempfile.mkdtemp(prefix="ingest_"))
        with zipfile.ZipFile(src,"r") as z:
            z.extractall(tmp)
        src_root = tmp
    else:
        src_root = src

    count = walk_and_ingest(src_root, repo, args.apply, args.overwrite, actions)
    update_changelog(repo, f"{args.note} ({count} files)", args.apply, actions)
    run_inventory(repo, args.apply, actions)

    print("=== repo_ingest summary ===")
    for a in actions:
        print(" -",a)

if __name__=="__main__":
    main()
