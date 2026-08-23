#!/usr/bin/env python3
"""
certify.py — project-independent certification driver.

Discovers every book under model/ (including lib/), orders them by their
include-book graph, decides :defaxioms-okp from whether any defaxiom is in
the book's include closure, runs the generator / consistency pre-checks,
then certifies each book with the configured ACL2 runner.  Exit 1 on any
failure.  Used by scripts/certify_books.sh and by the agent harness.
"""
import json, os, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "model"

def books():
    info = {}
    for f in sorted(list(MODEL.glob("*.lisp")) + list(MODEL.glob("lib/*.lisp"))):
        name = f.relative_to(MODEL).with_suffix("").as_posix()
        src = re.sub(r";[^\n]*", "", f.read_text(encoding="utf-8", errors="replace"))
        info[name] = {"includes": re.findall(r'\(include-book\s+"([^"]+)"', src),
                      "has_axiom": bool(re.search(r"^\s*\(defaxiom\s", src, re.M))}
    return info

def topo(info):
    order, seen = [], set()
    def visit(b):
        if b in seen or b not in info: return
        seen.add(b)
        for i in info[b]["includes"]: visit(i)
        order.append(b)
    for b in sorted(info): visit(b)
    return order

def axiom_in_closure(b, info, memo):
    if b in memo: return memo[b]
    v = info.get(b, {}).get("has_axiom", False) or any(axiom_in_closure(i, info, memo) for i in info.get(b, {}).get("includes", []))
    memo[b] = v; return v

def runner():
    cmd = os.environ.get("ACL2_CMD")
    if cmd: return cmd.split()
    if shutil.which("acl2"): return ["acl2"]
    return ["docker", "compose", "run", "--rm", "-T", "acl2", "acl2"]

def prechecks():
    cfg = json.loads((ROOT / "pipeline.json").read_text()) if (ROOT / "pipeline.json").exists() else {}
    steps = []
    if cfg.get("irs"):
        steps.append([sys.executable, "tools/clauses_to_acl2.py", *cfg["irs"], "--check", "--english", "--ace"])
    if (ROOT / "tools/fetch_opinions.py").exists():
        steps.append([sys.executable, "tools/fetch_opinions.py"])
    steps.append([sys.executable, "tools/check_text_stability.py"])
    if (ROOT / "data/audit_worlds.json").exists() and json.loads((ROOT / "data/audit_worlds.json").read_text()).get("theories"):
        steps.append([sys.executable, "tools/gen_consistency_audit.py", "--check"])
        if (ROOT / "reports/adversarial_audit.json").exists():
            steps.append([sys.executable, "tools/adversarial_audit.py", "--check"])
    if (ROOT / "reports/trusted_base_by_book.json").exists():
        steps.append([sys.executable, "tools/print_axioms.py", "--check"])
    for s in steps:
        p = subprocess.run(s, cwd=ROOT, capture_output=True, text=True)
        tail = (p.stdout + p.stderr).strip().splitlines()[-1:] or [""]
        print(("  pre  " if p.returncode == 0 else "  PRE-FAIL ") + " ".join(Path(x).name if "/" in x else x for x in s[1:3]) + " — " + tail[0][:120])
        if p.returncode: return False
    return True

def main():
    only_pre = "--prechecks-only" in sys.argv
    if not prechecks(): return 1
    if only_pre: return 0
    info = books(); memo = {}
    logdir = ROOT / "logs/certify"; logdir.mkdir(parents=True, exist_ok=True)
    fails, qed_total = [], 0
    for b in topo(info):
        cert = MODEL / f"{b}.cert"
        if cert.exists(): cert.unlink()
        okp = axiom_in_closure(b, info, memo)
        form = f'(certify-book "model/{b}" ? {"nil :defaxioms-okp t" if okp else ""})\n'
        p = subprocess.run(runner(), input=form, cwd=ROOT, capture_output=True, text=True)
        log = logdir / f"{b.replace('/', '_')}.log"; log.write_text(p.stdout + p.stderr)
        qed = len(re.findall(r"^Q\.E\.D\.", p.stdout, re.M)); qed_total += qed
        ok = cert.exists()
        print(f"  {'CERT' if ok else 'FAIL'}  {b}  ({qed} Q.E.D.){'  (defaxioms-okp)' if okp else ''}{'' if ok else '  -> ' + str(log.relative_to(ROOT))}")
        if not ok: fails.append(b)
    print(f"\nCertified: {len(info) - len(fails)}  Failed: {len(fails)}  Q.E.D.: {qed_total}")
    if fails: print("FAILED BOOKS: " + ", ".join(fails))
    return 1 if fails else 0

if __name__ == "__main__":
    sys.exit(main())
