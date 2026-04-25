# Federal SAVE Act — Constitutional ACL2 Stress Test

Formal constitutional stress-test of the Safeguard American Voter Eligibility Act (H.R. 22, 119th Congress), which requires documentary proof of U.S. citizenship to register to vote in federal elections.

This project uses the [AGENTS.md](../AGENTS.md) framework to separate text-derived statutory facts from interpretive assumptions, then runs competing ACL2 proof obligations to identify which assumptions control the constitutional outcome.

## Architecture (v3 — Hybrid Encapsulate)

v3 uses a **hybrid architecture**: `encapsulate` with local witness functions for interpretive predicates (where inconsistency risk is highest), and `defaxiom` for text-derived facts and scenario ground truths (self-evidently consistent constraints on `defstub` functions). This design puts consistency protection exactly where it matters most.

See [RIGOR_NOTES_V3.md](RIGOR_NOTES_V3.md) for the full technical rationale.

## Quick Start

```powershell
# Run consistency check (verifies core vocabulary)
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_consistency_check.lisp"

# Run challenger proof (expects constitutional conflict)
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_challenger_model.lisp"

# Run government proof (expects no conflict)
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_government_model.lisp"
```

> **Important**: Never load both models in the same ACL2 session. They derive opposite conclusions and are intentionally incompatible.

## Results

| Book | Theorems | Technique | Result |
|---|---|---|---|
| Consistency check | 16 | defun decomposition, neutrality | ✅ All Q.E.D. |
| Process model | 19 | recursive list induction | ✅ All Q.E.D. |
| Process invariants | 13 | trace induction, absorbing states | ✅ All Q.E.D. |
| Hinge common | 4 | encapsulate | ✅ All Q.E.D. |
| Hinge mandatory | 2 | defaxiom bridge, defun enable | ✅ All Q.E.D. |
| Hinge discretionary | 3 | defaxiom bridge, defun enable | ✅ All Q.E.D. |
| Existentials | 3 | defun-sk Skolemization | ✅ All Q.E.D. |
| Independence | 3 | countermodel encapsulate | ✅ All Q.E.D. |
| Challenger model | 13 | encapsulate + bridge rules | ✅ All Q.E.D. |
| Government model | 5 | encapsulate + bridge rules | ✅ All Q.E.D. |
| **Total** | **81** | | **✅ All Q.E.D.** |

**Primary interpretive hinge**: Whether the alternative attestation process (§ 8(j)(2)(A)) provides a constitutionally adequate safety valve. See the split hinge books (`hinge_mandatory.lisp` / `hinge_discretionary.lisp`) for the formal analysis.

## Project Structure

```
federal_save_act/
├── README.md                                # This file
├── Overview.md                              # Full analysis report
├── RIGOR_NOTES_V3.md                        # v3/v4 architecture & rigor notes
├── agents-config.md                         # Project configuration
├── constitutional_language.txt              # U.S. Constitution provisions
├── federal_save_act_bill_text.txt           # H.R. 22 full text
├── federal_save_act_core.lisp               # Neutral vocabulary (defstub + defun)
├── federal_save_act_facts.lisp              # Text-derived facts (defaxiom)
├── federal_save_act_process.lisp            # Registration state machine + doc recognizers
├── federal_save_act_hinge.lisp              # Alternative process hinge theorems
├── federal_save_act_challenger_model.lisp   # Challenge-side model (encapsulate + defaxiom)
├── federal_save_act_government_model.lisp   # Government defense model (encapsulate + defaxiom)
├── federal_save_act_consistency_check.lisp  # Core vocabulary sanity + neutrality proofs
├── docker-compose.yml                       # ACL2 Docker config
├── .github/workflows/acl2-proofs.yml        # CI: automated proof certification
├── sources/
│   ├── source_manifest.json                 # Provenance manifest (all cited sources)
│   └── clause_trace.csv                     # Axiom → source clause traceability
├── scripts/
│   ├── certify-all.ps1                      # PowerShell certification script
│   └── docker-certify-all.sh                # Bash/Docker certification script
├── data/
│   └── parsed/
│       ├── federal_save_act.json            # Parsed bill sections
│       ├── federal_save_act_predicates.json # Normalized predicates
│       └── federal_save_act_ace.json        # ACE-normalized clauses
└── reports/
    └── federal_save_act_proof_obligations.md # Proof results
```

## Key Features

