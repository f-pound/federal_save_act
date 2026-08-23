#!/usr/bin/env python3
"""
fetch_opinions.py — download opinion text for every case in sources/source_manifest.json
that has a reporter citation, from the Caselaw Access Project static archive
(static.case.law), into inputs/opinions/<source_id>.txt.  Then
check_text_stability.py verifies every court-decided quote verbatim against it.

Reporters handled: U.S. (us), F.3d (f3d), F.2d (f2d), F. Supp. 3d (f-supp-3d).
Cases the archive does not carry (recent volumes) are reported, not failed.
"""
import json, re, sys, urllib.request
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "inputs" / "opinions"
REPORTERS = {"U.S.": "us", "F.3d": "f3d", "F.2d": "f2d", "F. Supp. 3d": "f-supp-3d"}

def cap_url(cite):
    m = re.search(r"(\d+)\s+(U\.S\.|F\.3d|F\.2d|F\. Supp\. 3d)\s+(\d+)", cite)
    if not m: return None
    vol, rep, page = m.group(1), REPORTERS[m.group(2)], int(m.group(3))
    return f"https://static.case.law/{rep}/{vol}/cases/{page:04d}-01.json"

def text_of(doc):
    body = doc.get("casebody", {})
    parts = []
    for op in body.get("opinions", []):
        parts.append(f"\n\n=== OPINION ({op.get('type','')}; author {op.get('author','')}) ===\n")
        parts.append(op.get("text", ""))
    return "".join(parts)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    man = json.loads((ROOT / "sources/source_manifest.json").read_text())
    got, missing = [], []
    for s in man["sources"]:
        if s.get("type") != "case": continue
        url = cap_url(s.get("citation", ""))
        if not url: missing.append((s["id"], "no reporter citation")); continue
        dst = OUT / f"{s['id']}.txt"
        if dst.exists() and "--refresh" not in sys.argv: got.append(s["id"]); continue
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "computational-amicus-pipeline/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r: doc = json.loads(r.read())
        except Exception as e:
            missing.append((s["id"], f"{url} -> {e}")); continue
        dst.write_text(f"SOURCE: {url}\nCASE: {doc.get('name_abbreviation','')} , {doc.get('decision_date','')}\n" + text_of(doc), encoding="utf-8")
        got.append(s["id"])
    print(f"opinions on disk: {', '.join(got)}")
    for sid, why in missing: print(f"  not available: {sid} — {why}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
