# Proof Tour: Federal SAVE Act ACL2 Development

This document provides a structured walkthrough of the proof architecture for ACL2 and legal reviewers. Reading time: approximately 10–15 minutes.

## Positioning

ACL2 does not decide whether the SAVE Act is constitutional.

ACL2 proves conditional consequences of explicitly formalized legal models. The value is **assumption exposure**, **process verification**, **source traceability**, and **mechanically checked derivation**.

This project is an early example of **A Computational Amicus Brief**: a machine-checkable, source-traced formal argument structure that exposes the assumptions and proof obligations behind competing legal theories.

## Pipeline

```
Public legal sources (H.R. 22, NVRA, Constitution, case law)
  ↓
source_manifest.json + clause_trace.csv
  ↓
classified ACL2 assumptions (defaxiom with labels)
  ↓
executable process model (defun state machine)
  ↓
document-list and trace induction (defthm with induction)
  ↓
burden and doctrine theorem chains (defun derivation + encapsulate)
  ↓
challenger/government conditional conclusions (defthm)
  ↓
computational amicus-style proof report
```

---

## 1. What the Project Proves

- **126 theorems**, all Q.E.D., across 17 ACL2 books.
- Under the **challenger's** interpretive model, a constitutional conflict exists for eligible citizens who lack documentary proof, face material burden, and are denied through the alternative process.
- Under the **government's** interpretive model, no constitutional conflict exists because the SAVE Act is a valid regulation with an adequate alternative process.
- The constitutional outcome **pivots on** `valid-regulationp` — a single unconstrained predicate that neither neutral statutory text nor the process model determines.
- Registration requires a prior acceptance path (document acceptance or alternative process approval).
- Denial requires a denial-triggering path (document rejection, alternative denial, or direct denial from submission).
- A collection of entirely nonqualifying documents cannot satisfy the documentary proof requirement.
- Burden severity is derived from constituent predicates, not assumed.

## 2. What the Project Does Not Prove

- Whether the SAVE Act **is** constitutional or unconstitutional.
- Whether the challenger's empirical assumptions (burden severity) are factually true.
- Whether the government's doctrinal claims (rational connection, evenhandedness) are legally correct.
- Whether a court would adopt the mandatory or discretionary reading of § 8(j)(2)(A).
- The magnitude of the burden (ACL2 models boolean properties, not quantitative assessments).
- That the formal model accurately captures all aspects of the real legal system.

## 3. Trusted Base

The project rests on **33 defaxioms** (see `reports/axiom_pressure_report.md`):

| Category | Count | Risk Level |
|---|---|---|
| Scenario facts (citizen-a properties) | 14 | Low |
| Government interpretive assumptions | 6 | Medium |
| Bridge rules (structural connectors) | 5 | Low |
| Empirical assumptions | 3 | **High** |
| Interpretive assumptions (hinge) | 2 | Medium |
| Doctrinal rules | 2 | Medium |
| Challenger interpretive assumption | 1 | Medium |

Everything else — 126 theorems, 24 defuns, 4 defun-sks, 4 encapsulates — is proved or consistency-checked by ACL2.

## 4. Source Traceability

Every defaxiom maps to a public legal source:
- **38 trace rows** in `sources/clause_trace.csv`
- **21 authoritative sources** in `sources/source_manifest.json`
- Each row records: axiom name → classification → source_id → section → quoted clause text
- Machine-checkable via `python tools/validate_trace.py`

## 5. Executable Process Model

**File**: `federal_save_act_process.lisp`

A 7-state, 9-event registration state machine modeled as recursive ACL2 functions:
- States: unsubmitted → submitted → doc-accepted / doc-rejected → alt-approved / alt-denied → registered / denied
- `reg-next-state`: single-step transition function
- `reg-run-trace`: recursive trace executor over arbitrary event lists
- Document recognizers: `qualifying-document-typep`, `qualifying-document-listp`, `has-qualifying-docs-from-listp`

This is genuine executable ACL2 — the state machine runs on any event trace.

## 6. Document-List Reasoning

