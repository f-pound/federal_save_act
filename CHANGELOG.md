# Changelog

All notable changes to the Federal SAVE Act ACL2 Constitutional Model are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
