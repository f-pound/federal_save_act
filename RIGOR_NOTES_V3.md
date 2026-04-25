# Rigor Notes — v3 (Hybrid Encapsulate Architecture)

## Summary of v3 Changes

Version 3 upgrades the Federal SAVE Act ACL2 stress-test to a **hybrid architecture** that uses `encapsulate` with local witness functions for interpretive predicates (where inconsistency risk is highest) and `defaxiom` for text-derived facts and scenario ground truths (where the constraints are self-evidently consistent).

**All models pass ACL2 certification** via Docker (`atwalter/acl2:latest`):

| Book | Theorems | Result |
|---|---|---|
| Consistency check | 13 | ✅ All Q.E.D. |
| Challenger model | 13 | ✅ All Q.E.D. (general: 270 steps, corollary: 41 steps) |
| Government model | 5 | ✅ All Q.E.D. (general: 282 steps, corollary: 55 steps) |

## Why This Hybrid Architecture?

### The Problem with Pure `defaxiom`

In ACL2, `defaxiom` adds a formula to the logical world as an unconditional axiom. The prover trusts it without proof. This creates a fundamental risk:

- **Inconsistency**: If two axioms contradict each other, ACL2 can prove anything (ex falso quodlibet). The system provides no warning — you simply get `Q.E.D.` for every theorem, including `nil`.
- **Undetectable without certification**: Without running `certify-book`, there is no way to check whether a set of `defaxiom` forms is jointly consistent.
- **Fragile under composition**: Adding a new `defaxiom` can silently break an existing consistent theory.

### Why Not Pure `encapsulate`?

An `encapsulate` block with an empty signature — `(encapsulate () ...)` — **cannot** prove ground facts about existing `defstub` functions. The `defstub` return values are unconstrained in the ACL2 logical world, so `(defthm witness (lawp 'federal-save-act))` is not provable from a `defstub`.

To use `encapsulate`, you must either:
1. **Introduce new constrained function signatures** inside the encapsulate (replacing the defstub), or
2. **Include the defstub in a single encapsulate** that introduces ALL functions together (a monolithic approach).

Option 1 is the correct modular approach. Option 2 works but loses the separation between core vocabulary and model-specific constraints.

### The Hybrid Solution

v3 uses each mechanism where it is most appropriate:

| Mechanism | Used for | Why safe |
|---|---|---|
| `defstub` | Neutral vocabulary (core) | No axioms — only introduces uninterpreted signatures |
| `defun` | Helper functions (core) | Definitions, not axioms — provably terminating |
| `defaxiom` | Text-derived facts, scenario ground truths | Self-evidently consistent stipulations about specific constants |
| `encapsulate` | Interpretive predicates (models) | New constrained functions with local witnesses proving consistency |
| `defaxiom` (bridge) | Connecting encapsulate predicates to core defstubs | Safe because they only fire when encapsulate-constrained predicates are satisfied |
| `defthm` | Intermediate lemmas and final proof obligations | Proved from the theory — the real test of the model |

The key insight: **the risk of inconsistency lies in interpretive axioms** (where the challenger and government make opposing claims), not in text-derived facts (which are direct statutory translations). `encapsulate` protects exactly where the risk is highest.

## Architecture Overview

```
federal_save_act_core.lisp          (defstub + defun: neutral vocabulary)
        │
federal_save_act_facts.lisp         (defaxiom: text-derived statutory rules)
        │
   ┌────┴────┐
   │         │
challenger   government
 model        model
   │         │
encapsulate  encapsulate
(new interp  (new defense
 predicates)  predicate)
   │         │
bridge rules bridge rules
(defaxiom)   (defaxiom)
   │         │
scenario     scenario
(defaxiom)   (defaxiom)
   │         │
lemma chain  lemma chain
(defthm)     (defthm)
   │         │
general thm  general thm
(defthm)     (defthm)
   │         │
citizen-a    citizen-a
corollary    corollary
(defthm)     (defthm)
```

### File Roles

| File | Mechanism | What it constrains |
|---|---|---|
| `core.lisp` | `defstub` + `defun` | Neutral vocabulary; no axioms |
| `facts.lisp` | `defaxiom` | Text-derived rules (prohibition, bridge rules) |
| `challenger_model.lisp` | `encapsulate` + `defaxiom` + `defthm` | Interpretive assumptions → bridge rules → scenario → proof |
| `government_model.lisp` | `encapsulate` + `defaxiom` + `defthm` | Defense assumptions → bridge rules → scenario → proof |
| `consistency_check.lisp` | `defthm` | Structural sanity checks on the core vocabulary |

## Key v3 Improvements

