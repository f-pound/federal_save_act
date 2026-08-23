#!/usr/bin/env python3
"""
gen_consistency_audit.py — generate model/federal_save_act_consistency_audit.lisp

The ACL2 analogue of Vero's formal audit (unsat / joint_unsat): every
defaxiom and every encapsulate-exported constraint in each PARTY THEORY is
re-stated over a concrete "toy world" in which every defstub has an
executable definition, and proved as a theorem.  If the generated book
certifies, each party's entire trusted base — text facts, scenario
stipulations, bridge rules, interpretive/doctrinal/empirical axioms and its
hinge reading — is jointly SATISFIABLE.  If a theorem fails, the failing
axiom names the inconsistency (or the missing condition).

Party theories audited:
  C = core defuns + facts + text_rules + voting_text_rules + scenario
      + hinge_common + hinge_discretionary + challenger_model
  G = same but hinge_mandatory + government_model

The generated book includes NO party book and contains NO defaxiom: it is
a neutral, clean book.  It is regenerated (and --check'ed) in CI.
"""
import re, sys, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "model"
_cfg = json.loads((ROOT / "pipeline.json").read_text()) if (ROOT / "pipeline.json").exists() else {}
OUT = MODEL / f"{_cfg.get('slug', 'federal_save_act')}_consistency_audit.lisp"

# ------------------------------------------------------------------ reader
def tokenize(src):
    src = re.sub(r";[^\n]*", "", src)
    src = re.sub(r'#\|.*?\|#', "", src, flags=re.S)
    return re.findall(r"\(|\)|'|\"(?:[^\"\\]|\\.)*\"|[^\s()']+", src)

def parse(tokens):
    out, stack = [], [[]]
    quote = []
    for t in tokens:
        if t == "(":
            stack.append([])
        elif t == ")":
            lst = stack.pop()
            stack[-1].append(lst)
        elif t == "'":
            quote.append(len(stack[-1]))
            continue
        else:
            stack[-1].append(t)
        # apply pending quote to the element just added
        if quote and len(stack[-1]) - 1 == quote[-1] and (t != "(" ):
            idx = quote.pop(); stack[-1][idx] = ["quote", stack[-1][idx]]
        elif quote and t == "(":
            pass
    # handle quoted lists closed later: simpler second pass below
    return stack[0]

def read_forms(path):
    """Robust reader: uses a small recursive descent handling ' properly."""
    return read_forms_from_string(path.read_text(encoding="utf-8"))

def read_forms_from_string(src):
    src = re.sub(r";[^\n]*", "", src)
    toks = re.findall(r"\(|\)|'|\"(?:[^\"\\]|\\.)*\"|[^\s()']+", src)
    pos = 0
    def rd():
        nonlocal pos
        t = toks[pos]; pos += 1
        if t == "(":
            lst = []
            while toks[pos] != ")":
                lst.append(rd())
            pos += 1
            return lst
        if t == "'":
            return ["quote", rd()]
        return t
    forms = []
    while pos < len(toks):
        forms.append(rd())
    return forms

def show(x):
    if isinstance(x, list):
        if len(x) == 2 and x[0] == "quote":
            return "'" + show(x[1])
        return "(" + " ".join(show(y) for y in x) + ")"
    return x

def subst_flip(x, mapping, flip):
    """Substitute mapped function names AND insert `flip` as their first argument."""
    if isinstance(x, list):
        if len(x) == 2 and x[0] == "quote":
            return x
        if x and isinstance(x[0], str) and x[0].lower() in mapping:
            return [mapping[x[0].lower()], flip] + [subst_flip(y, mapping, flip) for y in x[1:]]
        return [subst_flip(y, mapping, flip) for y in x]
    return x

def subst(x, mapping):
    if isinstance(x, list):
        if len(x) == 2 and x[0] == "quote":
            return x
        return [subst(y, mapping) for y in x]
    return mapping.get(x.lower(), x) if isinstance(x, str) else x

# ------------------------------------------------------------ extraction
def collect(books):
    """Return (stubs, defuns, sigs, constraints, axioms) across the books."""
    stubs, defuns, sigs, constraints, axioms = [], [], [], [], []
    for b in books:
        for f in read_forms(MODEL / f"{b}.lisp"):
            if not isinstance(f, list) or not f: continue
            head = f[0].lower()
            if head == "defstub":
                stubs.append((f[1], f[2]))
            elif head == "defun":
                defuns.append((f[1], f[2], f[3:]))
            elif head == "defaxiom":
                axioms.append((b, f[1], f[2]))
            elif head == "encapsulate":
                for s in f[1]:
                    sigs.append((s[0], s[1]))
                for e in f[2:]:
                    if isinstance(e, list) and e and e[0].lower() == "defthm":
                        constraints.append((b, e[1], e[2]))
    return stubs, defuns, sigs, constraints, axioms

