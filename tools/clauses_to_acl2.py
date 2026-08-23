#!/usr/bin/env python3
"""
clauses_to_acl2.py — Deterministically compile a statutory clause IR
(data/parsed/<name>.json, schema in tools/clause_ir_schema.json) into an
ACL2 book model/<book>.lisp, and optionally a controlled-English rendering.

The point: the JSON is the single source of truth for an enumerated
statutory definition.  Both the ACL2 definitions and the English
paraphrase are generated from it, so they cannot drift apart, and the
ACL2 output is byte-for-byte reproducible (CI runs --check).

Usage:
  python tools/clauses_to_acl2.py data/parsed/federal_save_act_document_rules.json
  python tools/clauses_to_acl2.py <ir.json> --check      # exit 1 if model/<book>.lisp is stale
  python tools/clauses_to_acl2.py <ir.json> --english    # also write docs/generated/<book>.md
  python tools/clauses_to_acl2.py <ir.json> --ace        # also upsert generated ACE statements
                                                         # into data/parsed/<ir-stem-without-suffix>_ace.json

IR sections: categories (enumerations), rules (defun / defaxiom), process
(labeled state machine table), atoms (ACE phrases for predicates).
Several IR files may be passed; flags apply to all.

Expression grammar (see clause_ir_schema.json):
  true | false
  {"and": [e...]} | {"or": [e...]} | {"not": e}
  {"some-in": [var, category]}  ->  (some-in-catsp var *category*)
  {"all-in":  [var, category]}  ->  (all-in-catsp  var *category*)
  {"none-in": [var, category]}  ->  (none-in-catsp var *category*)
  {"member":  [var, category]}  ->  (member-equal  var *category*)
  {"pred":    [name, args...]}  ->  (name args...)
"""
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SYM = re.compile(r"^[a-z][a-z0-9-]*$")


class IRError(Exception):
    pass


def check_sym(s, what):
    if not isinstance(s, str) or not SYM.match(s):
        raise IRError(f"bad {what}: {s!r} (must match {SYM.pattern})")
    return s


# ---------------------------------------------------------------- ACL2 emit

def emit_expr(e, cats, vars_, indent):
    pad = " " * indent
    if e is True:
        return "t"
    if e is False:
        return "nil"
    if not isinstance(e, dict) or len(e) != 1:
        raise IRError(f"expression must be a single-key object: {e!r}")
    (op, arg), = e.items()
    if op in ("and", "or"):
        if not isinstance(arg, list) or not arg:
            raise IRError(f"{op} needs a nonempty list")
        parts = [emit_expr(x, cats, vars_, indent + 2 + len(op)) for x in arg]
        sep = "\n" + pad + " " * (2 + len(op))
        return f"({op} " + sep.join(parts) + ")"
    if op == "not":
        return f"(not {emit_expr(arg, cats, vars_, indent + 5)})"
    if op in ("some-in", "all-in", "none-in", "member"):
        var, cat = arg
        check_sym(var, "variable")
        check_sym(cat, "category")
        if var not in vars_:
            raise IRError(f"unbound variable {var!r}")
        if cat not in cats:
            raise IRError(f"unknown category {cat!r}")
        fn = {"some-in": "some-in-catsp", "all-in": "all-in-catsp",
              "none-in": "none-in-catsp", "member": "member-equal"}[op]
        return f"({fn} {var} *{cat}*)"
    if op == "pred":
        name, *args = arg
        check_sym(name, "predicate")
        for a in args:
            if a.startswith("'"):
                check_sym(a[1:], "constant")
                continue
            check_sym(a, "argument")
            if a not in vars_:
                raise IRError(f"unbound variable {a!r}")
        return "(" + " ".join([name, *args]) + ")"
    raise IRError(f"unknown operator {op!r}")


