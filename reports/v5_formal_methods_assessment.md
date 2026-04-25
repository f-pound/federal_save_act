# v5 Formal Methods Assessment

## Summary

The Federal SAVE Act ACL2 model has been upgraded from a source-traced prototype (v4, 52 theorems) to a stronger formal-theorem-proving legal tool (v5, 81 theorems) with general invariants, existential modeling, separated semantic interpretations, and machine-checkable source traceability.

**81 theorems. All Q.E.D. Zero failures.**

## ACL2 Event Census

| Event Type | Count | Purpose |
|---|---|---|
| `defstub` | 45 | Uninterpreted predicates (neutral vocabulary) |
| `defaxiom` | 33 | Text facts, scenario facts, bridge rules, interpretive assumptions |
| `defconst` | 26 | State machine states, event types, document types |
| `defun` | 15 | Structural helpers, state machine, recognizers |
| `defthm` | 81 | Proven theorems |
| `defun-sk` | 3 | Existential propositions (Skolemized) |
| `encapsulate` | 3 | Interpretive predicate introductions with witnesses |
| **Total** | **206** | |

## Proof Complexity Metrics

| Metric | Value |
|---|---|
| Total certified theorems | 81 |
| Recursive functions | 7 (`reg-run-trace`, `reg-next-state`, `has-qualifying-docs-from-listp`, `qualifying-document-listp`, `qualifying-document-typep`, `trace-contains-eventp`, `trace-count-event`) |
| Induction proofs | 6 (list membership, append×2, remove, trace→register, trace→deny) |
| `encapsulate` blocks | 3 (challenger interpretive, government interpretive, hinge vocabulary) |
| `defun-sk` propositions | 3 (existential burden modeling) |
| State machine states | 10 |
| State machine events | 9 |
| Source-traced propositions | 38 (in clause_trace.csv) |
| Authoritative sources cited | 21 |
| ACL2 books | 12 |

## Defaxioms by Classification

| Label | Count | % |
|---|---|---|
| SCENARIO_FACT | 14 | 42% |
| INTERPRETATION_GOVERNMENT | 6 | 18% |
| BRIDGE_RULE | 5 | 15% |
| EMPIRICAL_ASSUMPTION | 3 | 9% |
| INTERPRETIVE_ASSUMPTION | 2 | 6% |
| DOCTRINAL_RULE | 2 | 6% |
| INTERPRETATION_CHALLENGER | 1 | 3% |

See `reports/axiom_inventory.md` for the full classification with sources, reasons, and future replacement paths.

## v4 → v5 Upgrade Summary

| Feature | v4 | v5 |
|---|---|---|
| Certified theorems | 52 | 81 (+56%) |
| Induction proofs | 0 | 6 |
| Existential modeling (defun-sk) | No | Yes |
| Hinge semantics | Combined (1 book) | Separated (3 books) |
| Process invariants | Specific traces only | General over arbitrary traces |
| Document-list proofs | Ground instances | Recursive induction |
| Independence proofs | Partial (neutrality) | Full (3 theorems) |
| Source trace validator | Manual audit | Machine-checkable (Python) |
| CI scope | ACL2 only | ACL2 + trace validation |
| Axiom inventory | Informal | Formal report with classifications |
| Documentation | Feature list | What proves / doesn't prove / assumed |

## What This Proves

1. **Conditional legal conclusions are formally derived**: The challenger's conflict and the government's no-conflict are logically entailed by their respective assumption sets — not asserted.

2. **The outcome is provably independent of neutral facts**: The statutory text alone does not determine constitutionality. The pivot is `valid-regulationp`, which requires doctrinal and empirical input.

3. **The hinge is identified and separated**: The mandatory-vs-discretionary reading of § 8(j)(2)(A) is the formal fork. Under mandatory semantics, denial is impossible. Under discretionary semantics, qualified citizens face risk of erroneous denial.

4. **General invariants hold for ALL traces**: Terminal states are absorbing, registration requires a register event, denial requires a deny event. These hold for arbitrary event sequences, not just handpicked examples.

5. **Existential burden claims are modeled**: If ANY burdened citizen exists, the burden class is nontrivial — stronger than a single named scenario.

## Remaining Limitations

1. **No quantitative burden analysis**: ACL2 models boolean propositions, not magnitudes. The burden-severity question requires empirical input.

2. **Limited induction depth**: The state machine proofs use simple list induction. A deeper model would prove properties about multi-step state machine compositions.

3. **No refinement stack**: Industrial ACL2 proofs use hierarchical refinement (concrete → abstract → concrete). This model has a flat architecture.

4. **Arithmetic absent**: No cost calculations, no statistical reasoning, no probabilistic burden assessment.

5. **Single scenario**: The existential model is more general than citizen-a, but the challenger and government books still use citizen-a as the concrete corollary target.

## Next Recommended Upgrades

1. **Parameterized interpretive modules**: Replace party-specific defaxiom ground facts with guarded theory modules that can be activated/deactivated.

2. **Multi-scenario regression**: Add citizen-b, citizen-c with different fact patterns (e.g., naturalized citizen with certificate, citizen with expired passport).

3. **Quantified burden severity**: Introduce ordinal or categorical burden levels (none/minimal/moderate/severe) with monotonicity theorems.

4. **Refinement proofs**: Prove that the abstract process model refines a concrete state machine specification.

5. **Cross-statute comparison**: Apply the same architecture to other voter registration statutes for comparative analysis.
