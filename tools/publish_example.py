#!/usr/bin/env python3
"""publish_example.py EXAMPLE_DIR — copy an example project's built explorer into
web/examples/<name>/ so GitHub Pages serves it at /examples/<name>/."""
import shutil, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
src = Path(sys.argv[1]).resolve(); name = src.name
dst = ROOT / "web" / "examples" / name
if dst.exists(): shutil.rmtree(dst)
(dst / "data").mkdir(parents=True)
for f in ("index.html", "app.js", "style.css"): shutil.copy2(src / "web" / f, dst / f)
shutil.copy2(src / "web" / "data" / "explorer.json", dst / "data" / "explorer.json")
print(f"published {dst.relative_to(ROOT)}")
