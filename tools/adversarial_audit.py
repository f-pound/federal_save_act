#!/usr/bin/env python3
"""
adversarial_audit.py — the ADVERSARIAL complement of the consistency audit.

The consistency audit (gen_consistency_audit.py) is confirmatory: it exhibits
one world in which every axiom of a party theory holds.  This tool asks, for
EACH axiom A of a theory T, the adversarial questions (cf. Vero's `disprove`
route, arXiv:2608.13522 § 3.5):

  1. INDEPENDENCE — is there a world satisfying (T \\ {A}) and NOT A?
     We try the cheapest candidate: the base world with exactly ONE stub
     redefined so that A becomes false at a witness point (a "flipped
     world"), then evaluate every other axiom there.  The worlds are finite
     (every stub is a membership test over named constants), so evaluation
     over the constants plus one fresh symbol is a complete finite-model
     check.  Verdicts:
        independent  — flipped world is a model of (T\\{A}) ∧ ¬A
        coupled      — the flip falsifies other axioms; they are listed.
                       Coupled clusters are the theory's LOAD-BEARING joints:
                       change one and the others must change with it.
  2. REDUNDANCY — can ACL2 prove A from T \\ {A}?  (--acl2) Runs one ACL2
     session per axiom over a generated book that asserts all other axioms
     and attempts A as a defthm under a time limit.  A success is a
     machine-checked certificate that A is a theorem of the rest (and could
     be deleted); a failure is NOT a proof of independence (item 1 is).

Outputs reports/adversarial_audit.{json,md}.  The finite-model verdicts are
computed by this evaluator over the SAME parsed axiom bodies and world
definitions that the certified consistency-audit book uses; the ACL2
redundancy certificates are kernel-checked.
"""
import json, re, subprocess, sys, tempfile, itertools
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_consistency_audit as G

ROOT = G.ROOT; MODEL = G.MODEL
OUT_JSON = ROOT / "reports/adversarial_audit.json"; OUT_MD = ROOT / "reports/adversarial_audit.md"

# ------------------------------------------------------------ evaluator
class World:
    """Finite interpretation: stubs/sigs from a world dict, core defuns parsed."""
    def __init__(self, worlddict, stubs, sigs, defuns, overrides=None):
        self.fns = {}
        self.overrides = overrides or {}
        self.strict = {n.lower() for n, _ in stubs + sigs}
        for n, args in stubs + sigs:
            spec = worlddict.get(n.lower())
            if spec:
                wargs, body = spec
                self.fns[n.lower()] = (wargs.strip("()").split(), G.read_forms_from_string(body)[0] if hasattr(G, 'read_forms_from_string') else parse_one(body))
            else:
                self.fns[n.lower()] = ([a for a in args], "nil")
        for n, args, body in defuns:
            self.fns[n.lower()] = ([a for a in args], body[-1])   # last form is the body (skip declares)
        self.consts = set()
        for a, b in self.fns.values():
            self.consts |= consts_in(b)

    def call(self, name, argvals):
        key = name.lower()
        if key in self.overrides:
            return bool(truthy(self.overrides[key](argvals)))
        params, body = self.fns[key]
        env = dict(zip(params, argvals))
        v = self.ev(body, env)
        return bool(truthy(v)) if key in self.strict else v

    def ev(self, x, env):
        if isinstance(x, str):
            if x.lower() == "t": return True
            if x.lower() == "nil": return False
            if x in env: return env[x]
            if x.lower() in env: return env[x.lower()]
            raise KeyError(f"unbound {x}")
        head = x[0].lower() if isinstance(x[0], str) else None
        if head == "quote": return x[1] if not isinstance(x[1], list) else tuple(x[1])
        if head == "and": return all(truthy(self.ev(y, env)) for y in x[1:]) if len(x) > 1 else True
        if head == "or": return any(truthy(self.ev(y, env)) for y in x[1:])
        if head == "not": return not truthy(self.ev(x[1], env))
        if head == "implies": return (not truthy(self.ev(x[1], env))) or truthy(self.ev(x[2], env))
        if head == "iff": return truthy(self.ev(x[1], env)) == truthy(self.ev(x[2], env))
        if head == "if": return self.ev(x[2], env) if truthy(self.ev(x[1], env)) else self.ev(x[3], env)
        if head == "equal": return self.ev(x[1], env) == self.ev(x[2], env)
        if head == "member-equal":
            v, lst = self.ev(x[1], env), self.ev(x[2], env)
            return v in (lst if isinstance(lst, tuple) else ())
        if head == "list": return tuple(self.ev(y, env) for y in x[1:])
        if head == "declare": return True
        if head == "booleanp": return isinstance(self.ev(x[1], env), bool)
        if head == "consp": v = self.ev(x[1], env); return isinstance(v, tuple) and len(v) > 0
        if head == "endp": v = self.ev(x[1], env); return not (isinstance(v, tuple) and len(v) > 0)
        return self.call(head, [self.ev(y, env) for y in x[1:]])

