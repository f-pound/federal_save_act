# The audits — what is checked, and what it means

This project asks a theorem prover to check legal arguments. That raises an obvious question: *who checks the assumptions?* Three automated audits answer it. All run in CI on every commit; all are reproducible locally.

## 1. Certification (what ACL2 proves)

Every `defthm` in `model/` is proved by ACL2 from definitions and the stated axioms. **374 theorems, 31 books.** A theorem that fails to prove fails the build.

## 2. Consistency audit — "could all of these assumptions be true at once?"

Plain English: a party's argument is a list of premises. Even if each premise sounds reasonable, a list can contradict itself (Vero, a 2026 benchmark of AI-written proofs, found that 45% of the defects in carefully reviewed formal specifications were of this kind — a missing condition that made two statements incompatible). ACL2's `defaxiom` does **not** check this: it will happily accept a contradictory set and then prove anything from it.

So `tools/gen_consistency_audit.py` builds, for each party, a small concrete "toy world" — a handful of named people, one application, two ballots, one law — gives every predicate an explicit definition in that world, and then **proves every axiom and every interpretive rule of that party as a theorem about the world**. If the generated book certifies, the party's entire trusted base is satisfiable.

Result: challenger 44 axioms + 7 rules — satisfiable. Government 50 + 5 — satisfiable. The two cannot share a world (a one-line propositional theorem records why).

For academics: this is a finite model construction; the book `federal_save_act_consistency_audit.lisp` is neutral (no axioms) and kernel-checked.

## 3. Adversarial audit — "which assumptions are doing the work?"

Plain English: confirming that the premises *can* all be true is not enough. The interesting question is which premises are **load-bearing**. `tools/adversarial_audit.py` takes each axiom in turn, **makes it false** by changing exactly one fact in the toy world, and then checks whether all the *other* axioms still hold. Three verdicts:

| Verdict | Meaning | What it tells a reader |
|---|---|---|
| **independent** | A can be denied without disturbing any other premise | A is a genuinely separate choice; toggling it in the explorer is meaningful on its own |
| **coupled** | denying A also falsifies the listed premises | those premises form a *joint* — they must move together. Joints are the hinges of the argument |
| **redundant** | ACL2 proves A from the other premises | A was never an assumption; it could be deleted |

Result (v6.8): challenger 43 independent, 1 coupled, 0 redundant; government 49 independent, 1 coupled, 0 redundant. The single joint on each side is the project's central hinge, rediscovered mechanically:

- challenger: *"the alternative process was denied for citizen-a"* ⇄ *"shall make a determination" is discretionary*
- government: *"the alternative process approved citizen-a"* ⇄ *"shall make a determination" is mandatory*

Nothing is redundant: every one of the 94 axioms carries weight.

The independence verdicts are a complete finite-model check by the tool's evaluator (over the same parsed axiom bodies and worlds the certified consistency-audit book uses). The redundancy verdicts are kernel-checked: one fresh ACL2 session per axiom asserts the others and attempts the axiom as a theorem. Full tables: `reports/adversarial_audit.md`. In the explorer, click any assumption: the details panel shows its verdict.

## 4. The other guards

- **Neutrality lint** — the neutral books (libraries, core, generated tables, structural invariants, audits) contain no `defaxiom`.
- **Proof-trivialising lint** — no `skip-proofs`, `defttag`, `defattach`, `progn!`, `include-raw`, `sys-call` anywhere.
- **Generated-book checks** — every book compiled from the clause IR, the audit book, the trusted-base report and the adversarial report must be byte-identical to what the generators produce.
- **Text stability** — every quoted statutory clause appears verbatim in both tracked bill texts.
- **`#print axioms` analogue** — `reports/trusted_base_by_book.md`: per book, the axioms any of its theorems could depend on, by decider.

## Why this matters for a template

A computational amicus brief for any statute will face the same questions: are the modeled premises consistent, which ones are hinges, and is any of them secretly a theorem of the others? These audits are statute-independent — they read the books, the worlds and the trace file — so a new project inherits them by inheriting the tools.
