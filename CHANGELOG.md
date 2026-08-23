# Changelog

All notable changes to the Federal SAVE Act ACL2 Constitutional Model are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [6.4.0] — 2026-08-23

### Added — explorer: "a citizen at the registration counter"
- Cartoon panel above the graph: tick what the applicant presents (checkboxes generated from the same § 3(b) category tables the ACL2 books are compiled from, embedded in `explorer.json` by the builder), optionally sign the § 8(j)(2)(A) attestation, and say whether the applicant is in fact a citizen. The clerk's speech bubble and the outcome box follow the statute mechanically — a JS mirror of `documentary-proof-bundlep` and the denial rule — then the mandatory/discretionary hinge, then the user's premises (reads the live conclusion statuses). Each step names who decides it (legislature / court / fact-finder).
- Demonstrates in one place: a birth certificate alone is denied, with a photo ID it is accepted, a plain REAL ID is not proof, attestation outcomes turn on the court's reading, and a denied citizen's constitutional meaning turns on the selected premises.

## [6.3.0] — 2026-08-23

### Added — "no grey areas in the logic; every grey area is a choice, and here is whose"
- **Decider tag** on every axiom: `sources/clause_trace.csv` gains a `decider` column — `legislature` (statutory text, 4), `court` (doctrine / interpretation, 16), `fact-finder` (empirical, 3), `party-stipulation` (conceded by both sides or arguendo, 15). Validated in CI (check 5); shown in the explorer's details panel ("Who decides this") and axioms drawer; theorems show "Nobody — proved by ACL2 from definitions".
- **Neutrality lint** (CI check 6): the 18 neutral books (libraries, core, generated tables, process/document/removal invariants, consistency, burden, doctrine, existentials, independence, hinge_common) must contain **no** `defaxiom`. Currently 0 violations.
- **Preset "Citizenship implies documents"**: grants the challenger every *legal* premise and denies only the two *empirical* ones. The challenger's registration conflict goes unsupported; the government's holds — making explicit that the registration dispute turns on one factual claim.
- **Theorems** `plain-real-id-is-not-recognized`, `plain-real-id-alone-is-not-proof`, `real-id-indicating-citizenship-alone-is-proof`: a plain REAL ID (what ~81% of air travellers now carry) is not in any § 3(b) category; only the five-state enhanced licence is. Structural, axiom-free.

### Census
- Theorems: 216 → **219**; axioms 38 (unchanged); decider tags 38/38.

## [6.2.0] — 2026-08-22

### Added — legislative currency
- `inputs/save_america_act_s1383_eah_text.txt` — the **current vehicle**: SAVE America Act as the House amendment to S. 1383 (218-213, Feb. 11, 2026). H.R. 22 (EH) remains the modeled text and is annotated as superseded-as-vehicle.
- `tools/check_text_stability.py` (CI + `certify_books.sh`): every statutory clause the model quotes (trace CSV rows and IR `text` fields) must appear **verbatim in both** texts. Result: **18/18 PASS**, one known non-operative difference (short title). This turns "§ 2 is unchanged in the new vehicle" into a machine-checked statement.
- `data/legislative_status.json` — Senate actions with tallies (51-48 motion to proceed; cloture 41-49 and 53-47; reconciliation amendments 48-50 ×2), executive-order track (EO 14248 enjoined in LULAC v. EOP and California v. Trump; EO 14399 challenged). Rendered as a status bar in the explorer.
- Source manifest: `s1383-eah`, `hr7296-ih`, `s3752-is`, `s128-is`, `crs-if12902-v4`, `crs-lsb11368`, `house-rules-comparative-print-s1383`, `eo-14248`, `eo-14399`, `lulac-v-eop`, `california-v-trump` (21 → 34 sources).
- Clause IR: rules may carry `description` (paraphrase, unchecked) distinct from `text` (verbatim, checked); several quotes made verbatim.

### Not yet modeled (scoped in reports/v6_lemma_library_assessment.md § 8)
- SAVE America Act § 3 photo-ID-to-vote (HAVA § 303A), the name-discrepancy registration process, and the 30-day DHS/SAVE list-submission mandate.