def emit_acl2(ir, ir_path):
    book = check_sym(ir["book"].replace("_", "-"), "book") and ir["book"]
    cats = {}
    out = []
    out.append('(in-package "ACL2")\n')
    for inc in ir.get("includes", []):
        out.append(f'(include-book "{inc}")')
    out.append("")
    out.append(";" * 78)
    out.append(f";; {book}.lisp  —  GENERATED FILE, DO NOT EDIT")
    out.append(f";; Source IR : {ir_path.relative_to(ROOT).as_posix()}")
    out.append(f";; Generator : tools/clauses_to_acl2.py")
    out.append(f";; IR sha256 : {hashlib.sha256(json.dumps(ir, sort_keys=True).encode()).hexdigest()}")
    if "title" in ir:
        out.append(f";; {ir['title']}")
    out.append(";;")
    out.append(";; Every defconst below is a statutory enumeration; every defun is a")
    out.append(";; statutory rule compiled from a boolean IR.  Provenance is carried in")
    out.append(";; the comments so reviewers can check each symbol against the text.")
    out.append(";" * 78)
    out.append("")
    for c in ir.get("categories", []):
        name = check_sym(c["name"], "category name")
        if name in cats:
            raise IRError(f"duplicate category {name}")
        syms = []
        out.append(";;; " + "=" * 73)
        out.append(f";;; CATEGORY {name}   [{c.get('source', '')}]")
        if c.get("description"):
            out.append(f";;; {c['description']}")
        out.append(";;; " + "=" * 73)
        for m in c["members"]:
            sym = check_sym(m["symbol"], "member symbol")
            if sym in syms:
                raise IRError(f"duplicate member {sym} in {name}")
            syms.append(sym)
            out.append(f";;   {sym:<36} {m.get('source', '')}")
            if m.get("text"):
                out.append(f";;       \"{m['text']}\"")
        cats[name] = syms
        out.append(f"(defconst *{name}*")
        out.append("  '(" + "\n    ".join(syms) + "))")
        out.append("")
    # cross-category disjointness (a symbol must mean one thing)
    seen = {}
    for name, syms in cats.items():
        for s in syms:
            if s in seen:
                raise IRError(f"symbol {s} appears in both {seen[s]} and {name}")
            seen[s] = name
    if "process" in ir:
        out.extend(emit_process(ir["process"]))
    for r in ir.get("rules", []):
        name = check_sym(r["name"], "rule name")
        args = [check_sym(a, "arg") for a in r["args"]]
        kind = r.get("kind", "defun")
        out.append(";;; " + "=" * 73)
        out.append(f";;; {'AXIOM' if kind == 'axiom' else 'RULE'} {name}   [{r.get('label', '')}]  {r.get('source', '')}")
        if r.get("text"):
            out.append(f";;; \"{r['text']}\"")
        if r.get("description"):
            out.append(f";;; {r['description']}")
        out.append(";;; " + "=" * 73)
        if kind == "defun":
            out.append(f"(defun {name} ({' '.join(args)})")
            out.append("  " + emit_expr(r["body"], cats, set(args), 2) + ")")
        elif kind == "axiom":
            # Text-derived constraint on defstubs: (implies hyps concl).
            # Free variables are implicitly universally quantified by ACL2.
            out.append(f"(defaxiom {name}")
            out.append("  (implies")
            out.append("   " + emit_expr(r["hyps"], cats, set(args), 3))
            out.append("   " + emit_expr(r["concl"], cats, set(args), 3) + "))")
        else:
            raise IRError(f"unknown rule kind {kind!r}")
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def emit_process(pr):
    """A labeled state machine as data: per-state / per-event defconsts and
    the edge table.  Rejects undeclared states/events and duplicate
    (from, event) pairs — lsm-step takes the FIRST match, so a duplicate
    would silently shadow a transition."""
    name = check_sym(pr["name"], "process name")
    out = [";;; " + "=" * 73, f";;; PROCESS {name}   [{pr.get('source', '')}]"]
    if pr.get("description"):
        out.append(f";;; {pr['description']}")
    out.append(";;; " + "=" * 73)
    states, events = {}, {}
    for st in pr["states"]:
        sym, const = check_sym(st["symbol"], "state"), check_sym(st["const"], "state const")
        if sym in states:
            raise IRError(f"duplicate state {sym}")
        states[sym] = const
        out.append(f"(defconst *{const}* '{sym})" + (f"  ; {st['text']}" if st.get("text") else ""))
    out.append("")
    for ev in pr["events"]:
        sym, const = check_sym(ev["symbol"], "event"), check_sym(ev["const"], "event const")
        if sym in events:
            raise IRError(f"duplicate event {sym}")
        events[sym] = const
        out.append(f"(defconst *{const}* '{sym})" + (f"  ; {ev['text']}" if ev.get("text") else ""))
    out.append("")
    out.append(f"(defconst *{name}-states*\n  (list " + " ".join(f"*{c}*" for c in states.values()) + "))")
    out.append(f"(defconst *{name}-events*\n  (list " + " ".join(f"*{c}*" for c in events.values()) + "))")
    out.append("")
    out.append(";; Edge table: (from-state event to-state).  Unlisted pairs are no-ops.")
    out.append(f"(defconst *{name}-edges*")
    out.append("  (list")
    seen = set()
    for e in pr["edges"]:
        f, ev, t = e["from"], e["event"], e["to"]
        for x, tbl, what in ((f, states, "state"), (t, states, "state"), (ev, events, "event")):
            if x not in tbl:
                raise IRError(f"edge references undeclared {what} {x!r}")
        if (f, ev) in seen:
            raise IRError(f"duplicate edge for ({f}, {ev}) — table would be nondeterministic")
        seen.add((f, ev))
        tag = f"  ; {e.get('label', '')} {e.get('source', '')}".rstrip()
        if e.get("text"):
            out.append(f"   ;; [{e.get('source_id', '')}] \"{e['text']}\"")
        out.append(f"   (list *{states[f]}* *{events[ev]}* *{states[t]}*){tag}")
    out.append("   ))")
    out.append("")
    return out


