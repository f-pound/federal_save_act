# Axiom Inventory — Federal SAVE Act ACL2 Model (v6.5)

All 52 `defaxiom` events classified by label, source, and replacement path.

> [!NOTE]
> `defaxiom` is used to constrain existing `defstub` predicates. `encapsulate` introduces NEW function signatures. The hybrid architecture uses `defaxiom` only for text-derived facts, scenario stipulations, bridge rules, and interpretive assumptions — NOT for arbitrary legal conclusions.

## Text Rules (generated, 2 axioms) + Facts Book (2 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `text-save-act-is-law` | TEXT_FACT | hr22-eh § 1 | Self-evident statutory declaration | None — correct as axiom |
| `text-save-act-documentary-proof-requirement` | PROHIBITION | hr22-eh § 2(b), § 2(d), § 2(f) | Constrains defstub `statute-denies-registrationp`; **generated** into `federal_save_act_text_rules.lisp` from the clause IR together with its ACE | Could become defun if statute-denies were a defun |
| `text-save-act-removal-upon-verified-information` | PROHIBITION | hr22-eh § 2(f) / NVRA § 8(k) | Constrains defstub `statute-removes-registrantp`; **generated** with its ACE | None — direct text |
| `text-documentary-proof-from-qualifying-documents` | BRIDGE_RULE | hr22-eh § 2(a) | Links defstubs `has-any-qualifying-documentp` → `has-documentary-proofp` | Could merge into defun if both predicates were concrete |

## Scenario Book (6 axioms) — shared by both party models

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `scenario-person` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None — correct as scenario axiom |
| `scenario-citizen` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `scenario-eligible` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `scenario-application` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `scenario-attempts-to-register` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `scenario-no-documentary-proof` | SCENARIO_FACT | n/a | Stipulated scenario ground fact (conceded by both parties) | None |

## Scenario B — erroneous § 8(k) removal (7 axioms, shared)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `scenario-b-person` / `-citizen` / `-eligible` / `-registered` | SCENARIO_FACT | n/a | Stipulated ground facts about citizen-b | None |
| `scenario-b-verified-noncitizen-information` | SCENARIO_FACT (**high-risk**) | n/a | The State holds "verified information" that is in fact erroneous | Contest by disputing the error rate of § 8(j)(4) database matches |
| `scenario-b-no-notice` / `-no-hearing` | SCENARIO_FACT | n/a | Consistent with the statutory path (no notice/hearing edge in § 8(k)) | A State may add notice by practice — toggle in the explorer |

## Voting Text Rule (generated, 1 axiom) — SAVE America Act § 3

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `text-photo-id-required-for-regular-ballot` | PROHIBITION | s1383-eah § 3 / HAVA § 303A(a)(1)(A) | Constrains defstub `statute-denies-regular-ballotp`; generated with its ACE | None — direct text |

## Scenario C — citizen-c at the polls (8 axioms, shared)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `scenario-c-person` / `-citizen` / `-eligible` / `-registered` / `-ballot` / `-votes-in-person` | SCENARIO_FACT | n/a | Stipulated ground facts | None |
| `scenario-c-no-valid-photo-id` / `-no-cure` | SCENARIO_FACT | n/a | Presents nothing in § 303A(c); does not cure within 3 days | A second voting scenario (expired licence + cure) would exercise the cure path |

## Challenger Model (9 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `challenger-bridge-right-to-vote` | BRIDGE_RULE | const-amend5 | Links encapsulate predicate to defstub `protected-right-to-votep` | Inherent to hybrid architecture |
| `challenger-bridge-regulation-invalid` | BRIDGE_RULE | anderson-v-celebrezze | Links encapsulate predicate to defstub `valid-regulationp` | Inherent to hybrid architecture |
| `challenger-scenario-no-presentation` | SCENARIO_FACT | n/a | Stipulated scenario ground fact | None |
| `challenger-scenario-no-fault` | EMPIRICAL_ASSUMPTION | fish-v-kobach | Empirical claim about burden — not derivable from statute | Make contestable: guard with explicit assumption predicate |
| `challenger-scenario-material-burden` | EMPIRICAL_ASSUMPTION | crawford-v-marion | Empirical claim about burden severity | Make contestable: guard with explicit assumption predicate |
| `challenger-bridge-removal-invalid` | BRIDGE_RULE | const-amend5 | Links `challenger-removal-due-process-violationp` to `(not (valid-regulationp law p))` | Inherent to hybrid architecture |
| `challenger-bridge-voting-invalid` | BRIDGE_RULE | anderson-v-celebrezze | Severe as-applied burden ⇒ not valid for that ballot | Inherent |
| `challenger-scenario-c-material-burden` | EMPIRICAL_ASSUMPTION (**high-risk**) | crawford-v-marion | citizen-c cannot obtain an expiring photo ID without material burden | Contest with state ID-issuance data |
| `challenger-scenario-alternative-process-denied` | INTERPRETATION_CHALLENGER | hr22-eh § 2(f) | Party-specific reading of "shall make a determination" | Replace with hinge_discretionary import |

