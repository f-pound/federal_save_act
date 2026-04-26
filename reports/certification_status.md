# Certification Status Report

## Summary

All **17 books** certify with ACL2 `certify-book`. This is the standard ACL2 certification method that generates `.cert` files with dependency tracking.

| Category | Count | certify-book flag |
|---|---|---|
| Clean (no defaxiom) | 6 | `(certify-book "name" ?)` |
| Contains defaxiom | 5 | `(certify-book "name" ? nil :defaxioms-okp t)` |
| Inherited defaxiom | 6 | `(certify-book "name" ? nil :defaxioms-okp t)` |
| **Total** | **17** | |

## Certification Matrix

| Book | Layer | certify-book | defaxiom | Source |
|---|---|---|---|---|
| `federal_save_act_core` | 0 | ✅ clean | None | — |
| `federal_save_act_process` | 1 | ✅ clean | None | includes core |
| `federal_save_act_consistency_check` | 1 | ✅ clean | None | includes core |
| `federal_save_act_facts` | 1 | ✅ defaxioms-okp | 3 own | includes core |
| `federal_save_act_process_invariants` | 2 | ✅ clean | None | includes process |
| `federal_save_act_document_proofs` | 2 | ✅ clean | None | includes process |
| `federal_save_act_hinge_common` | 2 | ✅ defaxioms-okp | 0 own, inherited | includes facts |
| `federal_save_act_existentials` | 2 | ✅ defaxioms-okp | 0 own, inherited | includes facts |
| `federal_save_act_burden_proofs` | 2 | ✅ defaxioms-okp | 0 own, inherited | includes facts |
| `federal_save_act_doctrine_proofs` | 2 | ✅ defaxioms-okp | 0 own, inherited | includes facts |
| `federal_save_act_model_consistency` | 2 | ✅ defaxioms-okp | 0 own, inherited | includes facts |
| `federal_save_act_independence` | 2 | ✅ defaxioms-okp | 0 own, inherited | includes facts |
| `federal_save_act_challenger_model` | 2 | ✅ defaxioms-okp | 12 own | includes facts |
| `federal_save_act_government_model` | 2 | ✅ defaxioms-okp | 15 own | includes facts |
| `federal_save_act_hinge_mandatory` | 3 | ✅ defaxioms-okp | 2 own | includes hinge_common |
| `federal_save_act_hinge_discretionary` | 3 | ✅ defaxioms-okp | 1 own | includes hinge_common |
| `federal_save_act_deep_process_invariants` | 3 | ✅ clean | None | includes process_inv |

## Dependency Graph

```
Layer 0:  core
            ├──────────────────────────────────────┐
Layer 1:  facts (defaxiom)      process            consistency_check
            │                      │
Layer 2:  hinge_common           process_invariants
          existentials           document_proofs
          burden_proofs
          doctrine_proofs
          model_consistency
          independence
          challenger_model (defaxiom)
          government_model (defaxiom)
            │                      │
Layer 3:  hinge_mandatory        deep_process_invariants
          hinge_discretionary
          (both defaxiom)
```

## What `:defaxioms-okp t` Means

ACL2's `certify-book` refuses to certify books containing `defaxiom` by default, because `defaxiom` introduces unverified assumptions that could make the logical world inconsistent. The `:defaxioms-okp t` flag tells ACL2: "I acknowledge the presence of defaxioms and accept the consistency risk."

In this project, the consistency risk is managed through:
1. **Source tracing**: Every defaxiom maps to a public legal source (verified by `validate_trace.py`).
2. **Classification**: Each defaxiom is labeled with its risk level (see `axiom_pressure_report.md`).
3. **Consistency checks**: `federal_save_act_consistency_check.lisp` proves 16 sanity theorems.
4. **Encapsulate witnesses**: Interpretive predicates use `encapsulate` with local witnesses (consistency-proved), not defaxiom.
5. **Burden derivation**: v5.2 replaced burden assumptions with executable `defun` chains.

## Clean vs. Defaxiom Significance

The **6 clean books** (core, process, consistency_check, process_invariants, document_proofs, deep_process_invariants) certify without any defaxiom acknowledgment. This means:

- The state machine model is **axiom-free**
- Process invariants (acceptance paths, denial paths, terminal stability) are **unconditionally proved**
- Document-list theorems are **unconditionally proved**
- The consistency check is **unconditionally proved**

The top 5 theorems in `TOP_5_THEOREMS.md` all come from clean books — they depend on zero axioms.

The **11 defaxiom-chain books** introduce legal assumptions (statutory text, scenario facts, interpretive readings). These are the books where **legal content enters the formal model**. The defaxiom-okp flag is ACL2's acknowledgment that this legal content is trusted, not proved.

## Scripts

| Script | What it does | Produces |
|---|---|---|
| `scripts/certify_books.sh` | Full certify-book in dependency order | `.cert` files + logs |
| `scripts/certify_books.ps1` | Same, for Windows PowerShell | `.cert` files + logs |
| `scripts/certify_all.sh` | Batch admission (acl2 < file.lisp) | Console Q.E.D. output + logs |
| `scripts/certify_all.ps1` | Same, for Windows PowerShell | Console Q.E.D. output + logs |

## CI

The GitHub Actions workflow (`.github/workflows/acl2-proofs.yml`) runs `certify-book` for all 17 books and verifies that every `.cert` file is generated. Certification logs are uploaded as workflow artifacts.
