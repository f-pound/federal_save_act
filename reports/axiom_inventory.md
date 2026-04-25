# Axiom Inventory — Federal SAVE Act ACL2 Model (v5)

All 33 `defaxiom` events classified by label, source, and replacement path.

> [!NOTE]
> `defaxiom` is used to constrain existing `defstub` predicates. `encapsulate` introduces NEW function signatures. The hybrid architecture uses `defaxiom` only for text-derived facts, scenario stipulations, bridge rules, and interpretive assumptions — NOT for arbitrary legal conclusions.

## Facts Book (3 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `text-save-act-is-law` | TEXT_FACT | hr22-eh § 1 | Self-evident statutory declaration | None — correct as axiom |
| `text-save-act-documentary-proof-requirement` | PROHIBITION | hr22-eh § 2(b) | Constrains defstub `statute-denies-registrationp` | Could become defun if statute-denies were a defun |
| `text-documentary-proof-from-qualifying-documents` | BRIDGE_RULE | hr22-eh § 2(a) | Links defstubs `has-any-qualifying-documentp` → `has-documentary-proofp` | Could merge into defun if both predicates were concrete |

## Challenger Model (12 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `challenger-bridge-right-to-vote` | BRIDGE_RULE | const-amend5 | Links encapsulate predicate to defstub `protected-right-to-votep` | Inherent to hybrid architecture |
| `challenger-bridge-regulation-invalid` | BRIDGE_RULE | anderson-v-celebrezze | Links encapsulate predicate to defstub `valid-regulationp` | Inherent to hybrid architecture |
| `challenger-scenario-person` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None — correct as scenario axiom |
| `challenger-scenario-citizen` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-eligible` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-application` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-attempts-to-register` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-no-documentary-proof` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-no-presentation` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-no-fault` | EMPIRICAL_ASSUMPTION | fish-v-kobach | Empirical claim about burden — not derivable from statute | Make contestable: guard with explicit assumption predicate |
| `challenger-scenario-material-burden` | EMPIRICAL_ASSUMPTION | crawford-v-marion | Empirical claim about burden severity | Make contestable: guard with explicit assumption predicate |
| `challenger-scenario-alternative-process-denied` | INTERPRETATION_CHALLENGER | hr22-eh § 2(f) | Party-specific reading of "shall make a determination" | Replace with hinge_discretionary import |

## Government Model (16 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `government-bridge-defense-validates` | BRIDGE_RULE | crawford-v-marion | Links encapsulate predicate to defstub `valid-regulationp` | Inherent to hybrid architecture |
| `government-election-integrity-interest` | DOCTRINAL_RULE | crawford-v-marion | Crawford holding, not statutory text | Could become encapsulate constraint |
| `government-important-interest` | DOCTRINAL_RULE | crawford-v-marion | Crawford holding | Could become encapsulate constraint |
| `government-reasonable-requirement` | INTERPRETATION_GOVERNMENT | crawford-v-marion | Government's reading of Crawford | Party-specific interpretation book |
| `government-procedure-evenhanded` | INTERPRETATION_GOVERNMENT | burdick-v-takushi | Government's claim | Party-specific interpretation book |
| `government-rationally-connected` | INTERPRETATION_GOVERNMENT | crawford-v-marion | Government's claim | Party-specific interpretation book |
| `government-adequate-alternative` | INTERPRETATION_GOVERNMENT | hr22-eh § 2(f) | Government's reading of alternative process | Replace with hinge_mandatory import |
| `government-burden-not-severe` | EMPIRICAL_ASSUMPTION | crawford-v-marion | Empirical claim about burden severity | Make contestable |
| `government-scenario-person` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `government-scenario-citizen` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `government-scenario-eligible` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `government-scenario-application` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `government-scenario-attempts-to-register` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `government-assume-right-to-vote-arguendo` | INTERPRETATION_GOVERNMENT | n/a | Government concession for stronger proof | None — strengthens proof |
| `government-scenario-no-documentary-proof` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `government-scenario-alternative-process-approved` | INTERPRETATION_GOVERNMENT | hr22-eh § 2(f) | Party-specific reading of alternative process | Replace with hinge_mandatory import |

## Hinge Books (2 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `semantic-a-mandatory-approval` | INTERPRETIVE_ASSUMPTION | hr22-eh § 2(f) | Constrains defstub `alternative-process-approvedp` under Semantic A | Inherent — mutually exclusive with Semantic B |
| `semantic-b-discretionary-denial` | INTERPRETIVE_ASSUMPTION | hr22-eh § 2(f) | Constrains defstub `alternative-process-approvedp` under Semantic B | Inherent — mutually exclusive with Semantic A |

## Summary by Classification

| Label | Count | Description |
|---|---|---|
| SCENARIO_FACT | 14 | Stipulated test scenario ground facts |
| INTERPRETATION_GOVERNMENT | 6 | Government-favorable readings |
| BRIDGE_RULE | 5 | Links between encapsulate predicates and core defstubs |
| DOCTRINAL_RULE | 2 | Established case law holdings |
| EMPIRICAL_ASSUMPTION | 3 | Contestable factual claims about burden severity |
| INTERPRETIVE_ASSUMPTION | 2 | Competing hinge semantics |
| TEXT_FACT | 1 | Direct statutory text translation |
| PROHIBITION | 1 | Primary statutory prohibition |
| INTERPRETATION_CHALLENGER | 1 | Challenger-favorable reading |
| **Total** | **33** | |

## Observations

1. **14 SCENARIO_FACT axioms** (42%) are stipulated ground facts about `citizen-a`. These are inherently axiomatic — they define the test scenario. No replacement needed.
2. **5 BRIDGE_RULE axioms** (15%) are structural connectors between encapsulate-introduced predicates and core defstubs. These are inherent to the hybrid architecture.
3. **6 INTERPRETATION_GOVERNMENT + 1 INTERPRETATION_CHALLENGER** (21%) are party-specific legal judgments. These should eventually be fully separated into theory modules with explicit assumption guards.
4. **3 EMPIRICAL_ASSUMPTION axioms** (9%) are the most contestable — they assert factual claims about burden severity. Future versions should guard these with explicit `(empirical-assumption-activep ...)` predicates.
5. **2 INTERPRETIVE_ASSUMPTION axioms** (6%) are the hinge semantics — inherently axiomatic because they encode mutually exclusive readings of statutory text.
