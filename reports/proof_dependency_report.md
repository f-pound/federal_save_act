# Proof Dependency Report — v5.2

## Purpose

For each major final theorem, this report lists exactly what ACL2 proved, what was assumed, and the classification of each assumption. This allows legal professionals and ACL2 experts to evaluate the trusted base of each conclusion independently.

---

## 1. `challenger-model-finds-conflict`

**Conclusion**: Constitutional conflict exists for citizen-a under the challenger model.

**Status**: Q.E.D. (proved by ACL2)

### Dependency Chain

| Dependency | Classification | Source |
|---|---|---|
| `challenger-scenario-person` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-citizen` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-eligible` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-application` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-attempts-to-register` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-no-documentary-proof` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-no-presentation` | SCENARIO_FACT | Stipulated |
| `challenger-scenario-no-fault` | EMPIRICAL_ASSUMPTION | Fish v. Kobach |
| `challenger-scenario-material-burden` | EMPIRICAL_ASSUMPTION | Crawford plurality |
| `challenger-scenario-alternative-process-denied` | INTERPRETATION_CHALLENGER | SAVE Act § 2(f) |
| `challenger-bridge-right-to-vote` | BRIDGE_RULE | Const. Amend. V |
| `challenger-bridge-regulation-invalid` | BRIDGE_RULE | Anderson v. Celebrezze |
| `text-save-act-documentary-proof-requirement` | PROHIBITION | H.R. 22 § 2(b) |
| `text-documentary-proof-from-qualifying-documents` | BRIDGE_RULE | H.R. 22 § 2(a) |
| `challenger-fundamental-right-rule` | PROVED (encapsulate) | — |
| `challenger-documentary-proof-is-undue-burden` | PROVED (encapsulate) | — |
| `challenger-undue-burden-defeats-regulation` | PROVED (encapsulate) | — |
| `challenger-lemma-*` (8 intermediate lemmas) | PROVED | — |

### What ACL2 Proved
- Given the 14 assumptions above, constitutional conflict follows as a logical necessity.
- The encapsulate proves that the interpretive rules are jointly consistent.

### What ACL2 Did NOT Prove
- That citizen-a actually exists.
- That the burden IS material (empirical question).
- That the alternative process IS denied (interpretive question).

---

## 2. `government-model-no-conflict`

**Conclusion**: No constitutional conflict exists for citizen-a under the government model.

**Status**: Q.E.D. (proved by ACL2)

### Dependency Chain

| Dependency | Classification | Source |
|---|---|---|
| `government-scenario-person` | SCENARIO_FACT | Stipulated |
| `government-scenario-citizen` | SCENARIO_FACT | Stipulated |
| `government-scenario-eligible` | SCENARIO_FACT | Stipulated |
| `government-scenario-application` | SCENARIO_FACT | Stipulated |
| `government-scenario-attempts-to-register` | SCENARIO_FACT | Stipulated |
| `government-scenario-no-documentary-proof` | SCENARIO_FACT | Stipulated |
| `government-assume-right-to-vote-arguendo` | INTERPRETATION_GOVERNMENT | Concession |
| `government-scenario-alternative-process-approved` | INTERPRETATION_GOVERNMENT | SAVE Act § 2(f) |
| `government-election-integrity-interest` | DOCTRINAL_RULE | Crawford |
| `government-important-interest` | DOCTRINAL_RULE | Crawford |
| `government-reasonable-requirement` | INTERPRETATION_GOVERNMENT | Crawford |
| `government-procedure-evenhanded` | INTERPRETATION_GOVERNMENT | Burdick v. Takushi |
| `government-rationally-connected` | INTERPRETATION_GOVERNMENT | Crawford |
| `government-adequate-alternative` | INTERPRETATION_GOVERNMENT | Crawford |
| `government-burden-not-severe` | EMPIRICAL_ASSUMPTION | Crawford plurality |
| `government-bridge-defense-validates` | BRIDGE_RULE | Crawford |
| `government-valid-regulation-rule` | PROVED (encapsulate) | — |
| `government-lemma-*` (2 intermediate lemmas) | PROVED | — |

