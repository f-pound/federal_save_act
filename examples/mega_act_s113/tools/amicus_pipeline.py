#!/usr/bin/env python3
"""
amicus_pipeline.py — the Computational Amicus Brief pipeline, as a CLI.

    sources  ──fetch──▶ inputs/*.txt + data/legislative_status.json
             ──extract──▶ data/parsed/<slug>_*_draft.json   (clause IR drafts, human review)
             ──compile──▶ model/*.lisp + ACE + docs/generated (clauses_to_acl2.py)
             ──certify──▶ all books (scripts/certify_books.sh)
             ──audit───▶ consistency + adversarial + trusted base
             ──hinges──▶ reports/hinges.md  (which premises the outcomes turn on)

Every stage is idempotent and leaves artifacts that CI re-checks.  Human
review points are explicit: `extract` writes DRAFTS with
requires_human_review=true; nothing drafted is compiled until a person
renames it.  Network stages fail soft and say what to fetch by hand.

Subcommands
  init NAME --title T                scaffold a new project directory from this one
  fetch bill  CONGRESS TYPE NUM [--version eh|ih|eas|...]
  fetch status CONGRESS TYPE NUM      -> data/legislative_status_<bill>.json (draft)
  fetch eo NUMBER                     Federal Register executive order text
  fetch case QUERY                    CourtListener search (COURTLISTENER_TOKEN)
  extract TEXTFILE --source-id ID     draft clause IRs from statutory text
  compile [--ace] [--validate-ace]    IR -> ACL2 / ACE / Markdown
  certify                             certify all books
  audit [--acl2]                      consistency + adversarial + trusted base
  hinges                              write reports/hinges.md
  all                                 compile -> certify -> audit -> hinges
"""
import argparse, json, os, re, subprocess, sys, urllib.request, urllib.parse, shutil, html
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UA = {"User-Agent": "computational-amicus-pipeline/1.0"}

def run(cmd, **kw):
    print("$", " ".join(cmd)); return subprocess.run(cmd, cwd=ROOT, **kw)

def get(url, timeout=60):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

# ------------------------------------------------------------------ fetch
def fetch_bill(args):
    t = args.type.lower(); v = args.version
    pkg = f"BILLS-{args.congress}{t}{args.number}{v}"
    url = f"https://www.govinfo.gov/content/pkg/{pkg}/html/{pkg}.htm"
    try:
        raw = get(url).decode("utf-8", "replace")
    except Exception as e:
        print(f"fetch failed ({e}); download manually: {url}"); return 1
    text = html.unescape(re.sub(r"<[^>]+>", "", raw))
    out = ROOT / "inputs" / f"{args.congress}{t}{args.number}_{v}_text.txt"
    out.parent.mkdir(exist_ok=True)
    out.write_text(f"SOURCE: {url}\nFETCHED BY: tools/amicus_pipeline.py fetch bill\n\n{text}", encoding="utf-8")
    print(f"wrote {out.relative_to(ROOT)} ({len(text)} chars)"); return 0

def fetch_status(args):
    import xml.etree.ElementTree as ET
    t = args.type.lower()
    url = f"https://www.govinfo.gov/bulkdata/BILLSTATUS/{args.congress}/{t}/BILLSTATUS-{args.congress}{t}{args.number}.xml"
    try:
        root = ET.fromstring(get(url))
    except Exception as e:
        print(f"fetch failed ({e}); download manually: {url}"); return 1
    b = root.find("bill")
    acts = sorted({(a.findtext("actionDate"), (a.findtext("text") or "")[:220]) for a in b.findall("actions/item")})
    votes = [a for a in acts if re.search(r"\d+ - \d+", a[1])]
    status = {"bill": f"{args.type.upper()}. {args.number} ({args.congress}th)", "title": b.findtext("title"),
              "latest_action": {"date": b.findtext("latestAction/actionDate"), "text": b.findtext("latestAction/text")},
              "recorded_votes": [{"date": d, "action": x} for d, x in votes],
              "text_versions": [tv.findtext("type") for tv in b.findall("textVersions/item")],
              "laws": [l.findtext("number") for l in b.findall("laws/item")],
              "draft": True, "note": "Draft from BILLSTATUS XML — review before copying into data/legislative_status.json"}
    out = ROOT / "data" / f"legislative_status_{args.congress}{t}{args.number}.json"
    out.write_text(json.dumps(status, indent=2) + "\n"); print(f"wrote {out.relative_to(ROOT)}: {status['latest_action']}"); return 0

