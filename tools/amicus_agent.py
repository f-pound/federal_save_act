#!/usr/bin/env python3
"""
amicus_agent.py — point it at a legal issue; get a certified, audited brief.

An agent harness in the shape Vero (arXiv:2608.13522) found to work: every
stage is  draft (model) → verify (mechanical oracle) → repair (model, with
the oracle's output)  until the oracle is green or the repair budget is
spent.  The oracles are this repository's CI checks, so nothing the model
writes is trusted until ACL2, APE, the text-stability checker, the trace
validator and the two audits have accepted it.

    python tools/amicus_agent.py run  --issue "H.R. 7300, 119th Congress (MEGA Act)" --project ../mega_act
    python tools/amicus_agent.py run  ... --dry-run RUNDIR     # replay recorded stage outputs (no API)
    python tools/amicus_agent.py run  ... --record RUNDIR      # save live outputs for later replay

Stages (each with its oracle):
  1 sources   model proposes bill ids / case citations / EOs  → fetched via amicus_pipeline (must succeed)
  2 ir        model writes clause-IR JSON per tools/clause_ir_schema.json → compile + text stability + APE strict
  3 core      model writes <slug>_core.lisp (stubs, conflict condition, pivot lemmas) → certify; neutrality lint
  4 parties   two adversarial drafts (challenger, government) + shared scenario + hinges + trace rows + audit worlds
              → certify; validate_trace (every axiom sourced + decider-tagged); consistency audit; adversarial audit
  5 graph     deterministic: explorer graph from the books, trace CSV and audits (no model)

What stays human: naming the issue; owning the conflict condition (stage 3 output is shown for sign-off
unless --no-signoff); the memo goes out under a person's name.
"""
import argparse, json, os, re, shutil, subprocess, sys, textwrap
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATE_ROOT = HERE.parent
MODEL = "claude-opus-5"

# ------------------------------------------------------------------ model
class Model:
    """Thin wrapper: structured JSON via output_config, streaming, adaptive thinking."""
    def __init__(self, record_dir=None):
        import anthropic
        self.client = anthropic.Anthropic()
        self.record_dir = Path(record_dir) if record_dir else None
        self.n = 0

    def ask(self, stage, system, user, schema, effort="high", max_tokens=64000):
        self.n += 1
        with self.client.messages.stream(
            model=MODEL, max_tokens=max_tokens,
            system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
            messages=[{"role": "user", "content": user}],
            thinking={"type": "adaptive"},
            output_config={"effort": effort, "format": {"type": "json_schema", "schema": schema}},
        ) as stream:
            msg = stream.get_final_message()
        if msg.stop_reason == "refusal":
            raise RuntimeError(f"model refused stage {stage}: {getattr(msg, 'stop_details', None)}")
        text = next(b.text for b in msg.content if b.type == "text")
        data = json.loads(text)
        if self.record_dir:
            self.record_dir.mkdir(parents=True, exist_ok=True)
            (self.record_dir / f"{self.n:02d}_{stage}.json").write_text(json.dumps({"system": system, "user": user, "output": data}, indent=2))
        return data

class ReplayModel:
    """Replays recorded outputs in order — for tests and for runs authored by hand."""
    def __init__(self, run_dir):
        self.files = sorted(Path(run_dir).glob("*.json")); self.i = 0
    def ask(self, stage, system, user, schema, **kw):
        while self.i < len(self.files):
            f = self.files[self.i]; self.i += 1
            if stage in f.stem.split("_"):
                self.last = json.loads(f.read_text())["output"]; return self.last
        raise RuntimeError(f"no recorded output for stage {stage} (repair attempts need a live model)")

# ---------------------------------------------------------------- oracles
def sh(cmd, cwd, timeout=1800):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    return p.returncode, (p.stdout + p.stderr)[-6000:]

def oracle_ir(project):
    irs = json.loads((project / "pipeline.json").read_text())["irs"]
    rc, out = sh([sys.executable, "tools/clauses_to_acl2.py", *irs, "--english", "--ace"], project)
    if rc: return False, out
    rc2, out2 = sh([sys.executable, "tools/check_text_stability.py"], project)
    rc3, out3 = sh([sys.executable, "tools/validate_ace_statements.py", "--fix"], project, timeout=900)
    ok = rc2 == 0 and rc3 == 0 and "Failed:   0" in out3
    return ok, out + out2 + out3