## [6.1.0] — 2026-08-23

### Added — § 8(k) removal → conflict bridge
- **Core**: `registered-voterp`, `statute-removes-registrantp`, `removal-procedure-evenhandedp` stubs; `removal-transactionp`; `constitutional-removal-conflict-conditionp (law cs p)` — the removal-side twin of the registration conflict condition (the object of `valid-regulationp` is the registrant p, "valid as applied to p"); twin pivot lemmas.
- **Text rule (generated)**: `text-save-act-removal-upon-verified-information` — § 8(k) as a `defaxiom` compiled from the IR with its ACE (`ace-gen-removal-requirement`, APE strict PASS).
- **Scenario B (shared)**: `citizen-b`, a registered citizen erroneously matched to "verified information" of noncitizenship and removed with no notice or hearing (7 conceded facts; `scenario-b-statute-removes` derived from the text rule).
- **Challenger removal branch**: encapsulated `challenger-removal-due-process-violationp` (Mathews v. Eldridge), bridge to `(not (valid-regulationp law p))`, `challenger-removal-conflict-general`, `challenger-model-finds-removal-conflict`.
- **Government removal branch**: encapsulated `government-removal-defense-establishedp` (Husted v. A. Philip Randolph Inst.), bridge, `government-removal-procedure-evenhanded`, `government-no-removal-conflict-general`, `government-model-no-removal-conflict`.
- Sources: `mathews-v-eldridge`, `husted-v-randolph` added to the manifest; 13 new trace rows.

### Changed — bridge rules narrowed (faithfulness)
- `challenger-undue-burden-defeats-regulation` and `government-bridge-defense-validates` previously concluded `(not (valid-regulationp law x))` / `(valid-regulationp law x)` for **every** x. Both are now conditioned on `(voter-registration-applicationp x)`: the undue-burden argument and the six-factor defense are about registration, and say nothing about removal. Without this narrowing either party's registration theory would have decided the removal question for free. All prior registration theorems still certify unchanged.

### Census
- Theorems: 204 → **216**; axioms: 27 → **38** (7 scenario-b facts, 1 text rule, 5 party removal assumptions); books: 25 (unchanged); encapsulates: 4 → 6.

## [6.0.1] — 2026-08-23

### Changed (explorer UX)
- Left panel rewritten as a three-step guide: **1 Start from a point of view** (presets renamed to "Both sides / Challenger's case / Government's defense / Statute text only / Contested premises only", each with a tooltip and a one-paragraph description of what it switches on), **2 Outcome under these premises** (scenario badges with an inline legend for Supported / Contested / Unsupported), **3 Doubt a premise? Untick it**.
- Details panel placeholder explains what clicking a box shows and what dimming means; About-modal steps updated; stale hard-coded counts removed.
- New node-type labels/colours for libraries, clause IR, and the due-process overlay.

## [6.0.0] — 2026-08-22

