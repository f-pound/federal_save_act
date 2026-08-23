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
OUT = MODEL / "federal_save_act_consistency_audit.lisp"

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
# Each world maps a stub / signature name -> (args, body).  Bodies are plain
# ACL2 over the scenario constants.  Anything not listed defaults to NIL.
PERSONS = "'(citizen-a citizen-b citizen-c citizen-d)"
REGISTERED = "'(citizen-b citizen-c citizen-d)"
COMMON = {
  "personp": ("(p)", f"(member-equal p {PERSONS})"),
  "citizen-of-usp": ("(p)", f"(member-equal p {PERSONS})"),
  "eligible-voterp": ("(p)", f"(member-equal p {PERSONS})"),
  "lawp": ("(law)", "(equal law 'federal-save-act)"),
  "voter-registration-applicationp": ("(x)", "(equal x 'registration-attempt-a)"),
  "attempts-to-registerp": ("(p x)", "(and (equal p 'citizen-a) (equal x 'registration-attempt-a))"),
  "protected-right-to-votep": ("(cs p)", f"(and (equal cs 'amend-v-equal-protection) (member-equal p {PERSONS}))"),
  "statute-denies-registrationp": ("(law p x)", f"(and (equal law 'federal-save-act) (member-equal p {PERSONS}) (equal x 'registration-attempt-a) (equal p 'citizen-a))"),
  "registered-voterp": ("(p)", f"(member-equal p {REGISTERED})"),
  "verified-noncitizen-informationp": ("(p)", "(equal p 'citizen-b)"),
  "statute-removes-registrantp": ("(law p)", f"(and (equal law 'federal-save-act) (member-equal p {REGISTERED}) (equal p 'citizen-b))"),
  "ballotp": ("(b)", "(member-equal b '(ballot-c ballot-d))"),
  "votes-in-personp": ("(p b)", "(or (and (equal p 'citizen-c) (equal b 'ballot-c)) (and (equal p 'citizen-d) (equal b 'ballot-d)))"),
  "cures-within-deadlinep": ("(p b)", "(and (equal p 'citizen-d) (equal b 'ballot-d))"),
  "statute-denies-regular-ballotp": ("(law p b)", f"(and (equal law 'federal-save-act) (member-equal p {REGISTERED}) (member-equal b '(ballot-c ballot-d)))"),
  "alternative-process-availablep": ("(p x)", "t"),
  "undue-burden-on-right-to-votep": ("(law p)", "t"),
  "document-acquisition-costp": ("(p)", "t"),
  "cost-functions-as-poll-taxp": ("(law p)", "t"),
  "attestation-evidence-satisfies-standardsp": ("(p x)", "nil"),
  "official-discretionary-denialp": ("(p x)", "nil"),
}
CHALLENGER = dict(COMMON, **{
  "valid-regulationp": ("(law x)", "nil"),
  "alternative-process-approvedp": ("(p x)", "nil"),
  "lacks-qualifying-documents-through-no-faultp": ("(p)", "t"),
  "cannot-obtain-qualifying-documents-without-material-burdenp": ("(p)", "t"),
  "alternative-process-discretionary-forp": ("(p x)", "t"),
  "substantial-risk-of-erroneous-denialp": ("(law p)", "t"),
  "severe-burden-on-plaintiffp": ("(law p)", "t"),
  "cannot-obtain-valid-photo-id-without-material-burdenp": ("(p)", "t"),
  "official-discretionary-denialp": ("(p x)", "t"),
  # encapsulate signatures (challenger theory)
  "challenger-right-to-vote-establishedp": ("(p)", f"(member-equal p {PERSONS})"),
  "challenger-undue-burden-establishedp": ("(law p)", "(equal law 'federal-save-act)"),
  "challenger-regulation-invalidp": ("(law x)", "(and (equal law 'federal-save-act) (equal x 'registration-attempt-a))"),
  "challenger-removal-due-process-violationp": ("(law p)", f"(and (equal law 'federal-save-act) (member-equal p {REGISTERED}))"),
  "challenger-voting-burden-establishedp": ("(law p)", f"(and (equal law 'federal-save-act) (member-equal p {PERSONS}))"),
})
GOVERNMENT = dict(COMMON, **{
  "valid-regulationp": ("(law x)", "t"),
  "alternative-process-approvedp": ("(p x)", "t"),
  "signs-attestation-under-perjuryp": ("(p)", "(equal p 'citizen-a)"),
  "submits-other-evidencep": ("(p)", "(equal p 'citizen-a)"),
  "official-determines-citizenshipp": ("(p)", "(equal p 'citizen-a)"),
  "attestation-evidence-satisfies-standardsp": ("(p x)", "(and (equal p 'citizen-a) (equal x 'registration-attempt-a))"),
  "important-government-interestp": ("(law)", "t"),
  "election-integrity-interestp": ("(law)", "t"),
  "registration-procedure-evenhandedp": ("(law)", "t"),
  "documentary-proof-requirement-rationally-connectedp": ("(law)", "t"),
  "reasonable-registration-requirementp": ("(law)", "t"),
  "adequate-alternative-processp": ("(law)", "t"),
  "burden-not-severep": ("(law p)", "t"),
  "removal-procedure-evenhandedp": ("(law)", "t"),
  "photo-id-requirement-evenhandedp": ("(law)", "t"),
  "provisional-cure-adequatep": ("(law)", "t"),
  # encapsulate signatures (government theory)
  "government-defense-establishedp": ("(law)", "t"),
  "government-removal-defense-establishedp": ("(law p)", "(equal p 'citizen-b)"),
  "government-voting-defense-establishedp": ("(law)", "t"),
})

