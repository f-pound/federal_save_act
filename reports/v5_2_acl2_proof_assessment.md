# v5.2 ACL2 Proof Assessment

## Summary

v5.2 focuses on ACL2 proof legitimacy, not general-engine reusability. It deepens the Federal SAVE Act model through list induction, trace induction, burden derivation, doctrine chaining, encapsulated legal theories, and explicit trusted-base reporting.

**126 theorems. All Q.E.D. Zero failures.**

## ACL2 Event Census

| Event Type | v5.1 | v5.2 | Change |
|---|---|---|---|
| `defthm` | 83 | 126 | +43 (+52%) |
| `defun` | 15 | 24 | +9 |
| `defstub` | 45 | 45 | 0 |
| `defaxiom` | 33 | 33 | 0 |
| `defconst` | 26 | 26 | 0 |
| `defun-sk` | 3 | 4 | +1 |
| `encapsulate` | 3 | 4 | +1 |
| **Total events** | **208** | **262** | **+54 (+26%)** |
| **ACL2 books** | **12** | **17** | **+5** |

## Theorem Counts by Book

| Book | v5.1 | v5.2 | Technique |
|---|---|---|---|
| Consistency check | 16 | 16 | neutrality proofs |
| Process model | 19 | 19 | recursive list induction |
| Process invariants | 15 | 15 | trace induction, absorbing states |
| **Deep process invariants** | — | **9** | **trace induction, terminal stability, no-skip** |
| Hinge common | 4 | 4 | encapsulate |
| Hinge mandatory | 2 | 2 | defaxiom bridge |
| Hinge discretionary | 3 | 3 | defaxiom bridge |
| Existentials | 6 | **6** | defun-sk Skolemization |
| Independence | 3 | 3 | structural decomposition |
| Challenger model | 13 | 13 | encapsulate + bridge rules |
| Government model | 5 | 5 | encapsulate + bridge rules |
| **Document proofs** | — | **9** | **list induction, structural denial** |
| **Burden proofs** | — | **8** | **derivation chain, contrapositives** |
| **Doctrine proofs** | — | **7** | **conditional doctrine, encapsulate** |
| **Model consistency** | — | **7** | **compositional decomposition** |
| **Total** | **83** | **126** | |

## New Executable Functions (defun)

| Function | File | Purpose |
|---|---|---|
| `trace-passed-through-denial-statep` | deep_process_invariants | Denial-path tracker |
| `all-nonqualifying-documentsp` | document_proofs | Every doc fails qualification |
| `filter-qualifying-documents` | document_proofs | Filter to qualifying-only |
| `lacks-all-qualifying-documentsp` | burden_proofs | Lacks all qualifying docs |
| `material-burdenp` | burden_proofs | Derived material burden |
| `no-adequate-alternative-forp` | burden_proofs | No alternative process |
| `denial-riskp` | burden_proofs | Derived denial risk |
| `severe-burdenp-derived` | burden_proofs | Derived severe burden |
| `exists-citizen-facing-discretionary-denialp` | existentials | defun-sk |

## Proof Complexity Metrics

| Metric | v5.1 | v5.2 |
|---|---|---|
| Total certified theorems | 83 | 126 |
| Recursive functions | 7 | 10 |
| Induction proofs | 6 | 11 |
| `encapsulate` blocks | 3 | 4 |
| `defun-sk` propositions | 3 | 4 |
| Document-list theorems | 10 | 19 |
| Process-invariant theorems | 15 | 24 |
| Burden derivation theorems | 0 | 8 |
| Doctrine chain theorems | 0 | 7 |
| Model-consistency theorems | 0 | 7 |
| Source-traced propositions | 38 | 38 |

## v5.1 → v5.2 Improvement Summary

| Feature | v5.1 | v5.2 |
|---|---|---|
| Total theorems | 83 | 126 (+52%) |
| Induction proofs | 6 | 11 (+83%) |
| Executable functions | 15 | 24 (+60%) |
| Burden: assumed or derived? | Assumed (defaxiom) | **Derived (defun chain)** |
| Doctrine: encoded how? | Ad hoc bridge rules | **Anderson-Burdick encapsulate** |
| Document reasoning | Basic recognizers | **Collection-level structural proofs** |
| Process invariants | 15 | 24 (+60%) |
| Consistency checks | 3 (in independence) | **10 (dedicated book)** |
| Proof dependency tracking | Informal | **Formal report** |
| Axiom pressure analysis | Inventory only | **Pressure + replacement paths** |

## Why v5.2 Is Stronger Than v5.1

1. **Burden derivation replaces burden assumption.** The 5-step chain from `lacks-all-qualifying-documentsp` through `severe-burdenp-derived` is proved, not assumed. This means the burden conclusion is auditable — anyone can check which inputs feed into it.

2. **Doctrine chains use encapsulate.** The Anderson-Burdick standard is introduced via encapsulate with local witnesses proving consistency. The exported constraints show exactly what doctrinal assumptions are needed for each direction (challenger invalidity, government validity).

3. **Document reasoning is collection-level.** The all-nonqualifying-documents theorem proves that a bundle of nonqualifying documents CANNOT satisfy the statutory requirement — this is a structural denial theorem, not a scenario-specific one.

4. **Deeper process invariants.** No-skip, denial-path, and no-registration-without-submission are genuine process-verification results relevant to procedural due process.

5. **Explicit proof dependency reporting.** Each major theorem's dependency chain is documented: what ACL2 proved, what was assumed from text, what was assumed empirically, what was assumed doctrinally.

## Why This Is Still Not a Judicial Decision Engine

1. ACL2 does not evaluate burden MAGNITUDE — it proves boolean properties.
2. ACL2 does not weigh competing interests — it proves conditional implications.
3. ACL2 does not apply stare decisis — it proves structural consequences of formalized rules.
4. The empirical assumptions (burden severity, document obtainability) remain external inputs that courts and scholars must evaluate independently.
5. The model does not capture procedural history, amicus briefs, or legislative intent beyond the statutory text.

## Remaining Trusted Assumptions

- **33 defaxioms** (unchanged): 14 scenario, 5 bridge, 6 government-interpretive, 3 empirical, 2 hinge, 2 doctrinal, 1 challenger-interpretive
- **3 highest-risk**: `challenger-scenario-no-fault`, `challenger-scenario-material-burden`, `government-burden-not-severe`
- See `reports/axiom_pressure_report.md` for full analysis

## Next Proof-Theoretic Upgrades

1. **Parameterized scenario framework** — Replace citizen-a with parameterized test harness for multiple fact patterns
2. **Quantified burden severity** — Introduce ordinal burden levels with monotonicity theorems
3. **Two-world countermodel construction** — Explicit encapsulate blocks for World-G and World-C to strengthen independence proofs
4. **Refinement proofs** — Prove abstract process model refines concrete state machine
5. **Cross-statute comparison** — Apply architecture to other voter registration statutes

## Positioning

v5.2 does not build the future **A Computational Amicus Brief** engine. v5.2 strengthens the Federal SAVE Act proof development itself. The focus is on legitimate ACL2 theorem proving: recursive executable models, induction over traces and document lists, derived burden conclusions, doctrinal theorem chains, encapsulated theory components, source-traced trusted assumptions, and proof dependency reporting.

A future project may generalize these methods into **A Computational Amicus Brief**. For now, this repository remains focused on the Federal SAVE Act.
