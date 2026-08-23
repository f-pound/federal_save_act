# Certification Status Report

## Summary

All **25 books** certify with ACL2 `certify-book` (tested: ACL2 8.7 native via Homebrew, and the `atwalter/acl2` Docker image in CI). Run `./scripts/certify_books.sh`.

| Category | Count | certify-book flag |
|---|---|---|
| Clean (no defaxiom) | 12 | `(certify-book "name" ?)` |
| Contains defaxiom | 7 | `(certify-book "name" ? nil :defaxioms-okp t)` |
| Inherited defaxiom | 6 | `(certify-book "name" ? nil :defaxioms-okp t)` |
| **Total** | **25** | |

## Certification Matrix

| Book | Layer | certify-book | defaxiom | Theorems | Source |
|---|---|---|---|---|---|
| `lib/enum_list` | L | ✅ clean | None | 21 | — (generic) |
| `lib/lsm` | L | ✅ clean | None | 22 | includes lib/enum_list |
| `federal_save_act_core` | 0 | ✅ clean | None | 2 | — |
| `federal_save_act_document_rules` | 0 | ✅ clean (generated) | None | 0 | includes lib/enum_list |
| `federal_save_act_process_table` | 0 | ✅ clean (generated) | None | 0 | — |
| `federal_save_act_removal_table` | 0 | ✅ clean (generated) | None | 0 | — |
| `federal_save_act_process` | 0 | ✅ clean | None | 28 | includes core, document_rules, process_table, lib/lsm |
| `federal_save_act_removal_invariants` | 5 | ✅ clean | None | 11 | includes removal_table, lib/lsm |
| `federal_save_act_text_rules` | 1 | ✅ defaxioms-okp (generated) | 1 own | 0 | includes core |
| `federal_save_act_facts` | 1 | ✅ defaxioms-okp | 2 own | 0 | includes core, text_rules |
| `federal_save_act_scenario` | 1 | ✅ defaxioms-okp | 6 own | 3 | includes facts |
| `federal_save_act_hinge_common` | 2 | ✅ defaxioms-okp | 0 own, inherited | 4 | includes facts |
| `federal_save_act_hinge_mandatory` | 3 | ✅ defaxioms-okp | 1 own | 2 | includes hinge_common |
| `federal_save_act_hinge_discretionary` | 3 | ✅ defaxioms-okp | 1 own | 3 | includes hinge_common |
| `federal_save_act_existentials` | 4 | ✅ defaxioms-okp | 0 own, inherited | 6 | includes facts |
| `federal_save_act_burden_proofs` | 4 | ✅ defaxioms-okp | 0 own, inherited | 8 | includes facts |
| `federal_save_act_doctrine_proofs` | 4 | ✅ defaxioms-okp | 0 own, inherited | 7 | includes facts |
| `federal_save_act_model_consistency` | 4 | ✅ defaxioms-okp | 0 own, inherited | 7 | includes facts |
| `federal_save_act_independence` | 4 | ✅ defaxioms-okp | 0 own, inherited | 3 | includes facts |
| `federal_save_act_challenger_model` | 4 | ✅ defaxioms-okp | 6 own | 11 | includes scenario |
| `federal_save_act_government_model` | 4 | ✅ defaxioms-okp | 10 own | 5 | includes scenario |
| `federal_save_act_process_invariants` | 5 | ✅ clean | None | 16 | includes process |
| `federal_save_act_deep_process_invariants` | 5 | ✅ clean | None | 11 | includes process_invariants |
| `federal_save_act_document_proofs` | 5 | ✅ clean | None | 17 | includes process |
| `federal_save_act_consistency_check` | 6 | ✅ clean | None | 17 | includes core |

Total defaxioms: 1 (text_rules) + 2 (facts) + 6 + 1 + 1 + 6 + 10 = **27**.  Total theorems: **204**.

## Dependency Graph

```
Layer L:  lib/enum_list ──► lib/lsm
              │                │
Layer 0:  core   document_rules  process_table  removal_table   (generated from IR)
              │        │              │              │
              └────────┴──────────────┴──► process   └──► removal_invariants
              │
Layer 1:  text_rules (generated defaxiom) ──► facts (defaxiom) ──► scenario (defaxiom)
              │                     │
Layer 2:  hinge_common              │
Layer 3:  hinge_mandatory / hinge_discretionary (defaxiom; mutually exclusive)
              │                     │
Layer 4:  existentials, burden_proofs, doctrine_proofs,
          model_consistency, independence        challenger_model, government_model
                                                 (defaxiom; mutually exclusive)
Layer 5:  process_invariants ──► deep_process_invariants ;  document_proofs
Layer 6:  consistency_check (core only)
```

The two hinge books and the two party models are never loaded in the same session (they constrain `alternative-process-approvedp` / `valid-regulationp` in opposite directions).