# ------------------------------------------------------------------ worlds
# Worlds and theories are DATA: data/audit_worlds.json.  A new statute project
# edits that file, not this tool.  Each world maps stub / signature name ->
# [args, body] in plain ACL2 over the scenario constants; unlisted -> NIL.
WORLDS_PATH = ROOT / "data" / "audit_worlds.json"
_W = json.loads(WORLDS_PATH.read_text(encoding="utf-8"))
COMMON = {k: tuple(v) for k, v in _W["common"].items()}
THEORIES = {}
for tag, t in _W["theories"].items():
    world = dict(COMMON); world.update({k: tuple(v) for k, v in t["world"].items()})
    THEORIES[tag] = (t["party"], world, t["books"])

def load_flips(party):
    """Structured flips from the adversarial audit, if it has run."""
    aa = ROOT / "reports" / "adversarial_audit.json"
    if not aa.exists(): return {}
    raw = json.loads(aa.read_text(encoding="utf-8")).get(party, [])
    return {r["axiom"]: (r["verdict"], r.get("flips") or [], r.get("breaks", []), r.get("witness") or {}, r.get("break_witnesses") or {}) for r in raw}

def inst(x, env):
    """Instantiate free variables (non-head symbols) from env with quoted constants."""
    if isinstance(x, list):
        if len(x) == 2 and x[0] == "quote": return x
        return [x[0]] + [inst(y, env) for y in x[1:]] if x else x
    if isinstance(x, str) and x in env:
        v = env[x]
        return ["quote", v] if isinstance(v, str) else ("t" if v is True else "nil")
    return x

def lit(v):
    return "t" if v is True else "nil" if v is False else f"'{v}"