def truthy(v): return v is not False and v is not None
def parse_one(s): return G.read_forms_from_string(s)[0]
def consts_in(x, acc=None):
    acc = set() if acc is None else acc
    if isinstance(x, list):
        if x and x[0] == "quote":
            q = x[1]
            if isinstance(q, list): acc |= {s for s in q if isinstance(s, str)}
            else: acc.add(q)
        else:
            for y in x: consts_in(y, acc)
    return acc

def free_vars(form, bound=()):
    """Variables of an axiom body: symbols that are not function heads, constants, or t/nil."""
    vs = set()
    def walk(x, pos):
        if isinstance(x, list):
            if not x: return
            if x[0] == "quote": return
            for i, y in enumerate(x): walk(y, i)
        elif isinstance(x, str) and pos != 0 and x.lower() not in ("t", "nil"):
            vs.add(x)
    walk(form, 1)
    return sorted(vs)

def holds(world, form, universe):
    """Universal closure of `form` over the finite universe."""
    vs = free_vars(form)
    for vals in itertools.product(universe, repeat=len(vs)):
        if not truthy(world.ev(form, dict(zip(vs, vals)))):
            return False, dict(zip(vs, vals))
    return True, None

def stub_points(world, form, env, stubnames, acc, depth=0):
    """All (stub, argvals) applications reachable from `form` at `env`,
    descending into core defuns (inlining their bodies)."""
    if depth > 6 or not isinstance(form, list) or not form or form[0] == "quote":
        return
    head = form[0].lower() if isinstance(form[0], str) else None
    if head in stubnames:
        try: acc.add((head, tuple(world.ev(y, env) for y in form[1:])))
        except KeyError: pass
    elif head in world.fns and head not in stubnames:
        params, body = world.fns[head]
        try:
            sub = dict(zip(params, [world.ev(y, env) for y in form[1:]]))
            stub_points(world, body, sub, stubnames, acc, depth + 1)
        except KeyError: pass
    for y in form[1:]:
        stub_points(world, y, env, stubnames, acc, depth)

def flips_for(world, form, universe, stubnames):
    """Candidate flips (single stub point, then pairs) that could make `form`
    false: every stub application reachable at every point of the universe."""
    vs = free_vars(form)
    points, pairs = set(), []
    for vals in itertools.product(universe, repeat=len(vs)):
        local = set()
        stub_points(world, form, dict(zip(vs, vals)), stubnames, local)
        points |= local
        loc = sorted(local)
        # pairs only among stub points reachable at the SAME witness point
        for a, b in itertools.combinations(loc, 2):
            pairs.append(((a[0], a[1], not truthy(world.call(a[0], list(a[1])))),
                          (b[0], b[1], not truthy(world.call(b[0], list(b[1]))))))
    singles = [((name, argvals, not truthy(world.call(name, list(argvals)))),) for name, argvals in sorted(points)]
    return singles + pairs[:20000]

def call_base(self, name, argvals):
    params, body = self.fns[name]
    return self.ev(body, dict(zip(params, argvals)))
World.call_base = call_base

