# Axiom Pressure Report — v5.2

## Summary

| Metric | v5.1 | v5.2 | Change |
|---|---|---|---|
| Total defaxioms | 33 | 33 | 0 |
| Total defthms | 83 | 126 | +43 (+52%) |
| defun (executable) | 15 | 24 | +9 |
| defun-sk (existential) | 3 | 4 | +1 |
| encapsulate blocks | 3 | 4 | +1 |
| Derived burden predicates replacing assumptions | 0 | 5 | +5 |

## What v5.2 Changed About Axiom Pressure

v5.2 did NOT reduce the raw defaxiom count (33 remains). Instead, it:

1. **Derived 5 burden predicates** (`lacks-all-qualifying-documentsp`, `material-burdenp`, `no-adequate-alternative-forp`, `denial-riskp`, `severe-burdenp-derived`) as executable `defun` — these REPLACE the need to assume burden conclusions directly.

2. **Added 43 new theorems** that derive conclusions from lower-level inputs rather than asserting them.

3. **Added 1 new encapsulate** (Anderson-Burdick doctrinal standard) with local witnesses proving consistency.

4. **Added 1 new defun-sk** (`exists-citizen-facing-discretionary-denialp`) for discretionary-denial existential.

## Defaxiom Classification (unchanged from v5.1)

| Label | Count | % | Risk Level |
|---|---|---|---|
| SCENARIO_FACT | 14 | 42% | Low — stipulated ground facts |
| INTERPRETATION_GOVERNMENT | 6 | 18% | Medium — party-specific readings |
| BRIDGE_RULE | 5 | 15% | Low — structural connectors |
| EMPIRICAL_ASSUMPTION | 3 | 9% | **High** — contestable factual claims |
| INTERPRETIVE_ASSUMPTION | 2 | 6% | Medium — hinge semantics |
| DOCTRINAL_RULE | 2 | 6% | Medium — case law holdings |
| INTERPRETATION_CHALLENGER | 1 | 3% | Medium — party-specific reading |

## Highest-Risk Remaining Axioms

| Axiom | File | Risk | Why It Remains |
|---|---|---|---|
| `challenger-scenario-no-fault` | challenger | **HIGH** | Empirical claim about 18,000+ applicants; could be contested with different data |
| `challenger-scenario-material-burden` | challenger | **HIGH** | Empirical claim about burden severity; Crawford plurality, not holding |
| `government-burden-not-severe` | government | **HIGH** | Empirical counter-claim; directly contradicts challenger's burden claim |
| `challenger-scenario-alternative-process-denied` | challenger | MEDIUM | Interpretive — depends on mandatory vs. discretionary reading |
| `government-scenario-alternative-process-approved` | government | MEDIUM | Interpretive — depends on mandatory vs. discretionary reading |

## Replacement Paths

| Current Axiom | Possible Replacement | Blocked By |
|---|---|---|
| `challenger-scenario-no-fault` | External empirical evidence record | No formal empirical data format |
| `challenger-scenario-material-burden` | Derivation from `material-burdenp` defun chain | Already partially replaced in v5.2 |
| `government-burden-not-severe` | Contestable predicate guard | Requires refactoring government model |
| Scenario facts (14) | Parameterized test framework | Requires v6+ generalization |
| Bridge rules (5) | Direct encapsulate constraints | Inherent to hybrid architecture |

## Conclusion

The axiom pressure has not decreased in count but has significantly decreased in **dependency scope**. In v5.1, burden conclusions were assumed. In v5.2, they are derived from 5 executable predicates. The 33 remaining axioms are:
- 14 obviously-consistent scenario stipulations
- 5 structural bridge rules
- 11 interpretive/empirical/doctrinal claims (the genuine trusted base)
- 2 hinge semantics (mutually exclusive by design)
- 1 text fact

## Trusted-Base Summary for Reviewers

### What is proved by ACL2 (no axioms needed)

- 126 theorems, including 5 induction proofs over traces, 3+ induction proofs over document lists
- 24 executable functions (defun) — state machine, document recognizers, burden derivation chain
- 4 defun-sk existential propositions with Skolemized witnesses
- 4 encapsulate blocks with local witnesses proving consistency
- All top 5 theorems depend on **zero axioms** — see `TOP_5_THEOREMS.md`

### What is assumed from public source text (low risk)

- 1 text fact: the SAVE Act is a law
- 14 scenario facts: citizen-a's properties (person, citizen, eligible, etc.)
- 5 bridge rules: structural connectors between encapsulate predicates and core defstubs

### What remains empirical (high risk — contestable)

- `challenger-scenario-no-fault`: citizens lack documents through no fault (Fish v. Kobach)
- `challenger-scenario-material-burden`: cannot obtain documents without material burden (Crawford plurality)
- `government-burden-not-severe`: burden is not severe (Crawford plurality)

### What remains interpretive (medium risk — depends on statutory reading)

- `challenger-scenario-alternative-process-denied`: alternative process denies citizen-a (discretionary reading)
- `government-scenario-alternative-process-approved`: alternative process approves citizen-a (mandatory reading)

### What remains doctrinal (medium risk — depends on case law application)

- `government-election-integrity-interest`: election integrity is an important interest (Crawford)
- `government-important-interest`: the government interest is important (Crawford)

### What is now derived rather than assumed (v5.2 improvement)

- `material-burdenp` — derived from `lacks-all-qualifying-documentsp` + `cannot-obtain...`
- `denial-riskp` — derived from `material-burdenp` + `no-adequate-alternative-forp`
- `severe-burdenp-derived` — derived from full chain
- Anderson-Burdick doctrinal standard — encapsulated with local witnesses
- Burden-class existence claims — derived from defun-sk existentials