# ------------------------------------------------------------------ ACE emit
#
# A rule whose body uses only and/or/some-in/member is put into disjunctive
# normal form over category MEMBERS; each disjunct becomes one ACE sentence
#
#   If a <subject> has a <noun-1> and the <subject> has a <noun-2> then the
#   <subject> has a <consequent>.
#
# Every member of a category therefore produces its own sentence (or its own
# pairing sentences), so the ACE text cannot silently cover fewer statutory
# items than the ACL2 table does.

def dnf(e, cats_members, var, neg=False):
    """Return list of conjuncts.  A literal is ("member", symbol) or
    ("pred", name, args, negated)."""
    if e is True:
        return [] if neg else [()]
    if e is False:
        return [()] if neg else []
    (op, arg), = e.items()
    if op == "not":
        return dnf(arg, cats_members, var, not neg)
    if op == "pred":
        return [(("pred", arg[0], tuple(arg[1:]), neg),)]
    if op in ("some-in", "member"):
        if neg:
            raise IRError("ACE rendering: negated enumeration is not supported")
        v, cat = arg
        if v != var:
            raise IRError(f"ACE rendering: variable {v!r} is not the possession variable {var!r}")
        return [(("member", m),) for m in cats_members[cat]]
    if (op == "or") != neg:          # or, or negated and  → union
        out = []
        for x in arg:
            out.extend(dnf(x, cats_members, var, neg))
        return out
    if op in ("and", "or"):          # and, or negated or → product
        acc = [()]
        for x in arg:
            acc = [a + b for a in acc for b in dnf(x, cats_members, var, neg)]
        return acc
    raise IRError(f"ACE rendering does not support operator {op!r}")


class AceCtx:
    """Tracks first/subsequent mention so entities get 'a' then 'the'."""
    def __init__(self, entities):
        self.entities = entities
        self.seen = set()

    def ref(self, var):
        noun = self.entities[var]
        if var in self.seen:
            return f"the {noun}"
        self.seen.add(var)
        return f"a {noun}"


def render_literal(lit, ctx, atoms, subj, noun_of):
    if lit[0] == "member":
        return f"{ctx.ref(subj)} has a {noun_of[lit[1]]}"
    _, name, args, negated = lit
    spec = atoms.get(name)
    if not spec:
        raise IRError(f"no ACE atom for predicate {name!r}")
    tpl = spec["ace_neg"] if negated else spec["ace"]
    if negated and "ace_neg" not in spec:
        raise IRError(f"atom {name!r} needs ace_neg")
    fills = {}
    for formal, actual in zip(spec["args"], args):
        if actual.startswith("'"):
            fills[formal] = spec.get("constants", {}).get(actual[1:], actual[1:])
        else:
            fills[formal] = ctx.ref(actual)
    return tpl.format(**fills)


