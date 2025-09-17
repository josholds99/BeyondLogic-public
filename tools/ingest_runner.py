from pathlib import Path, PurePath
import runpy, sys

REPO_ROOT = Path(__file__).resolve().parents[1]
INGEST    = REPO_ROOT / "tools" / "repo_ingest.py"

# Put the test ZIP anywhere in your repo (e.g., repo root) and point here:
SRC = REPO_ROOT / "ingest_smoke_test.zip"  # move the zip here or update this path

print(f"Repo root: {REPO_ROOT}")
print(f"Source zip: {SRC}")

if not SRC.exists():
    raise SystemExit(f"❌ Zip not found: {SRC}")

sys.argv = [INGEST.name, "--src", str(SRC), "--repo", str(REPO_ROOT), "--apply", "--overwrite", "--note", f"ingest {SRC.name} (smoke)"]
runpy.run_path(str(INGEST), run_name="__main__")
print("✔ Done")