def emit():
    out = ['(in-package "ACL2")', '',
           ';' * 78,
           f';; {OUT.name}  —  GENERATED by tools/gen_consistency_audit.py',
           ';;',
           ';; CONSISTENCY AUDIT of each party\'s trusted base (cf. Vero, arXiv:2608.13522 § 3.5).',
           ';; For each party theory, every defstub gets a concrete toy-world definition',
           ';; (aud-<party>-<name>), every core defun is re-defined over that world, and',
           ';; every defaxiom / encapsulate constraint of the theory is restated over the',
           ';; world and PROVED.  Certification of this book = the theory is satisfiable.',
           ';; A failing theorem names an inconsistent axiom or a missing condition.',
           ';; This book includes no party book and contains no defaxiom (neutral).',
           ';' * 78, '']
    stats = {}
    for tag, (party, world, books) in THEORIES.items():
        stubs, defuns, sigs, constraints, axioms = collect(books)
        names = [n for n, _ in stubs] + [n for n, _ in sigs]
        mapping = {n.lower(): f"aud-{tag}-{n}" for n in names}
        mapping.update({n.lower(): f"aud-{tag}-{n}" for n, _, _ in defuns})
        out.append(';;; ' + '=' * 73)
        out.append(f';;; WORLD {tag.upper()}: the {party} theory')
        out.append(f';;; books: {", ".join(books)}')
        out.append(';;; ' + '=' * 73)
        out.append('')
        flips = load_flips(party)
        # flips grouped by stub: stub -> list of (axiom, argvals, newval)
        by_stub = {}
        for ax, (verdict, fl, breaks, wit, bws) in flips.items():
            for name, argvals, newval in fl:
                by_stub.setdefault(name.lower(), []).append((ax, argvals, newval))
        out.append(f';; --- {len(names)} stub / signature definitions, parameterised by FLIP ---')
        out.append(';; (aud-X-f name args...) : the base world, except that when FLIP names an')
        out.append(';; audited axiom, the one or two stub values the adversarial audit flips to')
        out.append(';; falsify that axiom are overridden.  FLIP = \'none is the base world.')
        for n, args in stubs + sigs:
            a = show(args)
            spec = world.get(n.lower())
            argnames = [x for x in args]
            if spec:
                wargs, body = spec
                wnames = wargs.strip("()").split()
                assert len(wnames) == len(argnames), f"arity mismatch for {n}: world {wargs} vs stub {a}"
            else:
                wnames, body = argnames, "nil"
            over = by_stub.get(n.lower(), [])
            expr = f"(if {body} t nil)"
            for ax, argvals, newval in reversed(over):
                cond = " ".join([f"(equal flip '{ax})"] + [f"(equal {v} {lit(av)})" for v, av in zip(wnames, argvals)])
                expr = f"(if (and {cond}) {lit(newval)} {expr})"
            used = [v for v in wnames if re.search(r"\b%s\b" % re.escape(v), expr)]
            ign = [v for v in wnames if v not in used] + ([] if "flip" in expr else ["flip"])
            decl = f" (declare (ignore {' '.join(ign)}))" if ign else ""
            out.append(f"(defun {mapping[n.lower()]} (flip {' '.join(wnames)}){decl} {expr})")
        out.append('')
        out.append(f';; --- {len(defuns)} core definitions over the world (flip threaded through) ---')
        for n, args, body in defuns:
            out.append(f"(defun {mapping[n.lower()]} (flip {' '.join(args)})\n  " + " ".join(show(subst_flip(b, mapping, 'flip')) for b in body) + ")")
        out.append('')
        items = [("constraint", b, n, f) for b, n, f in constraints] + [("axiom", b, n, f) for b, n, f in axioms]
        out.append(f';; --- {len(items)} audited propositions in the BASE world (flip = none) ---')
        out.append(f';; ({len(constraints)} encapsulate constraints, {len(axioms)} defaxioms): the theory is satisfiable')
        for kind, b, n, f in items:
            out.append(f";; {kind} {n}  [{b}]")
            out.append(f"(defthm aud-{tag}-{n}\n  {show(subst_flip(f, mapping, "'none"))}\n  :rule-classes nil)")
        out.append('')
        # independence certificates
        ncert = 0
        if flips:
            out.append(';; --- INDEPENDENCE CERTIFICATES (kernel-checked adversarial audit) ---')
            out.append(';; For each audited axiom A with a recorded flip: (1) A is FALSE in the')
            out.append(';; flipped world; (2) every OTHER proposition of the theory still holds')
            out.append(';; there (independent), or the named coupled ones are false (coupled).')
            for kind, b, n, f in items:
                if kind != "axiom" or n not in flips: continue
                verdict, fl, breaks, wit, bws = flips[n]
                if not fl: continue
                fconst = f"'{n}"
                out.append(f";; {verdict}: {n}" + (f"  (coupled with {', '.join(breaks)})" if breaks else "") + (f"  witness {wit}" if wit else ""))
                out.append(f"(defthm aud-{tag}-flip-{n}-falsifies\n  (not {show(subst_flip(inst(f, wit), mapping, fconst))})\n  :rule-classes nil)")
                others = [(k2, b2, m, f2) for k2, b2, m, f2 in items if m != n and m not in breaks]
                conj = "\n   ".join(show(subst_flip(f2, mapping, fconst)) for _, _, m, f2 in others)
                out.append(f"(defthm aud-{tag}-flip-{n}-preserves-rest\n  (and {conj})\n  :rule-classes nil)")
                for m in breaks:
                    f2 = next(ff for _, _, mm, ff in items if mm == m)
                    out.append(f"(defthm aud-{tag}-flip-{n}-breaks-{m}\n  (not {show(subst_flip(inst(f2, bws.get(m, {})), mapping, fconst))})\n  :rule-classes nil)")
                ncert += 1
            out.append('')
        stats[party] = {"stubs_and_sigs": len(names), "defuns": len(defuns), "constraints": len(constraints), "axioms": len(axioms), "independence_certificates": ncert}
    out.append(';;; ' + '=' * 73)
    out.append(';;; JOINT UNSATISFIABILITY of the two registration bridges (propositional):')
    out.append(';;; the challenger needs (not (valid-regulationp law x)) and the government')
    out.append(';;; needs (valid-regulationp law x) for the same application x.  No world')
    out.append(';;; satisfies both, which is why the party books are never loaded together.')
    out.append(';;; ' + '=' * 73)
    out.append('''(defthm parties-registration-bridges-jointly-unsatisfiable
  (not (and (implies ci (not v))   ; challenger-bridge-regulation-invalid
            (implies gd v)         ; government-bridge-defense-validates
            ci gd))
  :rule-classes nil)''')
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8")
    return stats

if __name__ == "__main__":
    check = "--check" in sys.argv
    before = OUT.read_text(encoding="utf-8") if OUT.exists() else None
    stats = emit()
    after = OUT.read_text(encoding="utf-8")
    print(json.dumps(stats))
    if check:
        if before != after:
            OUT.write_text(before or "", encoding="utf-8")
            print(f"STALE: {OUT.relative_to(ROOT)} differs from generator output"); sys.exit(1)
        print(f"OK: {OUT.relative_to(ROOT)} matches generator")
    else:
        print(f"wrote {OUT.relative_to(ROOT)}")