def emit_ace_statements(ir):
    members = {c["name"]: [m["symbol"] for m in c["members"]] for c in ir.get("categories", [])}
    noun = {m["symbol"]: m.get("ace_noun") for c in ir.get("categories", []) for m in c["members"]}
    source = {m["symbol"]: m.get("source", "") for c in ir.get("categories", []) for m in c["members"]}
    atoms = ir.get("atoms", {})
    stmts = []
    for r in ir.get("rules", []):
        a = r.get("ace")
        if not a:
            continue
        kind = r.get("kind", "defun")
        subj = a["subject"]
        var = a.get("possession_of", subj)
        entities = dict(a.get("entities", {}))
        entities.setdefault(subj, subj)
        sentences, covered = [], []
        hyps = r["body"] if kind == "defun" else r["hyps"]
        for conj in dnf(hyps, members, var):
            ctx = AceCtx(entities)
            for lit in conj:
                if lit[0] == "member" and not noun.get(lit[1]):
                    raise IRError(f"member {lit[1]} has no ace_noun")
            covered.append(" + ".join(
                (f"{l[1]} [{source[l[1]]}]" if l[0] == "member" else ("not " if l[3] else "") + l[1])
                for l in conj))
            ante = " and ".join(render_literal(l, ctx, atoms, subj, noun) for l in conj)
            if kind == "defun":
                cons = f"{ctx.ref(subj)} has a {a['consequent_noun']}"
            else:
                (cl,) = dnf(r["concl"], members, var)
                cons = " and ".join(render_literal(l, ctx, atoms, subj, noun) for l in cl)
            sentences.append(f"If {ante} then {cons}.")
        stmts.append({
            "id": a["id"],
            "generated_from": {"ir": ir["book"], "rule": r["name"]},
            "source_ref": a.get("source_ref", r.get("source", "")),
            "source_text": r.get("text", ""),
            "ace_text": " ".join(sentences),
            "classification": a.get("classification", r.get("label", "")),
            "ape_status": "PENDING",
            "ape_error": None,
            "predicate_target": f"({r['name']} {' '.join(r['args'])})",
            "requires_human_review": False,
            "covers": covered,
            "notes": "GENERATED by tools/clauses_to_acl2.py from the clause IR; do not edit. "
                     "One sentence per DNF disjunct over statutory members.",
            "replaces": a.get("replaces", []),
        })
    pr = ir.get("process")
    if pr and pr.get("ace"):
        a = pr["ace"]
        subj = a["subject"]
        sentences, covered = [], []
        for e in pr["edges"]:
            sentences.append(
                f"If a {subj} is in a n:{e['from']}-state and a n:{e['event']}-event occurs "
                f"then the {subj} is in a n:{e['to']}-state.")
            covered.append(f"{e['from']} --{e['event']}--> {e['to']} [{e.get('label','')} {e.get('source','')}]".rstrip())
        stmts.append({
            "id": a["id"],
            "generated_from": {"ir": ir["book"], "process": pr["name"]},
            "source_ref": pr.get("source", ""),
            "source_text": pr.get("description", ""),
            "ace_text": " ".join(sentences),
            "classification": a.get("classification", "PROCESS_RULE"),
            "ape_status": "PENDING",
            "ape_error": None,
            "predicate_target": f"*{pr['name']}-edges*  (lsm-step / lsm-run)",
            "requires_human_review": False,
            "covers": covered,
            "notes": "GENERATED by tools/clauses_to_acl2.py from the process table; one sentence per edge.",
            "replaces": a.get("replaces", []),
        })
    return stmts


def upsert_ace(ir, ir_path, check):
    # All IRs of one project share one ACE file: <slug>_ace.json, where the
    # slug is given explicitly or is the IR stem with its section suffix removed.
    stem = ir.get("slug") or ir_path.stem
    for suffix in ("_voting_id_rules", "_voting_text_rules", "_voting_table", "_document_rules",
                   "_process_table", "_removal_table", "_text_rules", "_rules", "_table", "_clauses"):
        if stem.endswith(suffix):
            stem = stem[: -len(suffix)]
            break
    ace_path = ir_path.parent / f"{stem}_ace.json"
    doc = json.loads(ace_path.read_text(encoding="utf-8")) if ace_path.exists() else {"slug": stem, "ace_statements": []}
    new = emit_ace_statements(ir)
    by_id = {s["id"]: s for s in doc["ace_statements"]}
    stale = []
    for st in new:
        for rid in st["replaces"]:
            if rid in by_id:
                stale.append(rid)
        old = by_id.get(st["id"])
        if old is not None and old.get("ace_text") == st["ace_text"] and old.get("covers") == st["covers"]:
            # keep the APE validator's results (it owns these three fields)
            for k in ("ape_status", "ape_error", "notes"):
                if k in old:
                    st[k] = old[k]
    changed = any(by_id.get(st["id"]) != st for st in new) or bool(stale)
    if check:
        if changed:
            print(f"STALE: {ace_path.relative_to(ROOT)} generated ACE statements differ from IR")
            return 1
        print(f"OK: {ace_path.relative_to(ROOT)} generated ACE statements match IR")
        return 0
    out = [s for s in doc["ace_statements"] if s["id"] not in stale and s["id"] not in {n["id"] for n in new}]
    # insert generated statements at the position of the first replaced/old one
    pos = len(out)
    ids = [s["id"] for s in doc["ace_statements"]]
    for st in new:
        cands = [ids.index(i) for i in st["replaces"] + [st["id"]] if i in ids]
        if cands:
            pos = min(pos, min(cands))
    doc["ace_statements"] = out[:pos] + new + out[pos:]
    ace_path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {ace_path.relative_to(ROOT)} ({len(new)} generated statement(s); removed {stale or 'none'})")
    return 0


# ------------------------------------------------------------- English emit