def oracle_certify(project):
    rc, out = sh([sys.executable, "tools/certify.py"], project, timeout=3600)
    return rc == 0, out

def oracle_parties(project):
    ok1, o1 = oracle_certify(project)
    rc2, o2 = sh([sys.executable, "tools/validate_trace.py"], project)
    rc3, o3 = sh([sys.executable, "tools/gen_consistency_audit.py"], project)
    rc4, o4 = sh([sys.executable, "tools/adversarial_audit.py"], project, timeout=3600)
    return ok1 and rc2 == 0 and rc3 == 0 and rc4 == 0, o1 + o2 + o3 + o4

# ----------------------------------------------------------------- stages
def read(p): return Path(p).read_text(encoding="utf-8")

def stage_sources(model, project, issue):
    schema = {"type": "object", "additionalProperties": False, "required": ["bills", "cases", "executive_orders", "summary"],
              "properties": {"summary": {"type": "string"},
                             "bills": {"type": "array", "items": {"type": "object", "additionalProperties": False, "required": ["congress", "type", "number", "version", "why"],
                                       "properties": {"congress": {"type": "integer"}, "type": {"type": "string"}, "number": {"type": "integer"}, "version": {"type": "string"}, "why": {"type": "string"}}}},
                             "cases": {"type": "array", "items": {"type": "object", "additionalProperties": False, "required": ["name", "citation", "proposition"],
                                       "properties": {"name": {"type": "string"}, "citation": {"type": "string"}, "proposition": {"type": "string"}}}},
                             "executive_orders": {"type": "array", "items": {"type": "integer"}}}}
    out = model.ask("sources", "You are the research stage of a computational-amicus pipeline. Identify the primary legal documents for the issue: the bill(s) and the text version to model (prefer the latest engrossed/enrolled text), the controlling or competing cases each side would cite (with the proposition each supports), and any executive orders. Cite only documents you are confident exist; the fetch stage will verify.", f"Issue: {issue}", schema)
    fetched = []
    for b in out["bills"]:
        rc, o = sh([sys.executable, "tools/amicus_pipeline.py", "fetch", "bill", str(b["congress"]), b["type"], str(b["number"]), "--version", b["version"]], project, timeout=120)
        fetched.append((b, rc == 0, o.strip().splitlines()[-1] if o.strip() else ""))
        sh([sys.executable, "tools/amicus_pipeline.py", "fetch", "status", str(b["congress"]), b["type"], str(b["number"])], project, timeout=120)
    for eo in out["executive_orders"]:
        sh([sys.executable, "tools/amicus_pipeline.py", "fetch", "eo", str(eo)], project, timeout=120)
    cfg = json.loads((project / "pipeline.json").read_text())
    cfg.setdefault("texts", {}); cfg.setdefault("text_checks", {})
    for b, ok, _ in fetched:
        if ok:
            sid = f"{b['type'].lower()}{b['number']}-{b['version']}"
            cfg["texts"][sid] = f"inputs/{b['congress']}{b['type'].lower()}{b['number']}_{b['version']}_text.txt"
            cfg["text_checks"][sid] = [sid]
    (project / "pipeline.json").write_text(json.dumps(cfg, indent=2) + "\n")
    (project / "sources" / "proposed_sources.json").write_text(json.dumps(out, indent=2))
    return out, fetched