### 1. Possession ≠ Presentation

The statute says "presents documentary proof ... with the application." v3 separates:

- `has-documentary-proofp (x)` — person possesses qualifying documents
- `presents-documentary-proofp (p x)` — person presents documents with application `x`

The denial trigger now uses `presents-documentary-proofp`, which is the actual statutory requirement.

### 2. Completed Qualifying Document Helper

`has-any-qualifying-documentp` now includes all seven document categories:

1. REAL ID indicating citizenship
2. Valid U.S. passport
3. Military ID with U.S. birth record
4. Government photo ID showing U.S. birth
5. Government photo ID with supporting document
6. **Certified birth certificate** (added in v3)
7. **Naturalization certificate** (added in v3)

### 3. Factored Intermediate Predicates

Instead of one monolithic `constitutional-conflict-conditionp`, v3 introduces:

- `qualified-federal-voterp (p)` — person meets all voter qualifications
- `registration-transactionp (p x)` — person attempts to register via application
- `save-act-denial-triggerp (p x)` — the SAVE Act's denial condition fires

These give ACL2 smaller intermediate propositions to reason over.

### 4. Explicit Party Disagreement

The challenger model introduces new encapsulate-constrained predicates:
- `challenger-right-to-vote-establishedp`
- `challenger-undue-burden-establishedp`
- `challenger-regulation-invalidp`

The government model introduces:
- `government-defense-establishedp`

Both models also constrain core defstub predicates:

| Core Predicate | Challenger | Government |
|---|---|---|
| `lacks-qualifying-documents-through-no-faultp` | ✅ ON | (not asserted) |
| `cannot-obtain-qualifying-documents-without-material-burdenp` | ✅ ON | (not asserted) |
| `important-government-interestp` | (not asserted) | ✅ ON |
| `election-integrity-interestp` | (not asserted) | ✅ ON |
| `registration-procedure-evenhandedp` | (not asserted) | ✅ ON |
| `documentary-proof-requirement-rationally-connectedp` | (not asserted) | ✅ ON |
| `reasonable-registration-requirementp` | (not asserted) | ✅ ON |
| `adequate-alternative-processp` | (not asserted) | ✅ ON |

### 5. Generalized Theorems

Both models include generalized theorem obligations:

- **Challenger**: `challenger-conflict-general` (270 prover steps)
- **Government**: `government-no-conflict-general` (282 prover steps)

The concrete `citizen-a` theorems are corollaries.

### 6. Intermediate Lemma Chains

Both models include explicit intermediate lemmas that make the proof chain auditable:

**Challenger chain**:
1. `challenger-lemma-qualified-voter`
2. `challenger-lemma-right-established`
3. `challenger-lemma-protected-right`
4. `challenger-lemma-registration-transaction`
5. `challenger-lemma-undue-burden`
6. `challenger-lemma-regulation-invalid`
7. `challenger-lemma-not-valid-regulation`
8. `challenger-lemma-denial`

**Government chain**:
1. `government-lemma-defense-established`
2. `government-lemma-regulation-valid`

## Remaining Limitations

### 1. Hybrid defaxiom Usage

While interpretive predicates are protected by `encapsulate`, the **bridge rules** and **scenario facts** still use `defaxiom`. These are safe for the current models (self-evidently consistent ground truths), but adding new scenario facts could theoretically introduce inconsistency. A v4 upgrade could use a monolithic encapsulate that introduces ALL functions (including core defstubs) with a single comprehensive witness.

### 2. No Functional Instantiation

The generalized theorems are universal claims proved from the constrained axioms. A more rigorous approach would prove them via `functional-instantiation`, demonstrating the theorem holds for any functions satisfying the encapsulate constraints.

### 3. No Quantifier Depth

The models do not use `defun-sk` or `defchoose` for existentially quantified properties. All quantification is implicit in the universal scope of `defthm`.

## Next Steps (v4 Roadmap)

1. **Monolithic witness book**: A single encapsulate that introduces ALL functions with a comprehensive concrete witness, eliminating all `defaxiom` usage
2. **Functional instantiation**: Prove generalized theorems via `:functional-instance` hints
3. **Quantified properties**: Use `defun-sk` to express "there exists a citizen in class C who is denied"
4. **Poll tax theory**: Formalize the Amend. XXIV argument as a second independent proof chain
5. **Manner vs. qualification**: Formalize the Art. I §2 / Art. I §4 structural argument
6. **Due process / removal**: Model the § 8(k) removal process and procedural due process
7. **Multi-scenario testing**: Add `citizen-b` (naturalized citizen), `citizen-c` (Native American with tribal ID), etc.