### Added
- `model/lib/enum_list.lisp` — generic **enumerated-category list library** (21 theorems, no hints): `all-in-catsp` / `some-in-catsp` / `none-in-catsp` / `filter-in-cats` with append, removal, filtering, duality and category-widening (statutory-amendment) lemmas.
- `model/lib/lsm.lisp` — generic **labeled state machine library** (22 theorems, no hints): table-driven `lsm-step` / `lsm-run`, derived sets (`lsm-sources-into`, `lsm-events-into`, `lsm-events-from`), and once-and-for-all invariants: entry guards, event guards, exit guards, no-skip, closed-set induction, absorbing states, trace composition.
- `data/parsed/federal_save_act_document_rules.json` + `tools/clause_ir_schema.json` — a deterministic **statutory clause IR** for enumerated definitions and boolean rules.
- `tools/clauses_to_acl2.py` — compiles the IR to `model/federal_save_act_document_rules.lisp` (generated, byte-reproducible, `--check` in CI) and to `docs/generated/*.md` controlled-English paraphrases from the same source.
- `model/federal_save_act_scenario.lisp` — the six conceded citizen-a ground facts, stated once and shared by both party models.
- `core-valid-regulation-defeats-conflict` / `core-conflict-pivots-on-valid-regulation` in core — the structural pivot, proved once where every model inherits it.
- `reports/v6_lemma_library_assessment.md` — what changed and why.
- **Generated ACE**: `tools/clauses_to_acl2.py --ace` renders a rule's boolean tree into Attempto Controlled English (DNF → one `If … then …` sentence per statutory member or member-pair) and upserts it into `data/parsed/federal_save_act_ace.json`; `--check` fails CI on drift. IR members carry `ace_noun`. The hand-written `ace-001`…`ace-005` are replaced by the generated `ace-gen-documentary-proof` (10 sentences, covering § 3(b)(1)-(4) and all six § 3(b)(5)(A)-(F) pairings; APE strict PASS). Note: `ace-005` had encoded the § 3(b)(5) pairing correctly since v5.3 while the ACL2 model did not — the two layers were never cross-checked before.

### Changed
- `federal_save_act_process.lisp` — the registration machine is now a **data table** `*reg-edges*` interpreted by `lib/lsm`; acceptance/denial state sets are *computed* from the table (`*reg-acceptance-states*`, `*reg-denial-states*`) rather than hand-listed.
- `process_invariants` / `deep_process_invariants` — every theorem is an instance of a library lemma discharged by evaluating the table. **0** `:induct` / `:cases` / cond-enable hints remain (13 before). Theorem names and statements preserved; several strengthened (`only-acceptance-states-register`, `leaving-unsubmitted-requires-submission`, `reg-run-trace-stays-in-state-space`).
- `document_proofs` — rewritten over the generated § 3(b) category tables as `enum_list` instances; adds `filter-preserves-documentary-proof`, `pairing-two-insufficient-bundles-can-create-proof`, and the amendment lemma `widening-standalone-list-preserves-proof`.
- Challenger / government models include `federal_save_act_scenario` and drop their duplicated scenario axioms (14 → 6 SCENARIO_FACT events).
- `scripts/certify_books.sh` now honours `$ACL2_CMD`, prefers a native `acl2`, checks the generated book against its IR first, and certifies the 21-book chain; CI calls the script instead of 17 inline steps.
- `tools/build_explorer_data.py` scans `model/lib/` too.

### Fixed
- **Statutory faithfulness bug (§ 3(b)(5))**: v3–v5 treated a certified birth certificate or a naturalization certificate *alone* as documentary proof. The statute counts them only when *presented together with* a government-issued photo ID. Fixed in `has-any-qualifying-documentp` (core), in the generated `documentary-proof-bundlep`, and in the consistency-check theorems; the false v5 theorems `birth-cert-is-qualifying` / `nat-cert-is-qualifying` / `nonempty-qualifying-list-has-docs` are replaced by their correct counterparts (`birth-cert-alone-is-not-qualifying`, `birth-cert-with-photo-id-is-qualifying`, `recognized-without-standalone-or-anchor-is-not-proof`).

### Census
- Theorems: 126 → **193** (43 in reusable libraries)
- Axioms: 33 → **27**
- Books: 17 → **21** (9 clean, 12 defaxioms-okp)
- ACE statements: 13 → **9** (1 generated from IR, 8 hand-written)

## [5.3.2] — 2026-04-26