def stage_ir(model, project, slug, texts, feedback=""):
    schema = {"type": "object", "additionalProperties": False, "required": ["files"],
              "properties": {"files": {"type": "array", "items": {"type": "object", "additionalProperties": False, "required": ["name", "ir"],
                             "properties": {"name": {"type": "string"}, "ir": {"type": "object"}}}}}}
    system = ("You write clause-IR files for a statute, following the JSON schema and the worked example exactly. Every `text` field must be a VERBATIM quote from the statute text (fragments separated by ' ... ', editorial notes in [brackets]); "
              "a checker rejects anything that is not. Produce: one enumeration/rules file per defined term that the statute enumerates; one text_rules file with each operative prohibition or duty as a `kind: axiom` rule with `atoms` carrying ACE phrases "
              "(subject-verb-object, n:compound-nouns, 'a X ... the X' anaphora); one process_table file per lifecycle the statute describes (states, events, edges with citations). Use only predicates you also declare in `atoms`. Decide paired structures ('only if presented together with') explicitly as and/or trees.")
    example = read(TEMPLATE_ROOT / "data/parsed/federal_save_act_document_rules.json") + "\n\n" + read(TEMPLATE_ROOT / "data/parsed/federal_save_act_text_rules.json")
    user = (f"SCHEMA:\n{read(TEMPLATE_ROOT / 'tools/clause_ir_schema.json')}\n\nWORKED EXAMPLE (SAVE Act):\n{example}\n\nSTATUTE TEXT (slug={slug}):\n" + "\n\n".join(texts) + (f"\n\nORACLE FEEDBACK FROM PREVIOUS ATTEMPT — fix these:\n{feedback}" if feedback else ""))
    out = model.ask("ir", system, user, schema)
    names = []
    for f in out["files"]:
        p = project / "data/parsed" / f["name"]
        p.write_text(json.dumps(f["ir"], indent=2, ensure_ascii=False) + "\n", encoding="utf-8"); names.append(f"data/parsed/{f['name']}")
    cfg = json.loads((project / "pipeline.json").read_text()); cfg["irs"] = names; (project / "pipeline.json").write_text(json.dumps(cfg, indent=2) + "\n")
    return out

def stage_core(model, project, slug, feedback=""):
    schema = {"type": "object", "additionalProperties": False, "required": ["core_lisp", "conflict_condition_rationale"],
              "properties": {"core_lisp": {"type": "string"}, "conflict_condition_rationale": {"type": "string"}}}
    system = "You write the neutral core book of a computational amicus brief in ACL2: defstub vocabulary (no axioms), factored intermediate defuns, one or more conflict conditions of the form (and <law> <qualified person> <protected right> <transaction> <statutory denial> (not (valid-regulationp law obj))), and the two pivot lemmas per condition. Follow the worked example's style exactly. No defaxiom, no skip-proofs."
    user = f"WORKED EXAMPLE:\n{read(TEMPLATE_ROOT / 'model/federal_save_act_core.lisp')}\n\nGENERATED BOOKS FOR THIS STATUTE (reference their predicates):\n" + "\n\n".join(read(p) for p in sorted((project / 'model').glob(f'{slug}_*.lisp'))) + (f"\n\nORACLE FEEDBACK:\n{feedback}" if feedback else "")
    out = model.ask("core", system, user, schema)
    (project / "model" / f"{slug}_core.lisp").write_text(out["core_lisp"])
    return out

