# Federal SAVE Act — Constitutional ACL2 Stress Test

Formal constitutional stress-test of the Safeguard American Voter Eligibility Act (H.R. 22, 119th Congress), which requires documentary proof of U.S. citizenship to register to vote in federal elections.

This project uses the [AGENTS.md](../AGENTS.md) framework to separate text-derived statutory facts from interpretive assumptions, then runs competing ACL2 proof obligations to identify which assumptions control the constitutional outcome.

**Current version: 6.3.0** — See [CHANGELOG.md](CHANGELOG.md) for version history.

## Legislative Status (as of 2026-08-22)

**Not law.** H.R. 22 passed the House 220-208 (Apr. 10, 2025) and never moved in the Senate. The current vehicle is the **SAVE America Act**, passed as a House amendment to **S. 1383** (218-213, Feb. 11, 2026); Senate cloture failed 41-49 (Mar. 21) and 53-47 (Mar. 26, 2026), and reconciliation-amendment attempts failed 48-50 (Apr. 23, Jun. 4). The model was built on H.R. 22 § 2; `tools/check_text_stability.py` verifies in CI that every clause the model quotes appears verbatim in **both** texts (18/18; only the short title differs). The new vehicle adds material the model does not yet cover: § 3 photo ID to vote, a name-discrepancy process, and DHS/SAVE list submission. Executive Order 14248's proof-of-citizenship provision is permanently enjoined (*LULAC v. EOP*, D.D.C. Oct. 31, 2025, appeal pending; *California v. Trump*, D. Mass. June 24, 2026); EO 14399 (Mar. 31, 2026) is under challenge. Machine-readable: [`data/legislative_status.json`](data/legislative_status.json).

## What This Project Proves

Once law status, qualified-voter status, protected right, registration transaction, and statutory denial are established, the remaining formal pivot is whether the regulation is valid. The clean books prove that the model’s state machine has coherent registration and denial paths, including an alternative-approval path to registration. Whether the statute legally requires approval under that path is handled by a separate interpretive assumption.

The government model’s no-conflict theorem depends on a package of scenario facts, doctrinal assumptions, interpretive assumptions, empirical assumptions, and bridge rules. The legal-defense factors are a subset of that trusted base.

The government model formalizes a Crawford/Anderson-Burdick-style defense. ACL2 proves that if those modeled doctrinal, interpretive, and empirical premises are accepted, then the no-conflict theorem follows.

The certified ACL2 books do not prove that the SAVE Act is constitutional or unconstitutional. They prove that, under explicitly stated and source-traced assumptions, the government model entails no constitutional conflict, while the challenger model entails conflict. The clean books independently prove process and document-list invariants with no trusted legal assumptions. The defaxiom-chain books introduce statutory, empirical, doctrinal, and interpretive assumptions. The principal value of the project is that it makes the legal pivot — especially `valid-regulationp` and the mandatory/discretionary alternative-process hinge — explicit and mechanically checkable.

## Architecture (v6.0 — Hybrid Encapsulate + Lemma Libraries)

The project uses a **hybrid architecture**: `encapsulate` with local witness functions for interpretive predicates and doctrinal standards (where inconsistency risk is highest), `defaxiom` for text-derived facts and scenario ground truths (self-evidently consistent constraints on `defstub` functions), and executable `defun` chains for derived burden conclusions. This design puts consistency protection exactly where it matters most while making burden derivation mechanically auditable.

v6.0 adds a **lemma-library layer** beneath the statute books. `model/lib/lsm.lisp` proves the invariants of an arbitrary table-driven legal process (entry/exit/event guards, absorbing states, closed-set induction) once; `model/lib/enum_list.lisp` proves the algebra of "any of the following" enumerated definitions once. The SAVE Act books supply a data table (`*reg-edges*`) and generated category tables (`*standalone-proof-types*` …) and obtain every invariant by instantiation — ACL2's only statute-specific work is evaluating the tables. The category tables themselves are **compiled** from a deterministic clause IR (`data/parsed/federal_save_act_document_rules.json`) by `tools/clauses_to_acl2.py`, which also emits the matching controlled-English paraphrase, so prose and math cannot drift. See [reports/v6_lemma_library_assessment.md](reports/v6_lemma_library_assessment.md).