def fetch_eo(args):
    url = f"https://www.federalregister.gov/api/v1/documents.json?conditions[presidential_document_type]=executive_order&conditions[term]=%22Executive%20Order%20{args.number}%22"
    try:
        data = json.loads(get(url))
    except Exception as e:
        print(f"fetch failed ({e}); search manually: https://www.federalregister.gov/presidential-documents/executive-orders"); return 1
    hits = [d for d in data.get("results", []) if str(d.get("executive_order_number")) == str(args.number)] or data.get("results", [])[:1]
    if not hits: print("no result"); return 1
    d = hits[0]
    txt = ""
    if d.get("raw_text_url"):
        try: txt = get(d["raw_text_url"]).decode("utf-8", "replace")
        except Exception: pass
    out = ROOT / "inputs" / f"eo_{args.number}.txt"
    out.write_text(f"SOURCE: {d.get('html_url')}\nCITATION: {d.get('citation')}\nTITLE: {d.get('title')}\nSIGNED: {d.get('signing_date')}\n\n{txt}", encoding="utf-8")
    print(f"wrote {out.relative_to(ROOT)}: {d.get('title')} ({d.get('citation')})"); return 0

def fetch_case(args):
    tok = os.environ.get("COURTLISTENER_TOKEN")
    if not tok:
        print("COURTLISTENER_TOKEN not set; get one at https://www.courtlistener.com/help/api/rest/ and retry, or add the case to sources/source_manifest.json by hand."); return 1
    q = urllib.parse.quote(args.query)
    req = urllib.request.Request(f"https://www.courtlistener.com/api/rest/v4/search/?q={q}&type=o", headers={**UA, "Authorization": f"Token {tok}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r: data = json.loads(r.read())
    except Exception as e:
        print(f"fetch failed ({e})"); return 1
    for res in data.get("results", [])[:5]:
        print(f"- {res.get('caseName')} | {res.get('citation')} | {res.get('dateFiled')} | https://www.courtlistener.com{res.get('absolute_url')}")
    return 0

# ---------------------------------------------------------------- extract
ENUM_RE = re.compile(r"(?:the\s+term|an?)\s+[`'\"]+(?P<term>.{3,90}?)['`\"]+\s+means(?P<lead>[^:]{0,200}?)(?:any\s+of\s+the\s+following|the\s+following):\s*(?P<body>(?:\s*[`'\"]*\(\d+\).*?)+?)(?=\n\s*[`'\"]*\([a-z]\)|\n\s*\([a-z]\) |\n\s*[`'\"]*\(\d+\)\s+[A-Z][a-z]+ [a-z]+\.--|\Z)", re.S | re.I)
ITEM_RE = re.compile(r"[`'\"]*\((\d+)\)\s+(.+?)(?=\s*[`'\"]*\(\d+\)\s|\Z)", re.S)
PROHIB_RE = re.compile(r"((?:[A-Z][^.]{0,160}?)\b(?:shall not|may not)\b[^.]{0,400}?\bunless\b[^.]{0,400}?\.)", re.S)
DUTY_RE = re.compile(r"((?:[A-Z][^.]{0,120}?)\bshall (?:remove|establish a process|submit|provide|notify|transmit)\b[^.]{0,400}?\.)", re.S)

def slug(s): return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:48]

def extract(args):
    text = Path(args.textfile).read_text(encoding="utf-8", errors="replace")
    flat = re.sub(r"[ \t]+", " ", text)
    sid = args.source_id
    drafts = {"book": f"{args.slug}_draft_rules", "title": f"DRAFT clause IR extracted from {Path(args.textfile).name} — REVIEW REQUIRED", "source_id": sid,
              "includes": ["lib/enum_list"], "categories": [], "rules": [], "requires_human_review": True,
              "review_notes": ["Every `text` below is a verbatim quote (check_text_stability.py will verify it).",
                               "Category structure (standalone vs paired items) must be decided by a human: the extractor lists items flat.",
                               "Prohibitions/duties are listed as candidate axioms with placeholder predicates; name the predicates and add them to core."]}
    for m in ENUM_RE.finditer(flat):
        term = re.sub(r"\s+", " ", m.group("term")).strip(); body = m.group("body")
        items = [(n, re.sub(r"\s+", " ", t).strip().rstrip(".") + ".") for n, t in ITEM_RE.findall(body)]
        if len(items) < 2: continue
        members, used = [], set()
        for n, t in items:
            sym = slug(t.split(",")[0].split(" that ")[0])[:40] or f"item-{n}"
            if sym in used: sym = f"{sym}-{n}"
            used.add(sym)
            members.append({"symbol": sym, "source": f"({n})", "text": t[:300], "ace_noun": "n:" + sym})
        drafts["categories"].append({"name": slug(term) + "-types", "source": f"{sid}: definition of '{term}'", "description": f"DRAFT: items enumerated in the definition of '{term}' — decide standalone vs paired structure by hand", "members": members})
        drafts["rules"].append({"name": slug(term) + "-bundlep", "args": ["docs"], "label": "DEFINED_TERM", "source": f"{sid}: definition of '{term}'",
                                "text": re.sub(r"\s+", " ", m.group(0)[:160]).strip(), "body": {"some-in": ["docs", slug(term) + "-types"]}})
    cands = []
    for m in PROHIB_RE.finditer(flat):
        cands.append(("PROHIBITION", re.sub(r"\s+", " ", m.group(1)).strip()))
    for m in DUTY_RE.finditer(flat):
        cands.append(("DUTY", re.sub(r"\s+", " ", m.group(1)).strip()))
    seen = set()
    for i, (label, q) in enumerate(cands):
        if q in seen: continue
        seen.add(q)
        drafts["rules"].append({"name": f"draft-{label.lower()}-{i+1}", "kind": "axiom", "args": ["p", "x"], "label": label, "source": sid, "text": q[:400],
                                "hyps": {"and": [{"pred": ["personp", "p"]}, {"pred": ["TODO-condition", "p", "x"]}]}, "concl": {"pred": ["TODO-consequence", "p", "x"]},
                                "requires_human_review": True})
    out = ROOT / "data" / "parsed" / f"{args.slug}_draft_rules.json"
    out.write_text(json.dumps(drafts, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {out.relative_to(ROOT)}: {len(drafts['categories'])} enumerated definitions, {len(drafts['rules'])} candidate rules (REVIEW REQUIRED)")
    return 0

# ---------------------------------------------------------------- compile / certify / audit / hinges
def ir_files():
    cfg = json.loads((ROOT / "pipeline.json").read_text()) if (ROOT / "pipeline.json").exists() else {}
    return [ROOT / p for p in cfg.get("irs", [])] or sorted(p for p in (ROOT / "data/parsed").glob("*.json") if "_draft_" not in p.name and p.name.endswith(("_rules.json", "_table.json")) and "explorer" not in p.name)

def compile_(args):
    flags = ["--english"] + (["--ace"] if args.ace else [])
    r = run([sys.executable, "tools/clauses_to_acl2.py", *[str(p) for p in ir_files()], *flags])
    if r.returncode: return r.returncode
    if args.validate_ace:
        return run([sys.executable, "tools/validate_ace_statements.py", "--fix"]).returncode
    return 0

def certify(args): return run(["./scripts/certify_books.sh"]).returncode

def audit(args):
    for cmd in ([sys.executable, "tools/gen_consistency_audit.py"], [sys.executable, "tools/print_axioms.py"],
                [sys.executable, "tools/adversarial_audit.py"] + (["--acl2"] if args.acl2 else [])):
        if run(cmd).returncode: return 1
    return 0

def hinges(args):
    aa = json.loads((ROOT / "reports/adversarial_audit.json").read_text())
    graph = json.loads((ROOT / "data/parsed/explorer_graph.json").read_text())
    nodes = {n["id"]: n for n in graph["nodes"]}; edges = graph["edges"]
    # downstream conclusions of each assumption node (support edges only)
    def downstream(nid, seen=None):
        seen = seen if seen is not None else set()
        for e in edges:
            if e["from"] == nid and e["relation"] not in ("contests", "negates") and e["to"] not in seen:
                seen.add(e["to"]); downstream(e["to"], seen)
        return seen
    md = ["# Hinges — which premises the outcomes turn on", "",
          "A *hinge* is a premise that (a) is coupled to another premise in the adversarial audit, or (b) sits upstream of a final conclusion on one party's path only. Generated by `tools/amicus_pipeline.py hinges`.", ""]
    md += ["## Coupled clusters (adversarial audit)", ""]
    for party, rs in aa.items():
        for r in rs:
            if r["verdict"] == "coupled":
                md.append(f"- **{party}**: `{r['axiom']}` ⇄ {', '.join('`'+b+'`' for b in r['breaks'])}")
    md += ["", "## Premises upstream of final conclusions", "", "| Premise | Decider-type | Conclusions it supports | Party |", "|---|---|---|---|"]
    for h in graph["hypotheticals"]:
        for cid in h["controls"]:
            n = nodes.get(cid)
            if not n: continue
            concl = sorted(x for x in downstream(cid) if nodes.get(x, {}).get("type") == "FINAL_CONCLUSION")
            md.append(f"| {h['label']} | {n.get('type','')} | {', '.join('`'+c+'`' for c in concl) or '—'} | {h['path']} |")
    (ROOT / "reports/hinges.md").write_text("\n".join(md) + "\n"); print("wrote reports/hinges.md"); return 0

def all_(args):
    for f in (compile_, certify, audit, hinges):
        if f(args): return 1
    return 0

# ---------------------------------------------------------------- init (scaffold)
SCAFFOLD_KEEP = ["model/lib", "tools", "scripts", "web/index.html", "web/app.js", "web/style.css", "docs/PIPELINE.md", "docs/AUDITS.md", "docs/AGENT.md", "tools/clause_ir_schema.json"]
# (.github/workflows/acl2-proofs.yml is copied only for a top-level project: see init)
def init(args):
    dst = Path(args.name).resolve()
    if dst.exists(): print(f"{dst} exists"); return 1
    for rel in SCAFFOLD_KEEP:
        src = ROOT / rel
        if not src.exists(): continue
        tgt = dst / rel
        if src.is_dir(): shutil.copytree(src, tgt, ignore=shutil.ignore_patterns('*.cert', '*.fasl', '*.port', '*.lx64fsl', '__pycache__', '*.log'))
        else: tgt.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(src, tgt)
    if not any(p.name == ".git" for p in dst.parents for p in [p]) and not (dst.parent / ".git").exists():
        shutil.copytree(ROOT / ".github", dst / ".github", ignore=shutil.ignore_patterns("*.log"))
    for d in ("inputs", "data/parsed", "model", "sources", "reports", "docs/generated"):
        (dst / d).mkdir(parents=True, exist_ok=True)
    slugname = slug(Path(args.name).name).replace("-", "_")
    (dst / "pipeline.json").write_text(json.dumps({"slug": slugname, "title": args.title, "irs": [], "bills": [], "notes": "List the clause-IR files to compile, in dependency order."}, indent=2) + "\n")
    (dst / "model" / f"{slugname}_core.lisp").write_text(f'(in-package "ACL2")\n\n;; {args.title} — neutral vocabulary.  Declare defstubs here; no defaxiom.\n')
    (dst / "sources" / "clause_trace.csv").write_text("axiom_name,file,label,decider,source_id,section,clause_text\n")
    (dst / "sources" / "source_manifest.json").write_text(json.dumps({"version": "1", "sources": []}, indent=2) + "\n")
    (dst / "data" / "audit_worlds.json").write_text(json.dumps({"persons": "'(person-a)", "registered": "'(person-a)", "common": {}, "theories": {}}, indent=2) + "\n")
    (dst / "data" / "parsed" / "explorer_graph.json").write_text(json.dumps({"layers": json.loads((ROOT / "data/parsed/explorer_graph.json").read_text())["layers"], "nodes": [], "edges": [], "hypotheticals": []}, indent=2) + "\n")
    (dst / "README.md").write_text(f"# {args.title}\n\nScaffolded from the Federal SAVE Act computational amicus brief. See docs/PIPELINE.md.\n")
    print(f"scaffolded {dst}\nnext: tools/amicus_pipeline.py fetch bill ...; extract ...; write core stubs; compile; certify; audit; hinges"); return 0

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("init"); p.add_argument("name"); p.add_argument("--title", required=True); p.set_defaults(fn=init)
    f = sub.add_parser("fetch"); fs = f.add_subparsers(dest="what", required=True)
    p = fs.add_parser("bill"); p.add_argument("congress"); p.add_argument("type"); p.add_argument("number"); p.add_argument("--version", default="ih"); p.set_defaults(fn=fetch_bill)
    p = fs.add_parser("status"); p.add_argument("congress"); p.add_argument("type"); p.add_argument("number"); p.set_defaults(fn=fetch_status)
    p = fs.add_parser("eo"); p.add_argument("number"); p.set_defaults(fn=fetch_eo)
    p = fs.add_parser("case"); p.add_argument("query"); p.set_defaults(fn=fetch_case)
    p = sub.add_parser("extract"); p.add_argument("textfile"); p.add_argument("--source-id", required=True); p.add_argument("--slug", default="draft"); p.set_defaults(fn=extract)
    p = sub.add_parser("compile"); p.add_argument("--ace", action="store_true"); p.add_argument("--validate-ace", action="store_true"); p.set_defaults(fn=compile_)
    p = sub.add_parser("certify"); p.set_defaults(fn=certify)
    p = sub.add_parser("audit"); p.add_argument("--acl2", action="store_true"); p.set_defaults(fn=audit)
    p = sub.add_parser("hinges"); p.set_defaults(fn=hinges)
    p = sub.add_parser("all"); p.add_argument("--ace", action="store_true"); p.add_argument("--validate-ace", action="store_true"); p.add_argument("--acl2", action="store_true"); p.set_defaults(fn=all_)
    a = ap.parse_args(); sys.exit(a.fn(a))

if __name__ == "__main__":
    main()