def stage_parties(model, project, slug, feedback=""):
    schema = {"type": "object", "additionalProperties": False, "required": ["books", "trace_rows", "audit_worlds", "sources"],
              "properties": {"books": {"type": "array", "items": {"type": "object", "additionalProperties": False, "required": ["name", "lisp"], "properties": {"name": {"type": "string"}, "lisp": {"type": "string"}}}},
                             "trace_rows": {"type": "array", "items": {"type": "object", "additionalProperties": False, "required": ["axiom_name", "file", "label", "decider", "source_id", "section", "clause_text"],
                                            "properties": {k: {"type": "string"} for k in ["axiom_name", "file", "label", "decider", "source_id", "section", "clause_text"]}}},
                             "audit_worlds": {"type": "object"},
                             "sources": {"type": "array", "items": {"type": "object", "additionalProperties": False, "required": ["id", "title", "citation", "url", "type"], "properties": {k: {"type": "string"} for k in ["id", "title", "citation", "url", "type"]}}}}}
    system = ("You write, for a computational amicus brief, the shared scenario book, the hinge books (one per competing reading of the statute's pivotal phrase), the challenger model and the government model, exactly in the worked example's architecture: "
              "encapsulate with local witnesses for interpretive rules; defaxiom for bridges and scenario facts; every defaxiom gets a trace row with a decider (legislature|court|fact-finder|party-stipulation) and a source id; "
              "narrow every bridge to the object it concerns. Also produce data/audit_worlds.json: a toy world per party in which every defstub has a membership-test definition over the scenario constants. Use only predicates declared in core or the generated books. Draft the two parties as adversaries: each theory must be complete and valid on its own premises.")
    ex = "\n\n".join(read(TEMPLATE_ROOT / f"model/{b}.lisp") for b in ["federal_save_act_scenario", "federal_save_act_hinge_common", "federal_save_act_hinge_mandatory", "federal_save_act_hinge_discretionary", "federal_save_act_challenger_model", "federal_save_act_government_model"])
    user = (f"WORKED EXAMPLE BOOKS:\n{ex}\n\nWORKED EXAMPLE audit_worlds.json:\n{read(TEMPLATE_ROOT / 'data/audit_worlds.json')}\n\nTHIS STATUTE — core and generated books:\n" +
            "\n\n".join(read(p) for p in sorted((project / 'model').glob(f'{slug}_*.lisp'))) + f"\n\nPROPOSED SOURCES:\n{read(project / 'sources/proposed_sources.json')}" + (f"\n\nORACLE FEEDBACK:\n{feedback}" if feedback else ""))
    out = model.ask("parties", system, user, schema)
    for b in out["books"]:
        (project / "model" / b["name"]).write_text(b["lisp"])
    import csv
    with open(project / "sources/clause_trace.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["axiom_name", "file", "label", "decider", "source_id", "section", "clause_text"]); w.writeheader(); w.writerows(out["trace_rows"])
    man = json.loads((project / "sources/source_manifest.json").read_text()); seen = {s["id"] for s in man["sources"]}
    man["sources"] += [s for s in out["sources"] if s["id"] not in seen]
    (project / "sources/source_manifest.json").write_text(json.dumps(man, indent=2) + "\n")
    (project / "data/audit_worlds.json").write_text(json.dumps(out["audit_worlds"], indent=2) + "\n")
    return out

def stage_graph(project, slug):
    """Deterministic explorer graph from books + trace + manifest — no model.
    Layers: sources → formalization (axioms) → executable (generated tables,
    invariant books) → theorems (party final theorems, neutral theorems) →
    conclusions (one per party)."""
    import csv, re as _re
    sys.path.insert(0, str(project / "tools"))
    import certify as C
    info = {}
    for f in sorted(list((project / "model").glob("*.lisp")) + list((project / "model").glob("lib/*.lisp"))):
        name = f.relative_to(project / "model").with_suffix("").as_posix()
        src = _re.sub(r";[^\n]*", "", f.read_text(encoding="utf-8", errors="replace"))
        info[name] = {"includes": _re.findall(r'\(include-book\s+"([^"]+)"', src),
                      "theorems": _re.findall(r'^\s*\(defthm\s+([\w\-]+)', src, _re.M),
                      "has_axiom": bool(_re.search(r"^\s*\(defaxiom\s", src, _re.M))}
    def closure(b, seen=None):
        seen = set() if seen is None else seen
        if b in seen or b not in info: return seen
        seen.add(b); [closure(i, seen) for i in info[b]["includes"]]; return seen
    party_books = {p: f"{slug}_{p}_model" for p in ("challenger", "government")}
    closures = {p: closure(b) for p, b in party_books.items()}
    def path_of_book(book):
        inC, inG = book in closures["challenger"], book in closures["government"]
        return "neutral" if (inC and inG) or (not inC and not inG) else ("challenger" if inC else "government")
    rows = list(csv.DictReader(open(project / "sources/clause_trace.csv", encoding="utf-8-sig")))
    manifest = json.loads((project / "sources/source_manifest.json").read_text())
    layers = json.loads((TEMPLATE_ROOT / "data/parsed/explorer_graph.json").read_text())["layers"]
    nodes, edges, hyps = [], [], []
    def node(**k): nodes.append(k)
    def edge(f, t, rel, path="neutral"): edges.append({"from": f, "to": t, "relation": rel, "path": path})
    # sources
    used_sources = {r["source_id"] for r in rows if r["source_id"] != "n/a"}
    for srcd in manifest.get("sources", []):
        if srcd["id"] in used_sources:
            node(id="src-" + srcd["id"], type="LEGAL_SOURCE", layer="sources", label=srcd["title"], description=srcd.get("citation", ""), source_ref=srcd.get("citation", ""), path="neutral")
    # conclusions
    for party in ("challenger", "government"):
        node(id=f"concl-{party}", type="FINAL_CONCLUSION", layer="conclusions", label=f"{party.capitalize()}: conditional conclusion",
             description=f"Proved under the {party}'s premises; see the final theorem in {party_books[party]}.lisp.", book=f"{party_books[party]}.lisp", path=party)
    # axioms
    axiom_book = {}
    for b, inf in info.items():
        src = (project / "model" / f"{b}.lisp").read_text(encoding="utf-8", errors="replace")
        for a in _re.findall(r'^\s*\(defaxiom\s+([\w\-]+)', src, _re.M): axiom_book[a] = b
        # encapsulate-exported constraints are traced too (interpretive rules)
        for a in _re.findall(r'^\s+\(defthm\s+([\w\-]+)', src, _re.M): axiom_book.setdefault(a, b)
    for r in rows:
        book = axiom_book.get(r["axiom_name"]); 
        if not book: continue
        nid = "ax-" + r["axiom_name"]; path = path_of_book(book)
        typ = {"SCENARIO_FACT": "SCENARIO_FACT", "EMPIRICAL_ASSUMPTION": "EMPIRICAL_ASSUMPTION", "BRIDGE_RULE": "BRIDGE_RULE", "TEXT_FACT": "TEXT_FACT", "PROHIBITION": "TEXT_FACT", "PROCEDURAL_FACT": "TEXT_FACT", "INTERPRETIVE_ASSUMPTION": "INTERPRETIVE_ASSUMPTION"}.get(r["label"], "DOCTRINAL_ASSUMPTION")
        node(id=nid, type=typ, layer="formalization", label=r["axiom_name"].replace("-", " "), description=r["clause_text"][:300], acl2_event=r["axiom_name"], book=f"{book}.lisp",
             source_ref=f"{r['source_id']} {r['section']}".strip(), trusted_base=True, path=path, high_risk=r["label"] == "EMPIRICAL_ASSUMPTION")
        if r["source_id"] != "n/a": edge("src-" + r["source_id"], nid, "source_traces", path)
        for party in (("challenger", "government") if path == "neutral" else (path,)):
            edge(nid, f"concl-{party}", f"supports_{party}", party)
        if r["decider"] in ("court", "fact-finder") and path != "neutral":
            hyps.append({"id": "hyp-" + r["axiom_name"], "category": f"{path.capitalize()} premises — {r['decider']}", "label": r["axiom_name"].replace("-", " "), "default": True, "controls": [nid], "path": path})
    # executable + neutral theorems
    for b, inf in info.items():
        if b.startswith("lib/") or b in party_books.values(): continue
        if inf["has_axiom"] and not b.endswith("_text_rules"): continue
        if not inf["theorems"] and not b.endswith("_table"): continue
        mid = "model-" + b
        node(id=mid, type="PROCESS_MODEL" if "table" in b or "invariants" in b else "DOCUMENT_MODEL", layer="executable",
             label=b.replace(slug + "_", "").replace("_", " "), description=f"{len(inf['theorems'])} theorems; trusted base from its include closure.", book=f"{b}.lisp", path="neutral")
        for inc in inf["includes"]:
            if inc in info and not inc.startswith("lib/") and ("model-" + inc) not in {n["id"] for n in nodes}:
                pass
            if inc in info and (inc.endswith("_table") or inc.endswith("_rules")) and not inc.endswith("_text_rules"):
                edge("model-" + inc, mid, "supports")
        for t in inf["theorems"][:6]:
            tid = "thm-" + t
            node(id=tid, type="THEOREM", layer="theorems", label=t.replace("-", " "), acl2_event=t, book=f"{b}.lisp", axiom_free=not any(info[c]["has_axiom"] for c in closure(b)), path="neutral")
            edge(mid, tid, "supports")
            for party in ("challenger", "government"): edge(tid, f"concl-{party}", "supports", party)
    # party theorems
    for party, b in party_books.items():
        for t in info[b]["theorems"]:
            tid = "thm-" + t
            node(id=tid, type="THEOREM", layer="theorems", label=t.replace("-", " "), acl2_event=t, book=f"{b}.lisp", path=party)
            edge(tid, f"concl-{party}", f"supports_{party}", party)
            for n in nodes:
                if n["id"].startswith("ax-") and n["path"] == party: edge(n["id"], tid, "supports", party)
    (project / "data/parsed/explorer_graph.json").write_text(json.dumps({"layers": layers, "nodes": nodes, "edges": edges, "hypotheticals": hyps}, indent=2) + "\n")
    return len(nodes), len(edges), len(hyps)

# -------------------------------------------------------------------- run
def run(args):
    project = Path(args.project).resolve()
    slug = re.sub(r"[^a-z0-9-]+", "-", Path(args.project).name.lower()).strip("-").replace("-", "_")
    if not project.exists():
        subprocess.run([sys.executable, str(HERE / "amicus_pipeline.py"), "init", str(project), "--title", args.issue], check=True)
    model = ReplayModel(args.dry_run) if args.dry_run else Model(args.record)
    log = lambda s: print(f"\n=== {s}", flush=True)

    log("stage 1: sources")
    src, fetched = stage_sources(model, project, args.issue)
    for b, ok, line in fetched: print(f"  bill {b['congress']} {b['type']}{b['number']} {b['version']}: {'OK' if ok else 'FAILED'} {line}")
    texts = [read(p) for p in sorted((project / "inputs").glob("*_text.txt"))]
    if not texts: print("no bill text fetched; stopping"); return 1

    log("stage 2: clause IR")
    feedback = ""
    for attempt in range(args.repairs + 1):
        stage_ir(model, project, slug, texts, feedback)
        ok, out = oracle_ir(project)
        print(f"  attempt {attempt}: {'GREEN' if ok else 'red'}")
        if ok: break
        print(textwrap.indent(out[-1500:], "    | "))
        feedback = out
    else:
        print("IR stage did not converge"); return 1

    log("stage 3: core")
    feedback = ""
    for attempt in range(args.repairs + 1):
        core = stage_core(model, project, slug, feedback)
        ok, out = oracle_certify(project)
        print(f"  attempt {attempt}: {'GREEN' if ok else 'red'}")
        if ok: break
        print(textwrap.indent(out[-1500:], "    | "))
        feedback = out
    else:
        print("core stage did not converge"); return 1
    if not args.no_signoff:
        print("\nCONFLICT CONDITION RATIONALE (sign-off point):\n" + textwrap.indent(core["conflict_condition_rationale"], "  "))

    log("stage 4: parties (adversarial drafts) + audits")
    feedback = ""
    for attempt in range(args.repairs + 1):
        stage_parties(model, project, slug, feedback)
        ok, out = oracle_parties(project)
        print(f"  attempt {attempt}: {'GREEN' if ok else 'red'}")
        if ok: break
        print(textwrap.indent(out[-2500:], "    | "))
        feedback = out
    else:
        print("parties stage did not converge"); return 1

    log("stage 5: explorer graph (deterministic)")
    n, e, h = stage_graph(project, slug); print(f"  {n} nodes, {e} edges, {h} hypotheticals")
    sh([sys.executable, "tools/print_axioms.py"], project); sh([sys.executable, "tools/amicus_pipeline.py", "hinges"], project); sh([sys.executable, "tools/build_explorer_data.py"], project)
    log("done — certified, audited; see reports/ and web/")
    return 0

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("run"); p.add_argument("--issue", required=True); p.add_argument("--project", required=True)
    p.add_argument("--repairs", type=int, default=3); p.add_argument("--dry-run"); p.add_argument("--record"); p.add_argument("--no-signoff", action="store_true")
    p.set_defaults(fn=run)
    a = ap.parse_args(); sys.exit(a.fn(a))

if __name__ == "__main__":
    main()
