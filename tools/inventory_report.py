#!/usr/bin/env python3
import os, json, hashlib
from pathlib import Path

def sha256(path: Path):
    h = hashlib.sha256()
    with open(path,"rb") as f:
        for chunk in iter(lambda: f.read(1024*1024), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    root = Path(".").resolve()
    manifest=[]
    for base in ["characters","environments","props","scripts","storyboards","assets","docs","archives","drafts"]:
        p = root/base
        if not p.exists(): continue
        for f in p.rglob("*"):
            if f.is_file():
                manifest.append({"path": str(f.relative_to(root)), "size": f.stat().st_size, "sha256": sha256(f)})
    out = root/"docs"/"reports"/"inventory.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2))
    print(f"Wrote {out} with {len(manifest)} entries.")

if __name__=="__main__":
    main()