### What ACL2 Proved
- Given the 16 assumptions above, no constitutional conflict exists.
- The government defeats the conflict via TWO independent paths: (a) valid regulation, (b) alternative process approved.

### What ACL2 Did NOT Prove
- That the government's interest IS important (doctrinal question).
- That the burden is NOT severe (empirical question).
- That the alternative process IS adequate (interpretive question).

---

## 3. `conflict-condition-pivots-on-valid-regulation`

**Conclusion**: Given all other preconditions, the conflict condition is logically equivalent to `(not (valid-regulationp law x))`.

**Status**: Q.E.D. (proved by ACL2)

### Dependency Chain

| Dependency | Classification |
|---|---|
| Definition of `constitutional-conflict-conditionp` | PROVED (defun) |
| Definition of `qualified-federal-voterp` | PROVED (defun) |
| Definition of `registration-transactionp` | PROVED (defun) |

### What ACL2 Proved
- Pure structural theorem — depends only on executable definitions, not assumptions.
- This is the strongest type of ACL2 proof: no axioms in the dependency chain.

---

## 4. `full-burden-chain` (v5.2 new)

**Conclusion**: Lacks documents + cannot obtain + no alternative → severe burden (derived).

**Status**: Q.E.D. (proved by ACL2)

### Dependency Chain

| Dependency | Classification |
|---|---|
| `lacks-all-qualifying-documentsp` | PROVED (defun) |
| `material-burdenp` | PROVED (defun) |
| `denial-riskp` | PROVED (defun) |
| `severe-burdenp-derived` | PROVED (defun) |
| `cannot-obtain-qualifying-documents-without-material-burdenp` | defstub (empirical input) |
| `alternative-process-approvedp` | defstub (interpretive input) |

### What ACL2 Proved
- The burden derivation chain is structurally correct.
- The derived conclusion follows from 5 executable definitions + 2 unconstrained inputs.
- No axioms in the direct dependency chain — only defun and defstub.

---

## 5. `registered-implies-prior-acceptance-path` (v5.1)

**Conclusion**: Any trace reaching registered must have passed through doc-accepted or alt-approved.

**Status**: Q.E.D. (proved by induction)

### Dependency Chain

| Dependency | Classification |
|---|---|
| `reg-next-state` | PROVED (defun) |
| `reg-run-trace` | PROVED (defun) |
| `trace-passed-through-acceptance-statep` | PROVED (defun) |
| `register-requires-acceptance-state` | PROVED (case analysis) |

### What ACL2 Proved
- Pure structural theorem — no axioms, no assumptions.
- Proved by induction over the event list.
- This is genuine process-verification work.

---

## 6. `denied-implies-prior-denial-path` (v5.2)

**Conclusion**: Any trace from a non-denied start that reaches denied must have passed through a denial-triggering state (doc-rejected, alt-denied, or submitted).

**Status**: Q.E.D. (proved by induction)

### Dependency Chain

| Dependency | Classification |
|---|---|
| `reg-next-state` | EXECUTABLE_DEFINITION |
| `reg-run-trace` | EXECUTABLE_DEFINITION |
| `trace-passed-through-denial-statep` | EXECUTABLE_DEFINITION |
| `denied-requires-denial-state` | PROVED (case analysis) |

### What ACL2 Proved
- Pure structural theorem — no axioms, no assumptions.
- Proved by induction over the event list.
- Denial-side dual of `registered-implies-prior-acceptance-path`.

---

## Summary: Assumption Counts by Final Theorem

| Final Theorem | Axioms Used | Encapsulate Rules | Definitions | Classification |
|---|---|---|---|---|
| challenger-model-finds-conflict | 14 | 3 | 4 | Conditional legal conclusion |
| government-model-no-conflict | 16 | 1 | 4 | Conditional legal conclusion |
| conflict-condition-pivots-on-valid-regulation | 0 | 0 | 3 | Structural theorem |
| full-burden-chain | 0 | 0 | 5 | Structural derivation |
| registered-implies-prior-acceptance-path | 0 | 0 | 3 | Process invariant |
| denied-implies-prior-denial-path | 0 | 0 | 4 | Process invariant |