- **Hybrid architecture**: `encapsulate` for interpretive predicates, `defaxiom` for text facts and scenarios
- **Source provenance**: Every axiom traced to authoritative source text via `clause_trace.csv`
- **Registration state machine**: 10-state, 9-event model of the full registration lifecycle
- **Document recognizers**: Structured document types replacing bare booleans
- **Hinge theorems**: Two competing semantics for § 8(j)(2)(A) with formal proofs of which drives conflict
- **Neutrality proofs**: Core vocabulary alone does not force either constitutional outcome
- **Possession ≠ presentation**: `has-documentary-proofp` vs. `presents-documentary-proofp`
- **Factored proof chain**: `qualified-federal-voterp` → `registration-transactionp` → `save-act-denial-triggerp`
- **Generalized theorems**: `challenger-conflict-general` and `government-no-conflict-general`
- **CI/CD**: GitHub Actions runs all proofs on every push

## Scenario

- **citizen-a**: An elderly U.S. citizen born at home in a rural area, who lacks a REAL ID, passport, birth certificate, or other qualifying document under the SAVE Act
- **registration-attempt-a**: A mail voter registration application for a federal election

## Constitutional Provisions

- U.S. Constitution, Article I, § 2 (Voter Qualifications — House)
- U.S. Constitution, Article I, § 4 (Elections Clause)
- Amendment V (Federal Equal Protection via Bolling v. Sharpe)
- Amendment XIV, § 1 (Citizenship; State Equal Protection — doctrinal source)
- Amendment XVII (Voter Qualifications — Senate)
- Amendment XXIV, § 1 (Poll Tax Prohibition)

## What ACL2 Proves

- **Conditional legal conclusions**: If the challenger's assumptions hold, constitutional conflict follows. If the government's assumptions hold, no conflict follows.
- **Structural invariants**: The registration state machine is deterministic, terminal states are absorbing, and specific paths always reach expected outcomes.
- **Source traceability**: Every axiom is classified and traced to authoritative legal text.
- **Independence**: The neutral statutory facts alone do not force either outcome — the result depends on doctrinal, empirical, and interpretive assumptions.
- **Existential modeling**: If ANY burdened citizen exists, the burden class is nontrivial.
- **Hinge identification**: The mandatory-vs-discretionary reading of § 8(j)(2)(A) is the formal pivot that determines the outcome.

## What ACL2 Does Not Prove

- Whether the SAVE Act **is** constitutional or unconstitutional
- Whether the challenger's empirical assumptions (burden severity) are factually true
- Whether the government's doctrinal claims (rational connection, evenhandedness) are legally correct
- Whether a court would adopt the mandatory or discretionary reading
- The _magnitude_ of the burden (ACL2 models boolean propositions, not quantitative assessments)

## What Remains Assumed

- **33 defaxioms** across 5 books — see `reports/axiom_inventory.md` for the full classification
- **14 scenario facts** stipulating citizen-a's properties (self-evidently consistent)
- **3 empirical assumptions** about burden severity (contestable, source-linked)
- **2 interpretive assumptions** encoding the hinge semantics (mutually exclusive)
- **5 bridge rules** connecting encapsulate predicates to core defstubs

## What Is Source-Traced

- 38 axiom-to-source mappings in `sources/clause_trace.csv`
- 21 authoritative sources in `sources/source_manifest.json`
- Every defaxiom has a classification, source_id, section reference, and quoted clause text
- Machine-checkable via `tools/validate_trace.py` (runs in CI)

## What Is Empirically Contestable

| Axiom | Claim | Source | How to Contest |
|---|---|---|---|
| `challenger-scenario-no-fault` | Citizens lack docs through no fault | Fish v. Kobach | Dispute the empirical prevalence |
| `challenger-scenario-material-burden` | Cannot obtain docs without material burden | Crawford plurality | Show burden is trivial |
| `government-burden-not-severe` | Burden is not severe | Crawford plurality | Show burden IS severe |

## Proof Complexity Comparison

This project uses: recursive functions, event traces, induction over lists, `encapsulate` with local witnesses, `defun-sk` Skolemization, CI-certified theorems, and machine-checkable source traceability.

It remains less complex than major ACL2 industrial proofs (e.g., AMD processor verification) because it has limited arithmetic, limited induction depth, and no large refinement stack. The primary value is in the _legal modeling architecture_, not raw proof complexity.

## Framework

This project follows the [AGENTS.md](../AGENTS.md) constitutional stress-test framework. See [templates/NEW_PROJECT_PROMPT.md](../templates/NEW_PROJECT_PROMPT.md) for instructions on bootstrapping new stress tests.

## License

This is a legal analysis tool, not legal advice. The ACL2 models do not decide constitutionality — they identify the proof obligations and assumptions needed to prove either a constitutional conflict or no conflict under competing interpretive models.