THEORIES = {
  "c": ("challenger", CHALLENGER,
        ["federal_save_act_core", "federal_save_act_text_rules", "federal_save_act_voting_text_rules",
         "federal_save_act_facts", "federal_save_act_scenario", "federal_save_act_hinge_common",
         "federal_save_act_hinge_discretionary", "federal_save_act_challenger_model"]),
  "g": ("government", GOVERNMENT,
        ["federal_save_act_core", "federal_save_act_text_rules", "federal_save_act_voting_text_rules",
         "federal_save_act_facts", "federal_save_act_scenario", "federal_save_act_hinge_common",
         "federal_save_act_hinge_mandatory", "federal_save_act_government_model"]),
}

def emit():
    out = ['(in-package "ACL2")', '',
           ';' * 78,
           ';; federal_save_act_consistency_audit.lisp  —  GENERATED by tools/gen_consistency_audit.py',
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
        out.append(f';; --- {len(names)} stub / signature definitions ---')
        for n, args in stubs + sigs:
            a = show(args)
            spec = world.get(n.lower())
            argnames = [x for x in args]
            if spec:
                wargs, body = spec
                wnames = wargs.strip("()").split()
                assert len(wnames) == len(argnames), f"arity mismatch for {n}: world {wargs} vs stub {a}"
                used = [v for v in wnames if re.search(r"\b%s\b" % re.escape(v), body)]
                ign = [v for v in wnames if v not in used]
                decl = f" (declare (ignore {' '.join(ign)}))" if ign else ""
                out.append(f"(defun {mapping[n.lower()]} {wargs}{decl} (if {body} t nil))")
            else:
                decl = f" (declare (ignore {' '.join(argnames)}))" if argnames else ""
                out.append(f"(defun {mapping[n.lower()]} {a}{decl} nil)")
        out.append('')
        out.append(f';; --- {len(defuns)} core definitions over the world ---')
        for n, args, body in defuns:
            out.append(f"(defun {mapping[n.lower()]} {show(args)}\n  " + " ".join(show(subst(b, mapping)) for b in body) + ")")
        out.append('')
        items = [("constraint", b, n, f) for b, n, f in constraints] + [("axiom", b, n, f) for b, n, f in axioms]
        out.append(f';; --- {len(items)} audited propositions ({len(constraints)} encapsulate constraints, {len(axioms)} defaxioms) ---')
        for kind, b, n, f in items:
            out.append(f";; {kind} {n}  [{b}]")
            out.append(f"(defthm aud-{tag}-{n}\n  {show(subst(f, mapping))}\n  :rule-classes nil)")
        out.append('')
        stats[party] = {"stubs_and_sigs": len(names), "defuns": len(defuns), "constraints": len(constraints), "axioms": len(axioms)}
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
