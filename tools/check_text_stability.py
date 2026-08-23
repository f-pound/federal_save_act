#!/usr/bin/env python3
"""
check_text_stability.py — Verify that every statutory clause the model relies
on is present, verbatim, in BOTH tracked bill texts:

  inputs/federal_save_act_bill_text.txt        H.R. 22 (EH, Apr. 10, 2025) — modeled text
  inputs/save_america_act_s1383_eah_text.txt   S. 1383 House amendment (Feb. 11, 2026) — current vehicle

Clauses checked:
  * every clause_trace.csv row whose source_id is hr22-eh (quoted clause_text)
  * every `text` field of category members / rules in data/parsed/*.json IRs
    whose source is the bill

A quote may contain "..." ellipses; each fragment of >= 25 characters must
appear after whitespace/quote normalisation.  Exit 1 if any fragment is
missing from either text.  This makes "the modeled § 2 text is unchanged in
the current vehicle" a machine-checked statement rather than an assertion.
"""
import csv, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Clauses KNOWN to differ between the two texts; reported, not failed.
KNOWN_DIFFS = {
    "trace:text-save-act-is-law": "short title: 'SAVE Act' (H.R. 22) vs 'SAVE America Act' (S. 1383 EAH) — not an operative change",
}
# Texts and the "must also appear in" relation come from pipeline.json when
# present ({"texts": {source_id: path}, "text_checks": {source_id: [ids...]}});
# the SAVE Act defaults are below.
_cfg = json.loads((ROOT / "pipeline.json").read_text()) if (ROOT / "pipeline.json").exists() else {}
TEXTS = {k: ROOT / v for k, v in _cfg.get("texts", {
    "hr22-eh":   "inputs/federal_save_act_bill_text.txt",
    "s1383-eah": "inputs/save_america_act_s1383_eah_text.txt",
}).items()}
TEXT_CHECKS = _cfg.get("text_checks", {"hr22-eh": ["hr22-eh", "s1383-eah"], "s1383-eah": ["s1383-eah"]})

def norm(s):
    s = s.replace("``", '"').replace("''", '"').replace("‘", "'").replace("’", "'")
    s = s.replace("“", '"').replace("”", '"').replace("—", "--").replace("–", "-").replace("`", "'")
    s = re.sub(r"\s+", " ", s)
    return s.strip().lower()

def fragments(q):
    q = norm(q)
    q = re.sub(r"\[[^\]]*\]", " ", q)          # drop editorial [brackets]
    q = re.sub(r"\s*--\s*interpretation:.*$", "", q)  # drop interpretation suffixes
    parts = re.split(r"\.\.\.|…", q)
    return [p.strip(' "\'.;,') for p in parts if len(p.strip()) >= 25]

def main():
    WHERE = {k: tuple(v) for k, v in TEXT_CHECKS.items()}
    corpus = {k: norm(v.read_text(encoding="utf-8", errors="replace")) for k, v in TEXTS.items()}
    # Opinion texts fetched by tools/fetch_opinions.py: court-decided quotes are
    # checked against them exactly as statutory quotes are checked against bills.
    for op in sorted((ROOT / "inputs" / "opinions").glob("*.txt")) if (ROOT / "inputs" / "opinions").exists() else []:
        corpus[op.stem] = norm(op.read_text(encoding="utf-8", errors="replace"))
        WHERE.setdefault(op.stem, (op.stem,))
    # Which texts a quote must appear in.  H.R. 22 clauses must survive into
    # the current vehicle; SAVE America Act-only clauses exist only there.
    checks = []
    rows = list(csv.DictReader(open(ROOT / "sources/clause_trace.csv", encoding="utf-8-sig")))
    for ir in sorted((ROOT / "data/parsed").glob("*.json")):
        try:
            d = json.loads(ir.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(d, dict) or d.get("source_id") not in WHERE or "_draft_" in ir.name:
            continue
        where = WHERE[d["source_id"]]
        for c in d.get("categories", []):
            for m in c["members"]:
                if m.get("text"):
                    checks.append((f"{ir.stem}:{m['symbol']}", m["text"], where))
        for r in d.get("rules", []):
            if r.get("text"):
                checks.append((f"{ir.stem}:{r['name']}", r["text"], where))
        for e in (d.get("process") or {}).get("edges", []):
            if e.get("text"):
                w = WHERE.get(e.get("source_id", d["source_id"]), where)
                checks.append((f"{ir.stem}:edge:{e['from']}--{e['event']}", e["text"], w))
    for row in rows:
        sid = row["source_id"]
        if sid in WHERE:
            # statutory quotes: all labels except pure interpretations are verbatim;
            # interpretation rows quote text then add "— interpretation: …" (stripped by fragments())
            checks.append((f"trace:{row['axiom_name']}", row["clause_text"], WHERE[sid]))
    n_case = sum(1 for name, q, w in checks if w and w[0] in [op.stem for op in (ROOT / "inputs" / "opinions").glob("*.txt")])
    errors = 0
    for name, quote, where in checks:
        for frag in fragments(quote):
            for k in where:
                text = corpus[k]
                if frag not in text:
                    if name in KNOWN_DIFFS:
                        print(f"KNOWN DIFF in {k}: [{name}] {KNOWN_DIFFS[name]}")
                        continue
                    errors += 1
                    print(f"MISSING in {k}: [{name}] \"{frag[:90]}\"")
    print(f"checked {len(checks)} quoted clauses against {len(corpus)} texts: {'PASS' if not errors else str(errors)+' missing'}")
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