**File**: `federal_save_act_document_proofs.lisp` (9 theorems)

Key theorem: `all-nonqualifying-implies-no-documentary-proof` — if every document in a collection fails `qualifying-document-typep`, the collection cannot satisfy the statutory requirement. Proved by induction on the document list.

This is a **structural denial theorem**: a citizen with only nonqualifying documents is structurally unable to satisfy the SAVE Act requirement through the documentary proof path.

## 7. Deep Process Invariants

**File**: `federal_save_act_deep_process_invariants.lisp` (9 theorems)

Key theorems:
- `terminal-state-remains-terminal-under-run-trace` — once decided, no further events change the outcome
- `denied-implies-prior-denial-path` — denial requires a denial-triggering state (induction)
- `no-registration-without-submission` — cannot register without submitting (induction)

These are genuine process-verification results over arbitrary traces.

## 8. Burden Derivation Chain

**File**: `federal_save_act_burden_proofs.lisp` (8 theorems)

Five executable `defun` predicates derive burden conclusions from lower-level inputs:
```
lacks-all-qualifying-documentsp
  + cannot-obtain-qualifying-documents-without-material-burdenp (defstub)
  → material-burdenp
    + no-adequate-alternative-forp
    → denial-riskp
      → severe-burdenp-derived
```

The empirical inputs remain as defstubs. The intermediate conclusions are **proved, not assumed**.

## 9. Hinge Interpretation Model

**Files**: `federal_save_act_hinge_common.lisp`, `_mandatory.lisp`, `_discretionary.lisp`

The SAVE Act's alternative attestation process (§ 8(j)(2)(A)) is the primary interpretive hinge:
- **Mandatory reading**: officials "shall" approve if evidence is sufficient → no denial possible
- **Discretionary reading**: officials "shall make a determination" ≠ "shall register" → denial is possible

These are modeled as separate ACL2 books with mutually exclusive semantics.

## 10. Doctrine Proof Chains

**File**: `federal_save_act_doctrine_proofs.lisp` (7 theorems)

An Anderson-Burdick encapsulate introduces the doctrinal standard with local witnesses. Bidirectional theorem chains:
- `invalid-regulation-enables-conflict-condition` (challenger direction)
- `valid-regulation-negates-conflict-condition` (government direction)

Every doctrine theorem is a conditional implication — ACL2 does not assert which direction is correct.

## 11. Existential / Class-Burden Modeling

**File**: `federal_save_act_existentials.lisp` (6 theorems, 4 defun-sk)

`defun-sk` propositions express "there exists a citizen who..." rather than relying on the named citizen-a scenario:
- `exists-citizen-lacking-proofp`
- `exists-citizen-with-unreasonable-burdenp`
- `exists-citizen-lacking-docs-no-faultp`
- `exists-citizen-facing-discretionary-denialp`

Bridge theorems connect witnesses to class-burden claims.

## 12. Model Consistency Checks

**File**: `federal_save_act_model_consistency.lisp` (7 theorems)

Structural sanity checks:
- Terminal outcomes are mutually exclusive
- `conflict-condition-pivots-on-valid-regulation` (iff theorem)
- Compositional decomposition of the full conflict condition
- Denial trigger scoping (requires actual registration transaction)

## 13. Challenger Conditional Theorem

**File**: `federal_save_act_challenger_model.lisp`

`challenger-model-finds-conflict`: Under the challenger's 14 assumptions, constitutional conflict exists for citizen-a. The encapsulate proves that the interpretive rules are jointly consistent.

## 14. Government Conditional Theorem

**File**: `federal_save_act_government_model.lisp`

`government-model-no-conflict`: Under the government's 16 assumptions, no constitutional conflict exists. The government defeats conflict through two independent paths: valid regulation AND alternative process approval.

## 15. How to Certify Locally

See [CERTIFICATION.md](CERTIFICATION.md) for full instructions. Quick start:

```bash
git clone https://github.com/f-pound/federal_save_act.git
cd federal_save_act
./scripts/certify_all.sh    # Linux/macOS
.\scripts\certify_all.ps1   # Windows PowerShell
```