## Government Model (15 axioms)

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
| `government-assume-right-to-vote-arguendo` | INTERPRETATION_GOVERNMENT | n/a | Government concession for stronger proof | None — strengthens proof |
| `government-bridge-removal-validates` | BRIDGE_RULE | crawford-v-marion | Links `government-removal-defense-establishedp` to `valid-regulationp law p` | Inherent |
| `government-removal-procedure-evenhanded` | INTERPRETATION_GOVERNMENT | hr22-eh § 8(k) | Government's claim that the verified-information trigger is evenhanded | Party-specific |
| `government-bridge-voting-validates` | BRIDGE_RULE | crawford-v-marion | Voting defense ⇒ valid for every ballot | Inherent |
| `government-photo-id-evenhanded` / `government-provisional-cure-adequate` | INTERPRETATION_GOVERNMENT | s1383-eah § 303A | Government's reading of § 303A | Party-specific |
| `government-scenario-alternative-process-approved` | INTERPRETATION_GOVERNMENT | hr22-eh § 2(f) | Party-specific reading of alternative process | Replace with hinge_mandatory import |

## Hinge Books (2 axioms)

| Event Name | Label | Source | Reason Remains Axiom | Future Path |
|---|---|---|---|---|
| `semantic-a-mandatory-approval` | INTERPRETIVE_ASSUMPTION | hr22-eh § 2(f) | Constrains defstub `alternative-process-approvedp` under Semantic A | Inherent — mutually exclusive with Semantic B |
| `semantic-b-discretionary-denial` | INTERPRETIVE_ASSUMPTION | hr22-eh § 2(f) | Constrains defstub `alternative-process-approvedp` under Semantic B | Inherent — mutually exclusive with Semantic A |

## Summary by Classification

| Label | Count | Description |
|---|---|---|
| SCENARIO_FACT | 21 | Stipulated test scenario ground facts: citizen-a (6), citizen-b (7), citizen-c (8) |
| INTERPRETATION_GOVERNMENT | 9 | Government-favorable readings |
| BRIDGE_RULE | 9 | Links between encapsulate predicates and core defstubs |
| DOCTRINAL_RULE | 2 | Established case law holdings |
| EMPIRICAL_ASSUMPTION | 4 | Contestable factual claims about burden severity |
| INTERPRETIVE_ASSUMPTION | 2 | Competing hinge semantics |
| TEXT_FACT | 1 | Direct statutory text translation |
| PROHIBITION | 3 | Primary statutory prohibition |
| INTERPRETATION_CHALLENGER | 1 | Challenger-favorable reading |
| **Total** | **52** | |

## Observations

1. **6 SCENARIO_FACT axioms** (22%) are stipulated ground facts about `citizen-a`, stated once in `federal_save_act_scenario.lisp` and conceded by both parties. These are inherently axiomatic — they define the test scenario. (v5 stated them twice, once per party model, for 14 events.)
2. **5 BRIDGE_RULE axioms** (19%) are structural connectors between encapsulate-introduced predicates and core defstubs. These are inherent to the hybrid architecture.
3. **6 INTERPRETATION_GOVERNMENT + 1 INTERPRETATION_CHALLENGER** (26%) are party-specific legal judgments. These should eventually be fully separated into theory modules with explicit assumption guards.
4. **3 EMPIRICAL_ASSUMPTION axioms** (11%) are the most contestable — they assert factual claims about burden severity. Future versions should guard these with explicit `(empirical-assumption-activep ...)` predicates.
5. **2 INTERPRETIVE_ASSUMPTION axioms** (7%) are the hinge semantics — inherently axiomatic because they encode mutually exclusive readings of statutory text.