def english_expr(e, cats, depth=0):
    if e is True:
        return "always"
    if e is False:
        return "never"
    (op, arg), = e.items()
    if op == "and":
        return " AND ".join(f"({english_expr(x, cats, depth+1)})" if isinstance(x, dict) and set(x) & {"and", "or"} else english_expr(x, cats, depth+1) for x in arg)
    if op == "or":
        return " OR ".join(f"({english_expr(x, cats, depth+1)})" if isinstance(x, dict) and set(x) & {"and", "or"} else english_expr(x, cats, depth+1) for x in arg)
    if op == "not":
        return f"it is not the case that {english_expr(arg, cats, depth+1)}"
    var, cat = arg[0], arg[1] if len(arg) > 1 else None
    if op == "some-in":
        return f"at least one item of {var} is a {cat.replace('-', ' ')}"
    if op == "all-in":
        return f"every item of {var} is a {cat.replace('-', ' ')}"
    if op == "none-in":
        return f"no item of {var} is a {cat.replace('-', ' ')}"
    if op == "member":
        return f"{var} is a {cat.replace('-', ' ')}"
    if op == "pred":
        return f"{arg[0]}({', '.join(arg[1:])})"
    raise IRError(op)


def emit_english(ir):
    out = [f"# {ir.get('title', ir['book'])}", "",
           "_Generated from the same IR as the ACL2 book; do not edit._", ""]
    for c in ir.get("categories", []):
        out.append(f"## Category `{c['name']}` — {c.get('source', '')}")
        if c.get("description"):
            out.append(c["description"])
        out.append("")
        for m in c["members"]:
            out.append(f"- **{m['symbol']}** ({m.get('source', '')}): {m.get('text', '')}")
        out.append("")
    pr = ir.get("process")
    if pr:
        out.append(f"## Process `{pr['name']}` — {pr.get('source', '')}")
        if pr.get("description"):
            out.append(pr["description"])
        out.append("")
        out.append("| From | Event | To | Basis |")
        out.append("|---|---|---|---|")
        for e in pr["edges"]:
            out.append(f"| {e['from']} | {e['event']} | {e['to']} | {e.get('label', '')} {e.get('source', '')}{(' — “' + e['text'] + '”') if e.get('text') else ''} |")
        out.append("")
        out.append("Any (state, event) pair not listed leaves the state unchanged.")
        out.append("")
    cats = {c["name"] for c in ir.get("categories", [])}
    for r in ir.get("rules", []):
        out.append(f"## {'Axiom' if r.get('kind') == 'axiom' else 'Rule'} `{r['name']}({', '.join(r['args'])})` — {r.get('source', '')}")
        if r.get("text"):
            out.append(f"> {r['text']}")
            out.append("")
        if r.get("description"):
            out.append(r["description"])
            out.append("")
        if r.get("kind") == "axiom":
            out.append(f"If {english_expr(r['hyps'], cats)}, then {english_expr(r['concl'], cats)}.")
        else:
            out.append(f"`{r['name']}` holds exactly when: {english_expr(r['body'], cats)}.")
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    check = "--check" in argv
    english = "--english" in argv
    ace = "--ace" in argv
    paths = [Path(a).resolve() for a in argv[1:] if not a.startswith("--")]
    status = 0
    for ir_path in paths:
        status = max(status, compile_one(ir_path, check, english, ace))
    return status


def compile_one(ir_path, check, english, ace):
    ir = json.loads(ir_path.read_text(encoding="utf-8"))
    lisp = emit_acl2(ir, ir_path)
    out_path = ROOT / "model" / f"{ir['book']}.lisp"
    status = 0
    if check:
        current = out_path.read_text(encoding="utf-8") if out_path.exists() else None
        if current != lisp:
            print(f"STALE: {out_path.relative_to(ROOT)} differs from compiled IR; rerun without --check")
            status = 1
        else:
            print(f"OK: {out_path.relative_to(ROOT)} matches IR")
    else:
        out_path.write_text(lisp, encoding="utf-8")
        print(f"wrote {out_path.relative_to(ROOT)}")
    if english:
        md_path = ROOT / "docs" / "generated" / f"{ir['book']}.md"
        md_path.parent.mkdir(parents=True, exist_ok=True)
        md = emit_english(ir)
        if check:
            if (md_path.read_text(encoding="utf-8") if md_path.exists() else None) != md:
                print(f"STALE: {md_path.relative_to(ROOT)}")
                status = 1
        else:
            md_path.write_text(md, encoding="utf-8")
            print(f"wrote {md_path.relative_to(ROOT)}")
    if ace:
        status = max(status, upsert_ace(ir, ir_path, check))
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv))
