# Federal SAVE Act — Constitutional ACL2 Stress Test

Formal constitutional stress-test of the Safeguard American Voter Eligibility Act (H.R. 22, 119th Congress), which requires documentary proof of U.S. citizenship to register to vote in federal elections.

This project uses the [AGENTS.md](../AGENTS.md) framework to separate text-derived statutory facts from interpretive assumptions, then runs competing ACL2 proof obligations to identify which assumptions control the constitutional outcome.

**Current version: 5.3.1** — See [CHANGELOG.md](CHANGELOG.md) for version history.

## What This Project Proves

Once law status, qualified-voter status, protected right, registration transaction, and statutory denial are established, the remaining formal pivot is whether the regulation is valid. The clean books prove that the model’s state machine has coherent registration and denial paths, including an alternative-approval path to registration. Whether the statute legally requires approval under that path is handled by a separate interpretive assumption.

The government model’s no-conflict theorem depends on a package of scenario facts, doctrinal assumptions, interpretive assumptions, empirical assumptions, and bridge rules. The legal-defense factors are a subset of that trusted base.

The government model formalizes a Crawford/Anderson-Burdick-style defense. ACL2 proves that if those modeled doctrinal, interpretive, and empirical premises are accepted, then the no-conflict theorem follows.

The certified ACL2 books do not prove that the SAVE Act is constitutional or unconstitutional. They prove that, under explicitly stated and source-traced assumptions, the government model entails no constitutional conflict, while the challenger model entails conflict. The clean books independently prove process and document-list invariants with no trusted legal assumptions. The defaxiom-chain books introduce statutory, empirical, doctrinal, and interpretive assumptions. The principal value of the project is that it makes the legal pivot — especially `valid-regulationp` and the mandatory/discretionary alternative-process hinge — explicit and mechanically checkable.

## Architecture (v5.2 — Hybrid Encapsulate)

The project uses a **hybrid architecture**: `encapsulate` with local witness functions for interpretive predicates and doctrinal standards (where inconsistency risk is highest), `defaxiom` for text-derived facts and scenario ground truths (self-evidently consistent constraints on `defstub` functions), and executable `defun` chains for derived burden conclusions. This design puts consistency protection exactly where it matters most while making burden derivation mechanically auditable.

See [RIGOR_NOTES_V3.md](docs/RIGOR_NOTES_V3.md) for the original v3 architectural rationale (still applicable to the hybrid core).

## Quick Start

```powershell
# Run consistency check (verifies core vocabulary)
cmd /c "docker compose run --rm -w /work/model acl2 acl2 < model/federal_save_act_consistency_check.lisp"

# Run challenger proof (expects constitutional conflict)
cmd /c "docker compose run --rm -w /work/model acl2 acl2 < model/federal_save_act_challenger_model.lisp"

# Run government proof (expects no conflict)
cmd /c "docker compose run --rm -w /work/model acl2 acl2 < model/federal_save_act_government_model.lisp"
```

> **Important**: Never load both models in the same ACL2 session. They derive opposite conclusions and are intentionally incompatible.

## Interactive Computational Amicus Explorer

Visually explore the proof-dependency graph and toggle assumptions to see which conclusions remain supported:

**Live Demo**: [https://f-pound.github.io/federal_save_act/](https://f-pound.github.io/federal_save_act/) (no installation required)

Or run locally:

```bash
python tools/serve_explorer.py
# Opens http://127.0.0.1:8000
```

The explorer lets users toggle empirical, interpretive, and doctrinal assumptions to see which proof paths and conditional conclusions remain supported. It visualizes existing certified ACL2 proof dependencies across 6 layers (sources → formalization → executable model → derivations → theorems → conclusions).

- **Click the audit stats** in the header bar to drill into books, theorems, axioms, and existentials
- **It does not run ACL2 live** — it renders pre-certified proof structure
- **It does not decide constitutionality** — final conclusions are conditional on selected assumptions
- See [reports/computational_amicus_explorer.md](reports/computational_amicus_explorer.md) for full documentation

## Results

| Book | Theorems | Technique | Result |
|---|---|---|---|
| Consistency check | 16 | defun decomposition, neutrality | ✅ All Q.E.D. |
| Process model | 19 | recursive list induction | ✅ All Q.E.D. |
| Process invariants | 15 | trace induction, acceptance-path invariant | ✅ All Q.E.D. |
| **Deep process invariants** | **9** | **trace induction, terminal stability, no-skip** | ✅ All Q.E.D. |
| Hinge common | 4 | encapsulate | ✅ All Q.E.D. |
| Hinge mandatory | 2 | defaxiom bridge, defun enable | ✅ All Q.E.D. |
| Hinge discretionary | 3 | defaxiom bridge, defun enable | ✅ All Q.E.D. |
| Existentials | 6 | defun-sk Skolemization | ✅ All Q.E.D. |
| Independence | 3 | structural decomposition, pivot theorem | ✅ All Q.E.D. |
| Challenger model | 13 | encapsulate + bridge rules | ✅ All Q.E.D. |
| Government model | 5 | encapsulate + bridge rules | ✅ All Q.E.D. |
| **Document proofs** | **9** | **list induction, structural denial** | ✅ All Q.E.D. |
| **Burden proofs** | **8** | **derivation chain, contrapositives** | ✅ All Q.E.D. |
| **Doctrine proofs** | **7** | **conditional doctrine, encapsulate** | ✅ All Q.E.D. |
| **Model consistency** | **7** | **compositional decomposition** | ✅ All Q.E.D. |
| **Total** | **126** | | **✅ All Q.E.D.** |

**Primary interpretive hinge**: Whether the alternative attestation process (§ 8(j)(2)(A)) provides a constitutionally adequate safety valve. See the split hinge books (`model/federal_save_act_hinge_mandatory.lisp` / `model/federal_save_act_hinge_discretionary.lisp`) for the formal analysis.

## Project Structure

```
federal_save_act/
├── README.md                                # This file
├── CHANGELOG.md                             # Version history
├── version.json                             # Machine-readable project metadata
├── LICENSE                                  # Apache 2.0
├── INVENTION_DISCLOSURE.md                  # Prior art disclosure
├── docker-compose.yml                       # ACL2 Docker config
├── .github/workflows/acl2-proofs.yml        # CI: automated proof certification
│
├── model/                                   # ACL2 formal model (.lisp files)
│   ├── federal_save_act_core.lisp           # Neutral vocabulary (defstub + defun)
│   ├── federal_save_act_process.lisp        # Registration state machine + doc recognizers
│   ├── federal_save_act_facts.lisp          # Text-derived facts (defaxiom)
│   ├── federal_save_act_hinge_common.lisp   # Shared hinge vocabulary (encapsulate)
│   ├── federal_save_act_hinge_mandatory.lisp    # Semantic A: mandatory approval
│   ├── federal_save_act_hinge_discretionary.lisp # Semantic B: discretionary denial
│   ├── federal_save_act_existentials.lisp   # Existential burden modeling (defun-sk)
│   ├── federal_save_act_burden_proofs.lisp  # Burden derivation chain
│   ├── federal_save_act_doctrine_proofs.lisp    # Conditional doctrine theorems
│   ├── federal_save_act_model_consistency.lisp  # Model sanity / consistency checks
│   ├── federal_save_act_independence.lisp   # Independence / non-entailment
│   ├── federal_save_act_challenger_model.lisp   # Challenger model (encapsulate + defaxiom)
│   ├── federal_save_act_government_model.lisp   # Government defense model
│   ├── federal_save_act_process_invariants.lisp # General state-machine invariants
│   ├── federal_save_act_deep_process_invariants.lisp # Deeper trace invariants
│   ├── federal_save_act_document_proofs.lisp    # Document-list structural proofs
│   └── federal_save_act_consistency_check.lisp  # Core vocabulary sanity + neutrality
│
├── inputs/                                  # Source legislation & constitutional text
│   ├── federal_save_act_bill_text.txt       # H.R. 22 full text
│   └── constitutional_language.txt          # U.S. Constitution provisions
│
├── docs/                                    # Detailed documentation
│   ├── Overview.md                          # Full analysis report
│   ├── PROOF_TOUR.md                        # Proof architecture walkthrough
│   ├── CERTIFICATION.md                     # Local certification guide
│   ├── TOP_5_THEOREMS.md                    # Five strongest theorems
│   ├── RIGOR_NOTES_V3.md                    # Architecture rationale
│   └── agents-config.md                     # Project configuration
│
├── sources/
│   ├── source_manifest.json                 # Provenance manifest (all cited sources)
│   └── clause_trace.csv                     # Axiom → source clause traceability
├── tools/
│   ├── validate_trace.py                    # Machine-checkable source trace validator
│   ├── build_explorer_data.py               # Build web/data/explorer.json from repo artifacts
│   ├── serve_explorer.py                    # Serve explorer at http://127.0.0.1:8000
│   └── validate_explorer_data.py            # Validate explorer.json graph integrity
├── scripts/
│   ├── certify_books.ps1                    # certify-book script (Windows PowerShell)
│   ├── certify_books.sh                     # certify-book script (Linux/macOS)
│   ├── certify_all.ps1                      # Batch admission script (Windows PowerShell)
│   └── certify_all.sh                       # Batch admission script (Linux/macOS)
├── data/
│   └── parsed/
│       ├── federal_save_act.json            # Parsed bill sections
│       ├── federal_save_act_predicates.json # Normalized predicates
│       ├── federal_save_act_ace.json        # ACE-normalized clauses
│       └── explorer_graph.json              # Curated proof-dependency graph
├── web/                                     # Interactive explorer (static HTML/JS/CSS)
│   ├── index.html                           # Main page
│   ├── app.js                               # Graph renderer + assumption engine
│   ├── style.css                            # Dark-theme stylesheet
│   └── data/
│       └── explorer.json                    # Generated data (built by tools/build_explorer_data.py)
├── reports/
│   ├── certification_status.md              # certify-book status matrix
│   ├── axiom_inventory.md                   # Full defaxiom classification report
│   ├── axiom_pressure_report.md             # Axiom pressure + replacement paths
│   ├── proof_dependency_report.md           # Theorem dependency chains
│   ├── computational_amicus_explorer.md     # Explorer documentation
│   ├── v5_formal_methods_assessment.md      # v5 metrics and assessment
│   ├── v5_2_acl2_proof_assessment.md        # v5.2 metrics and assessment
│   ├── v5_3_review_hardening_assessment.md  # v5.3 review hardening assessment
│   └── federal_save_act_proof_obligations.md # Proof results
└── logs/                                    # Certification logs (gitignored)
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
- **Independence (structural)**: The conflict condition structurally pivots on `valid-regulationp`. Since that predicate is an unconstrained defstub in the neutral model, ACL2's soundness guarantees neither outcome is derivable from text alone. (This is not an explicit two-model countermodel construction; it relies on metalogical properties of defstubs.)
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

## v5.2: ACL2 Proof-Legitimacy Upgrade

v5.2 does not build the future **A Computational Amicus Brief** engine. v5.2 strengthens the Federal SAVE Act proof development itself. The focus is on legitimate ACL2 theorem proving:

- Recursive executable models
- Induction over traces and document lists
- Derived burden conclusions (5-step derivation chain replaces assumed burden axioms)
- Doctrinal theorem chains (Anderson-Burdick encapsulate)
- Encapsulated theory components with local witnesses
- Source-traced trusted assumptions
- Proof dependency reporting

A future project may generalize these methods into **A Computational Amicus Brief**. For now, this repository remains focused on the Federal SAVE Act.

See `reports/v5_2_acl2_proof_assessment.md` for full metrics.

## For ACL2 Reviewers

1. **Run the proof suite**: `./scripts/certify_all.sh` (Linux/macOS) or `.\scripts\certify_all.ps1` (Windows). See [CERTIFICATION.md](docs/CERTIFICATION.md).
2. **Executable model**: `federal_save_act_process.lisp` — 7-state, 9-event registration state machine with recursive trace executor.
3. **Induction proofs**: `federal_save_act_process_invariants.lisp` and `federal_save_act_deep_process_invariants.lisp` — 24 theorems, 5+ by induction over event traces.
4. **Document-list induction**: `federal_save_act_document_proofs.lisp` — 9 theorems over recursive document lists.
5. **Encapsulate usage**: Challenger model, government model, hinge common, and doctrine proofs (4 blocks total, each with local witnesses).
6. **defun-sk usage**: `federal_save_act_existentials.lisp` — 4 Skolemized existential propositions.
7. **Remaining defaxioms**: 33 total, classified in `reports/axiom_pressure_report.md`.
8. **Top 5 theorems**: See [TOP_5_THEOREMS.md](docs/TOP_5_THEOREMS.md) — all five depend on zero axioms.
9. **Proof tour**: See [PROOF_TOUR.md](docs/PROOF_TOUR.md) for the full architecture walkthrough.

## For Legal Reviewers

1. **Legal sources**: H.R. 22 (SAVE Act), NVRA (52 U.S.C. §§ 20504–20511), U.S. Constitution (Art. I §§ 2, 4; Amends. V, XIV, XVII, XXIV), and case law (Crawford, Anderson, Harper, Reynolds, Burdick, Arizona v. ITCA). All in `sources/source_manifest.json`.
2. **Source tracing**: Every axiom traces to a specific clause in a public legal document via `sources/clause_trace.csv`. Machine-checkable via `tools/validate_trace.py`.
3. **Empirical/interpretive assumptions**: 3 empirical (burden severity), 2 interpretive (hinge semantics), 2 doctrinal (case law holdings). See `reports/axiom_pressure_report.md`.
4. **What ACL2 proves conditionally**: *If* these assumptions hold, *then* this legal conclusion follows. ACL2 does not evaluate which assumptions are correct.
5. **Why this is not a judicial decision engine**: ACL2 models boolean properties, not burden magnitudes. It does not weigh competing interests, apply stare decisis, or evaluate legislative intent. See [PROOF_TOUR.md](docs/PROOF_TOUR.md) §2.
6. **Challenger vs. government theories**: The challenger argues the documentary proof requirement is an undue burden on citizens who lack qualifying documents. The government argues the requirement is a valid regulation with an adequate alternative process. Both conclusions are formally derived from their respective assumption sets.

## Framework

This project follows the [AGENTS.md](../AGENTS.md) constitutional stress-test framework. See [templates/NEW_PROJECT_PROMPT.md](../templates/NEW_PROJECT_PROMPT.md) for instructions on bootstrapping new stress tests.

## License

This is a legal analysis tool, not legal advice. The ACL2 models do not decide constitutionality — they identify the proof obligations and assumptions needed to prove either a constitutional conflict or no conflict under competing interpretive models.