See [RIGOR_NOTES_V3.md](docs/RIGOR_NOTES_V3.md) for the original v3 architectural rationale (still applicable to the hybrid core).

## Quick Start

```bash
# Native ACL2 (e.g. `brew install acl2`) or Docker — certify all 25 books in order
./scripts/certify_books.sh
```

```powershell
# Windows / Docker: individual books
cmd /c "docker compose run --rm -w /work/model acl2 acl2 < model/federal_save_act_consistency_check.lisp"
cmd /c "docker compose run --rm -w /work/model acl2 acl2 < model/federal_save_act_challenger_model.lisp"
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
| **lib/enum_list** | **21** | **generic enumerated-category algebra, hint-free** | ✅ All Q.E.D. |
| **lib/lsm** | **22** | **generic labeled state machine invariants, hint-free** | ✅ All Q.E.D. |
| Core | 4 | shared conflict pivots (registration + removal) | ✅ All Q.E.D. |
| Document rules (generated) | 0 | compiled from clause IR | ✅ certified |
| Process table (generated) | 0 | compiled from clause IR (13 cited edges) | ✅ certified |
| Removal table (generated) | 0 | compiled from clause IR (§ 8(k)) | ✅ certified |
| Text rules (generated) | 0 | defaxiom compiled from clause IR | ✅ certified |
| Process model | 28 | generated edge table + library instances, evaluation | ✅ All Q.E.D. |
| **Removal invariants (§ 8(k))** | **11** | **lsm instances: statutory path has no notice/hearing** | ✅ All Q.E.D. |
| Scenario (shared) | 6 | conceded ground facts: citizen-a (registration), citizen-b (removal) | ✅ All Q.E.D. |
| Consistency check | 17 | defun decomposition, neutrality | ✅ All Q.E.D. |
| Process invariants | 16 | `:use` instances of lsm lemmas (0 inductions) | ✅ All Q.E.D. |
| Deep process invariants | 11 | `:use` instances of lsm lemmas (0 inductions) | ✅ All Q.E.D. |
| Hinge common | 4 | encapsulate | ✅ All Q.E.D. |
| Hinge mandatory | 2 | defaxiom bridge, defun enable | ✅ All Q.E.D. |
| Hinge discretionary | 3 | defaxiom bridge, defun enable | ✅ All Q.E.D. |
| Existentials | 6 | defun-sk Skolemization | ✅ All Q.E.D. |
| Independence | 3 | structural decomposition, pivot theorem | ✅ All Q.E.D. |
| Challenger model | 15 | encapsulate + bridge rules + shared scenario; registration and removal branches | ✅ All Q.E.D. |
| Government model | 8 | encapsulate + bridge rules + shared scenario; registration and removal branches | ✅ All Q.E.D. |
| Document proofs | 20 | enum_list instances over generated § 3(b) tables; plain REAL ID ≠ proof | ✅ All Q.E.D. |
| Burden proofs | 8 | derivation chain, contrapositives | ✅ All Q.E.D. |
| Doctrine proofs | 7 | conditional doctrine, encapsulate | ✅ All Q.E.D. |
| Model consistency | 7 | compositional decomposition | ✅ All Q.E.D. |
| **Total** | **219** | | **✅ All Q.E.D.** |

**Second hinge (v6.1)**: Whether removal under § 8(k) on "verified information" with no notice or hearing is a valid regulation as applied to a registered citizen. The challenger (Mathews v. Eldridge) and government (Husted) removal branches reach opposite conditional conclusions for `citizen-b`.

**Primary interpretive hinge**: Whether the alternative attestation process (§ 8(j)(2)(A)) provides a constitutionally adequate safety valve. See the split hinge books (`model/federal_save_act_hinge_mandatory.lisp` / `model/federal_save_act_hinge_discretionary.lisp`) for the formal analysis.

## Project Structure

```
federal_save_act/
├── README.md                                # This file
├── CHANGELOG.md                             # Version history
├── version.json                             # Machine-readable project metadata
├── CITATION.cff                             # GitHub citation metadata (APA/BibTeX)
├── LICENSE                                  # Apache 2.0
├── INVENTION_DISCLOSURE.md                  # Prior art disclosure
├── RELATED_WORK.md                          # Prior work acknowledgment + claimed contribution
├── docker-compose.yml                       # ACL2 Docker config
├── .github/workflows/acl2-proofs.yml        # CI: automated proof certification
│
├── model/                                   # ACL2 formal model (.lisp files)
│   ├── lib/
│   │   ├── enum_list.lisp                   # GENERIC: enumerated-category list algebra
│   │   └── lsm.lisp                         # GENERIC: labeled state machine invariants
│   ├── federal_save_act_core.lisp           # Neutral vocabulary (defstub + defun)
│   ├── federal_save_act_document_rules.lisp # GENERATED from clause IR (§ 3(b) tables)
│   ├── federal_save_act_process_table.lisp  # GENERATED: registration states/events/edges
│   ├── federal_save_act_removal_table.lisp  # GENERATED: § 8(k) removal states/events/edges
│   ├── federal_save_act_text_rules.lisp     # GENERATED: text-derived defaxiom(s)
│   ├── federal_save_act_process.lisp        # Registration machine over the generated table
│   ├── federal_save_act_removal_invariants.lisp # § 8(k): statutory path lacks notice/hearing
│   ├── federal_save_act_facts.lisp          # Text-derived facts (defaxiom)
│   ├── federal_save_act_scenario.lisp       # Shared citizen-a scenario (defaxiom)
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
│   ├── federal_save_act_bill_text.txt       # H.R. 22 (EH) full text — modeled text
│   ├── save_america_act_s1383_eah_text.txt  # SAVE America Act (S. 1383 EAH) — current vehicle
│   └── constitutional_language.txt          # U.S. Constitution provisions
│
├── docs/                                    # Detailed documentation
│   ├── generated/                           # English paraphrases compiled from clause IR
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
│   ├── check_text_stability.py              # Modeled clauses verbatim in both bill texts (CI)
│   ├── clause_ir_schema.json                # JSON Schema for the statutory clause IR
│   ├── clauses_to_acl2.py                   # IR → ACL2 book + controlled-English (deterministic)
│   ├── validate_ace_statements.py           # ACE → APE webservice validator (strict mode)
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
│       ├── federal_save_act_ace.json        # ACE clauses (APE-validated; § 3(b) entry generated from IR)
│       ├── federal_save_act_document_rules.json # Clause IR: § 3(b) enumeration
│       ├── federal_save_act_process_table.json  # Clause IR: registration process table
│       ├── federal_save_act_removal_table.json  # Clause IR: § 8(k) removal process table
│       ├── federal_save_act_text_rules.json     # Clause IR: text-derived axioms + ACE atoms
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
│   ├── v6_lemma_library_assessment.md       # v6.0 lemma libraries, IR compiler, § 3(b)(5) fix
│   └── federal_save_act_proof_obligations.md # Proof results
├── papers/
│   └── federal_save_act_computational_amicus_brief.md  # SSRN/arXiv abstract
└── logs/                                    # Certification logs (gitignored)
```

## Key Features

- **Reusable lemma libraries**: `lib/lsm` and `lib/enum_list` prove process and enumeration invariants once; statute books instantiate them over data tables
- **Prose → IR → math**: § 3(b) categories, the documentary-proof prohibition, and the registration / § 8(k) removal process tables are compiled from a deterministic JSON clause IR into ACL2, controlled English, and Markdown (CI checks all three match)
- **Hybrid architecture**: `encapsulate` for interpretive predicates, `defaxiom` for text facts and scenarios
- **Source provenance**: Every axiom traced to authoritative source text via `clause_trace.csv`
- **Registration state machine**: 10-state, 9-event, 13-edge data table; acceptance/denial sets derived from the table
- **Document recognizers**: Faithful § 3(b) structure — standalone proof vs. photo-ID-anchored supporting documents
- **Hinge theorems**: Two competing semantics for § 8(j)(2)(A) with formal proofs of which drives conflict
- **Neutrality proofs**: Core vocabulary alone does not force either constitutional outcome
- **Possession ≠ presentation**: `has-documentary-proofp` vs. `presents-documentary-proofp`
- **Factored proof chain**: `qualified-federal-voterp` → `registration-transactionp` → `save-act-denial-triggerp`
- **Generalized theorems**: `challenger-conflict-general` and `government-no-conflict-general`
- **CI/CD**: GitHub Actions runs all proofs on every push
- **ACE formal prose**: README and statutory clauses in APE-validated [Attempto Controlled English](https://attempto.ifi.uzh.ch/ape/) (8/8 PASS, strict mode); the § 3(b) definition, the documentary-proof prohibition, and both process tables have their ACE **generated from the clause IR** alongside the ACL2 books

## Scenario

- **citizen-a**: An elderly U.S. citizen born at home in a rural area, who lacks a REAL ID, passport, birth certificate, or other qualifying document under the SAVE Act
- **registration-attempt-a**: A mail voter registration application for a federal election
- **citizen-b** (v6.1): A registered U.S. citizen whose record is erroneously matched to "verified information" of noncitizenship and removed under § 8(k) with no notice or hearing

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

The § 8(k) removal process is modeled structurally (`federal_save_act_removal_invariants.lisp`: the statutory path to removal provably contains no notice or hearing event) and doctrinally (v6.1: `constitutional-removal-conflict-conditionp`, with challenger and government removal branches for `citizen-b`). The neutral books do **not** assert that removal without notice is unconstitutional; the party books derive opposite conditional conclusions from traced assumptions.

- **38 defaxioms** across 6 books — see `reports/axiom_inventory.md` for the full classification. Every one carries a **decider** tag (legislature 4 · court 16 · fact-finder 3 · party-stipulation 15): the logic has no grey areas; each axiom is a choice, and the tag says whose. A CI lint guarantees the 18 neutral books contain no axiom at all.
- **13 scenario facts** stipulating citizen-a (registration) and citizen-b (removal), shared by both party models (self-evidently consistent)
- **3 empirical assumptions** about burden severity (contestable, source-linked)
- **2 interpretive assumptions** encoding the hinge semantics (mutually exclusive)
- **5 bridge rules** connecting encapsulate predicates to core defstubs

## What Is Source-Traced

- 45 axiom-to-source mappings in `sources/clause_trace.csv`
- 34 authoritative sources (two tracked bill texts, CRS reports, two executive orders, EO litigation) in `sources/source_manifest.json`
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
2. **Generic libraries**: `model/lib/lsm.lisp` (22 theorems) and `model/lib/enum_list.lisp` (21 theorems) — all inductions live here, all hint-free. Two clients: registration (`process*`) and § 8(k) removal (`removal_invariants`).
3. **Executable model**: `federal_save_act_process.lisp` — 10-state, 9-event registration machine as a 13-row edge table (generated, one § citation per edge) interpreted by `lsm-run`.
4. **Instantiated invariants**: `process_invariants.lisp`, `deep_process_invariants.lisp`, `document_proofs.lisp` — 44 theorems, each a `:use` instance of a library lemma plus table evaluation; zero statute-specific inductions.
5. **Generated books**: `document_rules`, `process_table`, `removal_table`, `text_rules` are compiled from `data/parsed/*.json`; `python tools/clauses_to_acl2.py <irs...> --check --english --ace` verifies book, Markdown and ACE together.
6. **Encapsulate usage**: Challenger model, government model, hinge common, and doctrine proofs (4 blocks total, each with local witnesses).
7. **defun-sk usage**: `federal_save_act_existentials.lisp` — 4 Skolemized existential propositions.
8. **Remaining defaxioms**: 27 total, classified in `reports/axiom_inventory.md`.
9. **Top 5 theorems**: See [TOP_5_THEOREMS.md](docs/TOP_5_THEOREMS.md) — all five depend on zero axioms.
10. **Proof tour**: See [PROOF_TOUR.md](docs/PROOF_TOUR.md) for the full architecture walkthrough.

## For Legal Reviewers

1. **Legal sources**: H.R. 22 (SAVE Act), NVRA (52 U.S.C. §§ 20504–20511), U.S. Constitution (Art. I §§ 2, 4; Amends. V, XIV, XVII, XXIV), and case law (Crawford, Anderson, Harper, Reynolds, Burdick, Arizona v. ITCA). All in `sources/source_manifest.json`.
2. **Source tracing**: Every axiom traces to a specific clause in a public legal document via `sources/clause_trace.csv`. Machine-checkable via `tools/validate_trace.py`.
3. **Empirical/interpretive assumptions**: 3 empirical (burden severity), 2 interpretive (hinge semantics), 2 doctrinal (case law holdings). See `reports/axiom_pressure_report.md`.
4. **What ACL2 proves conditionally**: *If* these assumptions hold, *then* this legal conclusion follows. ACL2 does not evaluate which assumptions are correct.
5. **Why this is not a judicial decision engine**: ACL2 models boolean properties, not burden magnitudes. It does not weigh competing interests, apply stare decisis, or evaluate legislative intent. See [PROOF_TOUR.md](docs/PROOF_TOUR.md) §2.
6. **Challenger vs. government theories**: The challenger argues the documentary proof requirement is an undue burden on citizens who lack qualifying documents. The government argues the requirement is a valid regulation with an adequate alternative process. Both conclusions are formally derived from their respective assumption sets.

## Relation to Prior Work and Claimed Contribution

This project builds on substantial prior work in computational law ([Stanford CompLaw](https://complaw.stanford.edu/)), rules-as-code ([LegalRuleML](https://www.oasis-open.org/committees/legalruleml/)), controlled natural languages ([Attempto ACE](https://attempto.ifi.uzh.ch/)), executable legal languages ([Catala](https://catala-lang.org/)), and theorem-prover-based legal reasoning ([LogiKEy/Isabelle](https://logikey.org/)). It is **not** the first attempt to formalize law, nor the first use of controlled English or formal logic in legal reasoning.

The claimed contribution is narrower: to the author's knowledge, this is the first public ACL2 `certify-book`-backed **Computational Amicus Brief** for the Federal SAVE Act, combining source-traced statutory assumptions, ACE-style normalization, competing constitutional models, certified theorem books, proof-dependency reporting, and an interactive assumptions explorer.

See [RELATED_WORK.md](RELATED_WORK.md) for full acknowledgment of prior work and a precise claimed-contribution statement.

## Framework

This project follows the [AGENTS.md](../AGENTS.md) constitutional stress-test framework. See [templates/NEW_PROJECT_PROMPT.md](../templates/NEW_PROJECT_PROMPT.md) for instructions on bootstrapping new stress tests.

## License

This is a legal analysis tool, not legal advice. The ACL2 models do not decide constitutionality — they identify the proof obligations and assumptions needed to prove either a constitutional conflict or no conflict under competing interpretive models.

## Appendix: ACE Formal Prose

> The following Attempto Controlled English (ACE) translations of the README prose paragraphs are machine-parseable by the [Attempto Parsing Engine](https://attempto.ifi.uzh.ch/ape/). Every sentence below has been validated against the APE webservice in strict mode (no `Guess unknown words`, 0 errors, 0 warnings). Validate with: `python tools/validate_ace_statements.py`

<details>
<summary>§ Introduction — Project Description (line 3)</summary>

```ace
A n:project v:stress-tests a n:federal-statute. The n:federal-statute is a n:Safeguard-American-Voter-Eligibility-Act. The n:federal-statute requires a n:documentary-proof-of-citizenship for a n:voter-registration in a n:federal-election.
```
</details>

<details>
<summary>§ Introduction — Framework (line 5)</summary>

```ace
A n:project uses a n:framework. The n:framework separates a n:text-derived-statutory-fact from a n:interpretive-assumption. The n:project runs a n:competing-ACL2-proof-obligation. The n:competing-ACL2-proof-obligation identifies a n:controlling-assumption for a n:constitutional-outcome.
```
</details>

<details>
<summary>§ What This Project Proves — Paragraph 1 (line 11)</summary>

```ace
If a n:law-status is established and a n:qualified-voter-status is established and a n:protected-right is established and a n:registration-transaction is established and a n:statutory-denial is established then a n:formal-pivot remains. A n:clean-book proves that a n:state-machine has a n:coherent-registration-path and a n:coherent-denial-path. The n:state-machine includes a n:alternative-approval-path in the n:coherent-registration-path. A n:separate-interpretive-assumption determines that a n:statute requires a n:approval under the n:alternative-approval-path.
```
</details>

<details>
<summary>§ What This Project Proves — Paragraph 2 (line 13)</summary>

```ace
A n:government-model has a n:no-conflict-theorem. The n:no-conflict-theorem depends on a n:scenario-fact and a n:doctrinal-assumption and a n:interpretive-assumption and a n:empirical-assumption and a n:bridge-rule. A n:legal-defense-factor is a n:subset of the n:scenario-fact and the n:doctrinal-assumption and the n:interpretive-assumption.
```
</details>

<details>
<summary>§ What This Project Proves — Paragraph 3 (line 15)</summary>

```ace
A n:government-model formalizes a n:Crawford-Anderson-Burdick-defense. If a n:doctrinal-premise is accepted and a n:interpretive-premise is accepted and a n:empirical-premise is accepted then a n:no-conflict-theorem follows.
```
</details>

<details>
<summary>§ What This Project Proves — Paragraph 4 (line 17)</summary>

```ace
A n:certified-ACL2-book does not prove that a n:statute is constitutional. The n:certified-ACL2-book does not prove that the n:statute is unconstitutional. If a n:explicitly-stated-assumption holds then a n:government-model entails a n:no-conflict and a n:challenger-model entails a n:conflict. A n:clean-book proves a n:process-invariant and a n:document-list-invariant with no n:trusted-legal-assumption. A n:defaxiom-chain-book introduces a n:statutory-assumption and a n:empirical-assumption and a n:doctrinal-assumption and a n:interpretive-assumption. A n:project makes a n:legal-pivot a:explicit. The n:legal-pivot is a:mechanically-checkable.
```
</details>

<details>
<summary>§ Architecture — Hybrid (line 21)</summary>

```ace
A n:project uses a n:hybrid-architecture. The n:hybrid-architecture uses a n:encapsulate-technique with a n:local-witness-function for a n:interpretive-predicate and a n:doctrinal-standard. The n:hybrid-architecture uses a n:defaxiom-technique for a n:text-derived-fact and a n:scenario-ground-truth. The n:hybrid-architecture uses a n:executable-defun-chain for a n:derived-burden-conclusion.
```
</details>

<details>
<summary>§ Architecture — Lemma Libraries (line 23)</summary>

```ace
A n:lemma-library proves a n:process-invariant and a n:enumeration-invariant. A n:statute-book supplies a n:data-table to the n:lemma-library. The n:statute-book obtains every n:process-invariant by a n:instantiation. A n:compiler compiles a n:clause-IR into a n:ACL2-book. The n:compiler compiles the n:clause-IR into a n:English-paraphrase. The n:ACL2-book and the n:English-paraphrase can not diverge.
```
</details>

<details>
<summary>§ Interactive Explorer (line 56)</summary>

```ace
A n:user uses a n:explorer and selects a n:empirical-assumption and a n:interpretive-assumption and a n:doctrinal-assumption. The n:explorer shows a n:supported-proof-path and a n:supported-conditional-conclusion to the n:user. The n:explorer visualizes a n:certified-ACL2-proof-dependency across 6 n:layers.
```
</details>

<details>
<summary>§ Results — Primary Interpretive Hinge (line 89)</summary>

```ace
A n:primary-interpretive-hinge exists. If a n:alternative-attestation-process provides a n:constitutionally-adequate-safety-valve then a n:constitutional-outcome changes.
```
</details>

<details>
<summary>§ Proof Complexity (lines 259–261)</summary>

```ace
A n:project uses a n:recursive-function and a n:event-trace and a n:induction-over-lists and a n:encapsulate-technique and a n:defun-sk-Skolemization and a n:CI-certified-theorem and a n:machine-checkable-source-traceability. The n:project is not as complex as a n:major-ACL2-industrial-proof. A n:primary-value is in a n:legal-modeling-architecture.
```
</details>

<details>
<summary>§ v5.2 — Future Project (line 275)</summary>

```ace
A n:project has a n:method. A n:future-project may generalize the n:method into a n:computational-amicus-brief. The n:project concerns a n:Federal-SAVE-Act.
```
</details>

<details>
<summary>§ For Legal Reviewers — Challenger vs Government (line 299)</summary>

```ace
A n:challenger argues that a n:documentary-proof-requirement is a n:undue-burden on a n:citizen that lacks a n:qualifying-document. A n:government argues that the n:documentary-proof-requirement is a n:valid-regulation with a n:adequate-alternative-process. A n:respective-assumption-set entails a n:conclusion.
```
</details>

<details>
<summary>§ License — Disclaimer (line 315)</summary>

```ace
A n:project is a n:legal-analysis-tool. The n:project is not a n:legal-advice. A n:ACL2-model does not decide a n:constitutionality. The n:ACL2-model identifies a n:proof-obligation and a n:assumption.
```
</details>