### Added
- `tools/validate_ace_statements.py` — Automated ACE validator against the [Attempto APE webservice](https://attempto.ifi.uzh.ch/ape/)
- README "Appendix: ACE Formal Prose" — 13 prose paragraphs converted to APE-validated Attempto Controlled English in collapsible `<details>` blocks
- ACE validation runs in **strict mode** (no `Guess unknown words`) matching the APE web client defaults

### Changed
- `data/parsed/federal_save_act_ace.json` — All 13 `ace_text` fields rewritten with:
  - `n:` prefix on all domain-specific compound nouns
  - `v:` prefix on compound verbs (`v:register-to-vote`, `v:mechanically-checkable`)
  - `a:` prefix on compound adjectives (`a:explicit`)
  - Proper determiners (`a`/`the`) before every `n:` noun
  - Anaphor chains resolved (first mention uses `a n:X`, subsequent uses `the n:X`)
  - Restructured clauses: `cannot` → `can not`, `whether...has` → `determines`, `verified as` → `somebody verifies`, `in-person` → removed, `to vote in` → `for`
  - `ape_status`, `ape_error`, and `notes` fields updated from live APE responses
- ACE validation result: **13/13 PASS, 0 errors, 0 warnings**
- README project structure: added `validate_ace_statements.py`
- README Key Features: added ACE formal prose bullet

### Unchanged
- Theorem count: 126
- Axiom count: 33
- Book count: 17
- No ACL2 model files modified

## [5.3.1] — 2026-04-26

### Fixed
- Replaced broken Google Scholar URL for Fish v. Kobach with stable Justia link (`6e7687c`)
- Added `docket: "16-3147"` field to Fish v. Kobach source manifest entry

### Added
- Proof dependency graph visualization (`proof_dependency_graph_visual_4_26_26.png`)
- `CHANGELOG.md` (this file)
- `version.json` for machine-readable project metadata

## [5.3.0] — 2026-04-25

### Added
- `CERTIFICATION.md` — local certification guide with requirements, commands, troubleshooting
- `PROOF_TOUR.md` — structured 15-section proof architecture walkthrough
- `TOP_5_THEOREMS.md` — five strongest theorems with full technical detail
- `scripts/certify_all.sh` and `scripts/certify_all.ps1` — one-command proof suites
- `reports/v5_3_review_hardening_assessment.md`
- Reviewer-oriented comments in all major `.lisp` files
- `repo-check` CI job for document existence and defaxiom trace coverage

### Changed
- README.md: added "For ACL2 Reviewers" and "For Legal Reviewers" sections
- `reports/axiom_pressure_report.md`: added "Trusted-Base Summary for Reviewers" section
- `reports/proof_dependency_report.md`: added `denied-implies-prior-denial-path` theorem

### Unchanged
- Theorem count: 126
- Axiom count: 33
- Book count: 17
- No new defaxioms; no existing proofs modified

## [5.2.0] — 2026-04-24

### Added
- 43 new theorems (+52%): document proofs, burden proofs, doctrine proofs, deep process invariants, model consistency
- 9 new executable functions (`defun`)
- 1 new `defun-sk` proposition (`exists-citizen-facing-discretionary-denialp`)
- 1 new `encapsulate` block (Anderson-Burdick doctrinal standard)
- `reports/proof_dependency_report.md` — formal proof dependency tracking
- `reports/axiom_pressure_report.md` — axiom risk analysis with replacement paths
- 5 new ACL2 books: `burden_proofs`, `doctrine_proofs`, `deep_process_invariants`, `document_proofs`, `model_consistency`

### Changed
- Burden conclusions now **derived** from executable `defun` chain (previously assumed via defaxiom)
- Anderson-Burdick standard now introduced via `encapsulate` with local witnesses

### Unchanged
- Axiom count: 33 (no new defaxioms)

## [5.1.0] — 2026-04-23

### Added
- 2 additional theorems over v5.0
- Minor proof strengthening

## [5.0.0] — 2026-04-22

### Added
- Major upgrade from v4: 81 theorems (up from 52)
- 6 induction proofs (new capability)
- Existential modeling via `defun-sk` (3 propositions)
- Separated hinge semantics into 3 books
- General invariants over arbitrary traces
- Machine-checkable source traceability (`tools/validate_trace.py`)
- CI automation (`.github/workflows/acl2-proofs.yml`)
- Formal axiom inventory with classifications

### Changed
- Architecture: flat → layered with separated interpretive modules
- Process invariants: specific traces → general over arbitrary traces
- Document proofs: ground instances → recursive induction