def flipped(world, flips):
    """World with each (name, argvals, newval) in `flips` overridden."""
    w = World.__new__(World); w.fns = world.fns; w.consts = world.consts; w.strict = world.strict
    w.overrides = dict(world.overrides)
    for name, argvals, newval in flips:
        prev = w.overrides.get(name)
        def ov(av, _a=tuple(argvals), _v=newval, _prev=prev, _n=name):
            if tuple(av) == _a: return _v
            return _prev(av) if _prev else call_base(world, _n, av)
        w.overrides[name] = ov
    return w

# ------------------------------------------------------------ main
def audit_theory(tag, party, worlddict, books, use_acl2):
    stubs, defuns, sigs, constraints, axioms = G.collect(books)
    stubnames = {n.lower() for n, _ in stubs} | {n.lower() for n, _ in sigs}
    world = World(worlddict, stubs, sigs, defuns)
    universe = sorted(world.consts | {"other-symbol"})
    items = [("constraint", b, n, f) for b, n, f in constraints] + [("axiom", b, n, f) for b, n, f in axioms]
    # sanity: base world satisfies all (must agree with the certified book)
    for kind, b, n, f in items:
        ok, cx = holds(world, f, universe)
        assert ok, f"base world violates {n} at {cx} — evaluator disagrees with certified audit"
    results = []
    for kind, b, n, f in items:
        if kind != "axiom":
            continue
        verdict, broken, flip_used = "no-flip-found", [], None
        best = None
        for flips in flips_for(world, f, universe, stubnames):
            w = flipped(world, flips)
            okA, cx = holds(w, f, universe)
            if okA:  # flip did not falsify A
                continue
            witness = {k: v for k, v in (cx or {}).items()}
            desc = " & ".join(f"{name}{list(argvals)} := {'t' if newval else 'nil'}" for name, argvals, newval in flips)
            br = [m for k2, b2, m, f2 in items if m != n and not holds(w, f2, universe)[0]]
            if not br:
                verdict, broken, flip_used, flip_struct, wit = "independent", [], desc, [[name, list(argvals), bool(newval)] for name, argvals, newval in flips], witness
                break
            if best is None or len(br) < len(best[1]):
                best = (desc, br, [[name, list(argvals), bool(newval)] for name, argvals, newval in flips], witness)
        if verdict != "independent" and best:
            verdict, flip_used, broken, flip_struct, wit = "coupled", best[0], best[1], best[2], best[3]
        if verdict == "no-flip-found": flip_struct, wit = [], {}
        # witnesses for the coupled axioms (where they fail in the flipped world)
        bw = {}
        if flip_struct:
            w = flipped(world, [(a, tuple(b_), c) for a, b_, c in flip_struct])
            for k2, b2, m, f2 in items:
                if m in broken:
                    ok2, cx2 = holds(w, f2, universe); bw[m] = cx2 or {}
        results.append({"axiom": n, "book": b, "verdict": verdict, "flip": flip_used, "flips": flip_struct, "witness": wit, "breaks": broken, "break_witnesses": bw})
    if use_acl2:
        for r in results:
            r["acl2_redundancy"] = acl2_redundancy(tag, r["axiom"], books, items)
    return results

def acl2_redundancy(tag, target, books, items):
    """Assert every other axiom/constraint of the theory as a defaxiom over the
    REAL stubs (fresh session, core + text/fact books excluded: we re-assert
    their axioms too), then attempt `target` as a defthm with a time limit."""
    forms = ['(in-package "ACL2")', '(include-book "federal_save_act_core")',
             '(include-book "federal_save_act_hinge_common" :dir :system)' if False else '']
    # encapsulate signatures must exist: declare them as defstubs
    sigs = [s for b in books for f in G.read_forms(MODEL / f"{b}.lisp") if isinstance(f, list) and f and f[0].lower() == "encapsulate" for s in f[1]]
    for s in sigs:
        forms.append(f"(defstub {s[0]} {G.show(s[1])} t)")
    tf = None
    for kind, b, n, f in items:
        if n == target: tf = f; continue
        forms.append(f"(defaxiom aux-{n} {G.show(f)})")
    forms.append(f"(with-prover-time-limit 8 (defthm target-{target} {G.show(tf)} :rule-classes nil))")
    src = "\n".join(forms) + "\n"
    with tempfile.NamedTemporaryFile("w", suffix=".lisp", dir=MODEL, delete=False) as fh:
        fh.write(src); path = Path(fh.name)
    try:
        p = subprocess.run(["acl2"], input=f'(ld "{path.name}" :ld-error-action :return)\n', capture_output=True, text=True, cwd=MODEL, timeout=300)
        out = p.stdout
        if re.search(rf"TARGET-{re.escape(target.upper())}\b", out) and "Q.E.D." in out.split(f"TARGET-{target.upper()}")[-1][:4000] and "******** FAILED" not in out.split(f"TARGET-{target.upper()}")[-1][:4000]:
            return "redundant (ACL2 proved it from the others)"
        return "not provable from the others within 8s"
    finally:
        path.unlink(missing_ok=True)

