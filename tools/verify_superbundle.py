#!/usr/bin/env python3
from pathlib import Path
import os, sys

REQUIRED = [
    "characters","environments","props","scripts","storyboards",
    "assets/emblems","docs/guardrails","docs/processes","docs/reports","tools"
]

def count_files(p: Path) -> int:
    n = 0
    for _,_,fs in os.walk(p):
        n += len(fs)
    return n

def looks_like_repo(root: Path) -> bool:
    # Minimal signals that we’re at the repo root
    return (root/"scripts").exists() or (root/"characters").exists() or (root/"environments").exists()

def find_repo_root() -> Path | None:
    # 1) try parent of this file (.../BeyondLogic/tools/ -> .../BeyondLogic)
    here = Path(__file__).resolve()
    parents = [here.parent, *here.parents]  # tools/, BeyondLogic/, ...
    for p in parents[:5]:
        cand = p if p.name != "tools" else p.parent
        if looks_like_repo(cand):
            return cand

    # 2) try current working directory and its parents
    cwd = Path.cwd()
    for p in [cwd, *cwd.parents][:5]:
        if looks_like_repo(p):
            return p

    return None

def main():
    repo = find_repo_root()
    if not repo:
        print("❌ Could not locate repo root. Tip: ensure this file is inside BeyondLogic/tools/ and run again.")
        print(f"cwd={Path.cwd()}")
        print(f"file={Path(__file__).resolve()}")
        sys.exit(1)

    print(f"🔎 Using repo root: {repo}")

    missing = [d for d in REQUIRED if not (repo/d).exists()]
    if missing:
        print("❌ Missing:", ", ".join(missing)); sys.exit(1)

    print("✅ Structure OK")
    for d in REQUIRED:
        p = repo/d
        print(f"{d}: {count_files(p)} files")

    issue1 = repo/"scripts/issue-01/issue-01.md"
    print("Issue 1:", "present" if issue1.exists() else "MISSING")
    sys.exit(0)

if __name__ == "__main__":
    main()
