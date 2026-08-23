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

- **204 theorems**, all Q.E.D., across 25 ACL2 books (4 generated from the clause IR) — 43 of them in two generic, statute-independent lemma libraries (`model/lib/`).
- Under the **challenger's** interpretive model, a constitutional conflict exists for eligible citizens who lack documentary proof, face material burden, and are denied through the alternative process.
- Under the **government's** interpretive model, no constitutional conflict exists because the SAVE Act is a valid regulation with an adequate alternative process.
- The constitutional outcome **pivots on** `valid-regulationp` — a single unconstrained predicate that neither neutral statutory text nor the process model determines.
- Registration requires a prior acceptance path (document acceptance or alternative process approval).
- Denial requires a denial-triggering path (document rejection, alternative denial, or direct denial from submission).
- A collection of entirely nonqualifying documents cannot satisfy the documentary proof requirement; a supporting document (birth certificate, naturalization certificate, …) is proof only together with a government photo ID (§ 3(b)(5)).
- Burden severity is derived from constituent predicates, not assumed.

## 2. What the Project Does Not Prove

- Whether the SAVE Act **is** constitutional or unconstitutional.
- Whether the challenger's empirical assumptions (burden severity) are factually true.
- Whether the government's doctrinal claims (rational connection, evenhandedness) are legally correct.
- Whether a court would adopt the mandatory or discretionary reading of § 8(j)(2)(A).
- The magnitude of the burden (ACL2 models boolean properties, not quantitative assessments).
- That the formal model accurately captures all aspects of the real legal system.

## 3. Trusted Base

The project rests on **27 defaxioms** (see `reports/axiom_pressure_report.md`):

| Category | Count | Risk Level |
|---|---|---|
| Scenario facts (citizen-a properties, shared book) | 6 | Low |
| Government interpretive assumptions | 6 | Medium |
| Bridge rules (structural connectors) | 5 | Low |
| Empirical assumptions | 3 | **High** |
| Interpretive assumptions (hinge) | 2 | Medium |
| Doctrinal rules | 2 | Medium |
| Challenger interpretive assumption | 1 | Medium |

Everything else — 204 theorems, 49 defuns, 4 defun-sks, 4 encapsulates — is proved or consistency-checked by ACL2.

## 4. Source Traceability

Every defaxiom maps to a public legal source:
- **32 trace rows** in `sources/clause_trace.csv`
- **21 authoritative sources** in `sources/source_manifest.json`
- Each row records: axiom name → classification → source_id → section → quoted clause text
- Machine-checkable via `python tools/validate_trace.py`

## 5. Executable Process Model

**File**: `federal_save_act_process.lisp`

A 10-state, 9-event registration state machine written as a **13-row edge table** `*reg-edges*` — generated from `data/parsed/federal_save_act_process_table.json`, where every edge carries a § citation and a TEXT_FACT / MODEL_STRUCTURE label — and interpreted by the generic `lib/lsm` book:
- States: unsubmitted → submitted → doc-presented → doc-accepted / doc-rejected → alt-initiated → alt-approved / alt-denied → registered / denied
- `reg-next-state` = `(lsm-step s e *reg-edges*)`; `reg-run-trace` = `(lsm-run s events *reg-edges*)`
- `*reg-acceptance-states*` and `*reg-denial-states*` are *computed* from the table with `lsm-sources-into`, not hand-listed
- Document recognizers: `has-qualifying-docs-from-listp` = the generated `documentary-proof-bundlep`, over category tables compiled from `data/parsed/federal_save_act_document_rules.json`

This is genuine executable ACL2 — the state machine runs on any event trace — and because the process is data, every invariant is an instance of a library theorem discharged by evaluating the table.

## 6. Document-List Reasoning

**File**: `federal_save_act_document_proofs.lisp` (9 theorems)

Key theorem: `all-nonqualifying-implies-no-documentary-proof` — if every document in a collection is unrecognised by § 3(b), the collection cannot satisfy the statutory requirement. An instance of `none-in-catsp-narrow` / `some-in-catsp-iff-not-none-in-catsp` from `lib/enum_list`; the induction lives in the library. New in v6: `singleton-supporting-list-has-no-proof` and `anchor-and-supporting-pair-has-proof` capture the § 3(b)(5) pairing rule.

This is a **structural denial theorem**: a citizen with only nonqualifying documents is structurally unable to satisfy the SAVE Act requirement through the documentary proof path.

## 7. Deep Process Invariants

**File**: `federal_save_act_deep_process_invariants.lisp` (9 theorems)

Key theorems:
- `terminal-state-remains-terminal-under-run-trace` — once decided, no further events change the outcome
- `denied-implies-prior-denial-path` — denial requires a denial-triggering state (induction)
- `no-registration-without-submission` — cannot register without submitting (induction)

These are genuine process-verification results over arbitrary traces. In v6 each is a `:use` instance of `lsm-run-absorbing`, `lsm-run-entry-guard`, or `lsm-run-exit-guard`; no statute-specific induction or case analysis remains.

## 7a. § 8(k) Removal Process (v6)

**File**: `federal_save_act_removal_invariants.lisp` (11 theorems), table generated from `data/parsed/federal_save_act_removal_table.json`.

§ 8(k) names two steps — receipt of verified noncitizen information, and removal "at any time" upon receipt. The table holds those two TEXT_FACT edges plus five DUE_PROCESS_OVERLAY edges (notice, contest, confirmation) the statute does **not** contain. The theorems, all `lib/lsm` instances, state mechanically what earlier versions could only say in prose: `statutory-path-has-no-notice-or-hearing`, `text-edges-alone-reach-removal`, `removal-implies-prior-information-receipt`, `removed-is-absorbing` (no statutory reinstatement), `reinstatement-requires-contest-path` (only via the overlay). Neutral: the book does not assert that this is unconstitutional.

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