def main():
    use_acl2 = "--acl2" in sys.argv
    report = {}
    for tag, (party, world, books) in G.THEORIES.items():
        report[party] = audit_theory(tag, party, world, books, use_acl2)
    # markdown
    md = ["# Adversarial audit of the party trusted bases", "",
          "For each axiom A: flip exactly one stub value so A is false, and check whether every OTHER axiom of the theory still holds (complete finite-model check over the audit worlds). "
          "**independent** = the flipped world is a model of the rest ∧ ¬A. **coupled** = the flip also falsifies the listed axioms — these clusters are the theory's load-bearing joints (hinges). "
          + ("**ACL2 redundancy** = one ACL2 session per axiom attempts to prove A from the others; a success is a kernel-checked certificate that A is deletable." if use_acl2 else "Run with `--acl2` to add kernel-checked redundancy attempts."), ""]
    for party, rs in report.items():
        n_ind = sum(r["verdict"] == "independent" for r in rs); n_c = sum(r["verdict"] == "coupled" for r in rs); n_nf = sum(r["verdict"] == "no-flip-found" for r in rs)
        md += [f"## {party.capitalize()} theory — {len(rs)} axioms: {n_ind} independent, {n_c} coupled, {n_nf} no single-stub flip", "",
               "| Axiom | Verdict | Flip used | Breaks" + (" | ACL2 redundancy" if use_acl2 else "") + " |", "|---|---|---|---" + ("|---" if use_acl2 else "") + "|"]
        for r in rs:
            md.append(f"| `{r['axiom']}` | **{r['verdict']}** | `{r['flip'] or '—'}` | {', '.join('`'+b+'`' for b in r['breaks']) or '—'}" + (f" | {r.get('acl2_redundancy','')}" if use_acl2 else "") + " |")
        md.append("")
    md += ["## Reading the clusters", "",
           "A *coupled* verdict is not an error. It says the theory's axioms are not all free to vary independently: the listed axioms must move together. "
           "In the challenger theory the bridge rules and the scenario facts that instantiate them form one such joint; in the government theory the six-factor defense and its bridge form another. "
           "These joints are exactly the premises the explorer's presets toggle together, and the pivot theorems in `core` state the logic of each joint once.", ""]
    if "--check" in sys.argv:
        old = json.loads(OUT_JSON.read_text()) if OUT_JSON.exists() else {}
        strip = lambda rep: {k: [{x: r[x] for x in ("axiom", "verdict", "breaks", "flips")} for r in v] for k, v in rep.items()}
        if strip(old) != strip(report):
            print("STALE: reports/adversarial_audit.json verdicts differ from a fresh run — rerun tools/adversarial_audit.py --acl2"); return 1
        print("OK: adversarial audit verdicts match"); return 0
    OUT_JSON.write_text(json.dumps(report, indent=2) + "\n"); OUT_MD.write_text("\n".join(md) + "\n")
    for party, rs in report.items():
        print(party, {k: sum(r["verdict"] == k for r in rs) for k in ("independent", "coupled", "no-flip-found")},
              ({"redundant": sum(str(r.get("acl2_redundancy","")).startswith("redundant") for r in rs)} if use_acl2 else ""))
    return 0

if __name__ == "__main__":
    sys.exit(main())
