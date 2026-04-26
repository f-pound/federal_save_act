# v5.3 Review-Hardening Assessment

## Summary

v5.3 does not substantially expand the legal model. v5.3 makes the existing v5.2 proof development easier to inspect, certify, audit, and explain to ACL2 and legal reviewers.

## What Changed from v5.2

### New Documents

| File | Purpose |
|---|---|
| `CERTIFICATION.md` | Local certification guide with requirements, commands, troubleshooting |
| `PROOF_TOUR.md` | Structured 15-section proof architecture walkthrough |
| `TOP_5_THEOREMS.md` | Five strongest theorems with full technical detail |
| `reports/v5_3_review_hardening_assessment.md` | This document |

### New Scripts

| File | Purpose |
|---|---|
| `scripts/certify_all.sh` | One-command proof suite for Linux/macOS |
| `scripts/certify_all.ps1` | One-command proof suite for Windows |

### Updated Files

| File | Change |
|---|---|
| `README.md` | Added "For ACL2 Reviewers" and "For Legal Reviewers" sections |
| `.github/workflows/acl2-proofs.yml` | Added repo-check job (document existence, defaxiom trace coverage) |
| `reports/axiom_pressure_report.md` | Added "Trusted-Base Summary for Reviewers" section |
| `reports/proof_dependency_report.md` | Added `denied-implies-prior-denial-path` theorem |
| Process/invariant/document/burden/doctrine `.lisp` files | Added reviewer-oriented comments to major theorems |

### What Did NOT Change

- **Theorem count**: 126 (unchanged)
- **Axiom count**: 33 (unchanged)
- **Book count**: 17 (unchanged)
- **Event count**: 262 (unchanged)
- **No new defaxioms** were introduced
- **No existing proofs** were modified

## Certification Instructions

See [CERTIFICATION.md](../CERTIFICATION.md) for full details. Quick start:

```bash
git clone https://github.com/f-pound/federal_save_act.git
cd federal_save_act
./scripts/certify_all.sh    # Linux/macOS
.\scripts\certify_all.ps1   # Windows
```

## Top 5 Theorems

See [TOP_5_THEOREMS.md](../TOP_5_THEOREMS.md) for full details.

| # | Theorem | Technique | Axioms Used |
|---|---|---|---|
| 1 | `registered-implies-prior-acceptance-path` | Trace induction | 0 |
| 2 | `denied-implies-prior-denial-path` | Trace induction | 0 |
| 3 | `all-nonqualifying-implies-no-documentary-proof` | List induction | 0 |
| 4 | `conflict-condition-pivots-on-valid-regulation` | Biconditional rewriting | 0 |
| 5 | `terminal-state-remains-terminal-under-run-trace` | Case split + trace induction | 0 |

All five depend on zero axioms — they are proved entirely from executable definitions.

## ACL2 Features Demonstrated

| Feature | Where |
|---|---|
| Recursive executable functions | `federal_save_act_process.lisp` (7 defuns) |
| Induction over event traces | `process_invariants.lisp`, `deep_process_invariants.lisp` |
| Induction over document lists | `document_proofs.lisp` |
| `encapsulate` with local witnesses | Challenger, government, hinge common, doctrine proofs |
| `defun-sk` Skolemization | `existentials.lisp` (4 propositions) |
| Executable derivation chains | `burden_proofs.lisp` (5-step chain) |
| Source-traced trusted base | `clause_trace.csv`, `source_manifest.json` |
| Machine-checkable validation | `tools/validate_trace.py` |
| CI automation | `.github/workflows/acl2-proofs.yml` |

## Remaining Proof Limitations

1. **No `certify-book` certification**: Books are run via `acl2 < file.lisp`, not `certify-book`. All theorems are proved, but `.cert` files are not generated.
2. **No functional instantiation**: Generalized theorems use universal quantification, not `:functional-instance` hints.
3. **No quantitative burden analysis**: ACL2 models boolean properties, not magnitudes.
4. **No refinement proofs**: The abstract process model is not formally proved to refine a concrete specification.
5. **Limited induction depth**: Simple list induction and trace induction. No nested induction or well-founded ordinal reasoning.
6. **Single concrete scenario**: Challenger and government models use citizen-a. Parameterized test frameworks remain a future extension.

## Remaining Legal-Modeling Limitations

1. **No poll tax formalization**: The Twenty-Fourth Amendment argument is not modeled.
2. **No manner-vs-qualification formalization**: The Art. I §2 / Art. I §4 structural argument is not modeled.
3. **No § 8(k) due process model**: The removal/cancellation process is not formalized.
4. **No multi-scenario testing**: Only one citizen (citizen-a) is modeled. Naturalized citizens, citizens with expired documents, etc. are not included.
5. **No quantitative burden severity**: The project models burden as boolean, not as a spectrum (none/minimal/moderate/severe).

## Recommended Next Steps Before Outside Review

1. **Run `certify-book`**: Generate `.cert` files for each book to provide the standard ACL2 certification artifact.
2. **Add a second scenario**: Model citizen-b (e.g., naturalized citizen with certificate) to demonstrate the framework generalizes beyond citizen-a.
3. **Functional instantiation**: Prove at least one theorem via `:functional-instance` to demonstrate the encapsulate constraints are satisfied by concrete witnesses.
4. **Independent review**: Have an ACL2 expert not involved in the project certify the books and evaluate the proof architecture.

## Positioning

This project is an early example of **A Computational Amicus Brief**: a machine-checkable, source-traced formal argument structure that exposes the assumptions and proof obligations behind competing legal theories.

It is **not** a judicial decision engine. It is **not** a general-purpose legal reasoning system. It is a focused ACL2 proof development for a single piece of legislation (H.R. 22) that demonstrates how formal methods can make legal arguments more transparent, auditable, and mechanically verifiable.
