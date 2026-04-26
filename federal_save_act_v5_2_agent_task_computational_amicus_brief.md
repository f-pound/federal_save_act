# Agent Task: v5.2 In-Place Upgrade Toward A Computational Amicus Brief

**Repository:** `https://github.com/f-pound/federal_save_act`

**Purpose:** Use this as the agent handoff document for the next in-place repository update.

---

## 1. Objective

Upgrade the existing `federal_save_act` project **in place** to make it a more legitimate ACL2 theorem-proving development, focused only on the Federal SAVE Act model.

Do **not** build the full generic engine yet.

Do **not** prioritize general reusability for multiple laws yet.

The priority is to make this project credible to:

1. serious ACL2 / Lisp theorem-proving professionals;
2. legal scholars and litigators evaluating formal legal reasoning;
3. constitutional-law experts interested in machine-checkable legal argument structure.

The project should demonstrate that ACL2 is doing real proof work, not merely checking that hand-stated conclusions follow from hand-stated assumptions.

This v5.2 step should position the project as a precursor to **A Computational Amicus Brief**, not as the full engine itself.

---

## 2. Positioning

The repository should be presented as:

```text
A serious ACL2 formalization of a live federal election-law controversy,
using public legal sources, executable process semantics, induction over
registration traces and document lists, encapsulated interpretive theories,
and machine-checked conditional constitutional theorems.
```

It should **not** yet be presented as:

```text
A general automated legal reasoning engine.
```

A future project may generalize these methods into **A Computational Amicus Brief**. For now, this repository remains focused on the Federal SAVE Act.

---

## 3. Guiding Principle

Prefer this development pattern:

```text
public legal source
-> source-traced proposition
-> executable ACL2 model
-> intermediate lemmas
-> induction over traces/lists
-> conditional constitutional theorem
```

Avoid this development pattern:

```text
desired legal conclusion
-> defaxiom
-> defthm restating the conclusion
```

The model must remain honest:

```text
ACL2 does not decide the constitutional question.
ACL2 proves conditional consequences of a formalized legal model.
The value is exposing assumptions, verifying process logic, checking doctrinal
dependency, and making legal argument mechanically auditable.
```

---

## 4. Core v5.2 Goal

Make the Federal SAVE Act model stronger as an ACL2 proof development by adding:

1. deeper process invariants;
2. more induction proofs;
3. fewer one-off legal conclusion axioms;
4. clearer use of `encapsulate`;
5. stronger existential and class-burden modeling;
6. better separation between source facts, empirical assumptions, doctrine, and derived conclusions;
7. machine-checkable consistency and non-contradiction properties;
8. proof reports that distinguish genuine theorems from assumed premises.

---

## 5. Required Deliverables

Add or update these files:

```text
federal_save_act_deep_process_invariants.lisp
federal_save_act_document_proofs.lisp
federal_save_act_burden_proofs.lisp
federal_save_act_doctrine_proofs.lisp
federal_save_act_model_consistency.lisp
reports/v5_2_acl2_proof_assessment.md
reports/axiom_pressure_report.md
reports/proof_dependency_report.md
```

Do not remove existing v5.1 files unless necessary. Existing books must continue to certify.

---

## 6. Workstream Summary

| Workstream | Primary file | Minimum theorem target | Proof emphasis |
|---|---|---:|---|
| Deep process invariants | `federal_save_act_deep_process_invariants.lisp` | 6+ | Trace induction, terminal states, no skipped stages |
| Document-list proofs | `federal_save_act_document_proofs.lisp` | 6+ | List induction, qualifying-document preservation |
| Burden derivation | `federal_save_act_burden_proofs.lisp` | 4+ | Derive burden from lower-level predicates |
| Existential/class burden | `federal_save_act_existentials.lisp` | 3+ | `defun-sk` / `defchoose` witness style |
| Doctrine chains | `federal_save_act_doctrine_proofs.lisp` | 4+ | Conditional doctrine, no judicial overclaiming |
| Model consistency | `federal_save_act_model_consistency.lisp` | 4+ | Sanity and dependency checks |

---

## 7. Task 1 - Add Deeper Process Invariants

Create:

```text
federal_save_act_deep_process_invariants.lisp
```

Import the existing process and process-invariant books.

The current project already proves important trace properties, including that registration requires a prior acceptance path. Now deepen that work.

Add theorems over arbitrary traces, not only named examples.

### 7.1 Terminal exclusivity

Prove that a process trace cannot result in both registration and denial.

Example theorem shapes:

```lisp
(defthm registered-state-not-denied-state
  ...)

(defthm denied-state-not-registered-state
  ...)

(defthm terminal-outcomes-mutually-exclusive
  ...)
```

### 7.2 Absorbing terminal states

Prove that once the process reaches a terminal state, further events do not change the legal outcome unless the model explicitly allows reopening.

```lisp
(defthm registered-is-absorbing
  ...)

(defthm denied-is-absorbing
  ...)

(defthm terminal-state-remains-terminal-under-run-trace
  ...)
```

### 7.3 Acceptance precondition

Strengthen existing acceptance-path logic.

Prove:

```text
A trace can reach :registered only if it previously passed through either:
  :doc-accepted
  or
  :alt-approved.
```

Then prove a stronger version:

```text
If the trace reaches :registered from :submitted, then the process contains a
valid acceptance event before registration.
```

This should require induction over traces.

### 7.4 Denial precondition

Add the analogous denial theorem:

```text
A trace can reach :denied only if it contains a denial-triggering path:
  documentary proof failed;
  alternative process denied;
  or equivalent modeled denial event.
```

### 7.5 No skipped process stages

Prove that registration cannot be reached directly from initial submission without an intermediate acceptance state.

```lisp
(defthm no-direct-submission-to-registration
  ...)
```

### 7.6 Minimum acceptance criteria

- At least 6 new process invariant theorems.
- At least 2 should require induction over traces.
- The comments should explain why these are real process-verification theorems relevant to legal due-process / registration-process analysis.

---

## 8. Task 2 - Add Document-List Proofs

Create:

```text
federal_save_act_document_proofs.lisp
```

The project should show ACL2 reasoning over document collections, not merely single document predicates.

Use existing document recognizers and add theorem work around:

```text
qualifying documents
nonqualifying documents
document lists
appending evidence
removing irrelevant documents
documentary-proof sufficiency
```

Target theorems:

```lisp
(defthm empty-document-list-has-no-qualifying-document
  ...)

(defthm qualifying-document-member-implies-documentary-proof
  ...)

(defthm append-preserves-qualifying-document-left
  ...)

(defthm append-preserves-qualifying-document-right
  ...)

(defthm removing-nonqualifying-documents-preserves-proof-status
  ...)

(defthm all-nonqualifying-documents-implies-no-documentary-proof
  ...)
```

Where needed, define recursive helpers such as:

```lisp
(all-nonqualifying-documentsp docs)
(remove-nonqualifying-documents docs)
(has-documentary-proof-from-doc-listp docs)
```

### 8.1 Minimum acceptance criteria

- At least 6 document-list theorems.
- At least 2 should require induction over lists.
- These theorems should feed into the SAVE Act denial-trigger analysis.

---

## 9. Task 3 - Reduce One-Off Burden Assumptions

Create:

```text
federal_save_act_burden_proofs.lisp
```

The current model still relies on named assumptions about burden, hardship, and lack of access. Keep source-traced empirical assumptions where necessary, but derive more intermediate burden conclusions.

Do not simply assert:

```lisp
(severe-burdenp ...)
```

where it can be derived from lower-level predicates.

Add or refine predicates such as:

```lisp
(lacks-all-qualifying-documentsp p)
(cannot-reasonably-obtain-qualifying-documentp p)
(no-adequate-alternative-process-forp p x)
(risk-of-erroneous-denialp p x)
(material-burdenp p x)
(severe-burdenp p x)
```

Target theorem chain:

```text
lacks all qualifying documents
+ cannot reasonably obtain them
-> material burden

material burden
+ no adequate alternative process
-> substantial denial risk

material burden
+ substantial denial risk
-> severe burden under challenger theory
```

Example theorem shapes:

```lisp
(defthm lacks-documents-and-cannot-obtain-implies-material-burden
  ...)

(defthm material-burden-plus-no-alternative-implies-denial-risk
  ...)

(defthm material-burden-plus-denial-risk-implies-severe-burden
  ...)
```

Use `encapsulate` if the legal standard itself must remain abstract, but ensure the exported theorems expose the dependencies clearly.

### 9.1 Minimum acceptance criteria

- At least 4 new burden theorems.
- At least 2 existing one-off burden-related assumptions should be replaced or demoted into lower-level empirical assumptions.
- The report must identify which assumptions remain empirical and which conclusions are now derived.

---

## 10. Task 4 - Strengthen Existential and Class-Burden Modeling

Update or extend:

```text
federal_save_act_existentials.lisp
```

The current project uses `defun-sk`, which is good. Now make it more legally meaningful.

Model existence claims such as:

```text
There exists an eligible voter who lacks all qualifying documentary proof.

There exists an eligible voter who cannot reasonably obtain qualifying proof.

There exists an eligible voter who faces a nontrivial risk of denial under the
discretionary alternative process.

There exists a class of eligible voters for whom the burden is not merely
hypothetical.
```

Use `defun-sk` or `defchoose` where appropriate.

Target theorems:

```lisp
(defthm exists-documentless-eligible-voter-implies-burden-class-nonempty
  ...)

(defthm exists-burdened-voter-implies-law-has-nontrivial-burden
  ...)

(defthm discretionary-denial-witness-implies-erroneous-denial-risk
  ...)
```

### 10.1 Minimum acceptance criteria

- At least 3 new existential/class-burden theorems.
- Use ACL2's quantified/witness style intentionally.
- Avoid reducing everything back to only `'citizen-a`.

---

## 11. Task 5 - Strengthen Doctrine Proofs Without Overclaiming

Create:

```text
federal_save_act_doctrine_proofs.lisp
```

The goal is not to "prove constitutional law." The goal is to encode conditional doctrine more cleanly.

Separate:

```text
source text
empirical burden facts
doctrinal rule
interpretive assumption
derived constitutional conclusion
```

Add theorem chains such as:

```text
qualified voter
+ denial of federal registration
+ invalid regulation
-> constitutional conflict condition

valid regulation
-> no constitutional conflict condition

severe burden
+ insufficient justification
-> invalid regulation under challenger theory

important government interest
+ reasonable fit
+ adequate alternative process
-> valid regulation under government theory
```

Target theorem shapes:

```lisp
(defthm invalid-regulation-enables-conflict-condition
  ...)

(defthm valid-regulation-negates-conflict-condition
  ...)

(defthm severe-burden-and-inadequate-alternative-support-invalidity
  ...)

(defthm important-interest-and-adequate-alternative-support-validity
  ...)
```

Where possible, these should use previous process, burden, and hinge theorems.

### 11.1 Minimum acceptance criteria

- At least 4 doctrine theorems.
- At least one theorem should be challenger-favorable.
- At least one theorem should be government-favorable.
- The comments must explicitly state that ACL2 proves conditional doctrine consequences, not actual judicial holdings.

---

## 12. Task 6 - Improve Use of `encapsulate`

Audit existing uses of `encapsulate`.

Improve them where possible so that party theories and doctrinal standards are represented as abstract but satisfiable theories, not as bare conclusions.

Focus areas:

```text
challenger theory
government theory
mandatory alternative-process reading
discretionary alternative-process reading
valid-regulation doctrine
severe-burden doctrine
```

For each relevant `encapsulate`, ensure:

1. local witness functions exist;
2. exported constraints are clear;
3. exported theorems are not just restatements of desired conclusions;
4. the local witnesses demonstrate consistency;
5. comments explain the legal interpretation being modeled.

### 12.1 Minimum acceptance criteria

- At least 2 encapsulate blocks should be improved or documented more rigorously.
- The v5.2 report should explain why `encapsulate` is preferable to `defaxiom` for these theory components.

---

## 13. Task 7 - Add Model Consistency Checks

Create:

```text
federal_save_act_model_consistency.lisp
```

This should certify sanity properties of the model.

Target checks:

```text
The same trace cannot produce both registered and denied.

The mandatory and discretionary interpretations are not accidentally loaded as
the same theory.

Government and challenger conclusions are not proved from neutral facts alone.

The final conflict and no-conflict conclusions depend on disputed assumptions.

No book accidentally imports both incompatible party theories unless explicitly
testing inconsistency.
```

Target theorem shapes:

```lisp
(defthm no-trace-produces-both-registered-and-denied
  ...)

(defthm conflict-condition-pivots-on-valid-regulation
  ...)

(defthm neutral-facts-do-not-settle-outcome
  ...)
```

If ACL2 cannot directly prove "not derivable," use explicitly documented structural decompositions or two-world encapsulate witnesses.

### 13.1 Minimum acceptance criteria

- At least 4 consistency/sanity theorems.
- Must avoid loading mutually inconsistent books unless the file is explicitly an inconsistency demonstration.
- Must explain what ACL2 is and is not proving about independence.

---

## 14. Reporting Tasks

### 14.1 Axiom Pressure Report

Create:

```text
reports/axiom_pressure_report.md
```

This report should be candid and technical.

For each remaining `defaxiom`, list:

```text
event name
file
classification
source id
why it remains an axiom
whether it is source text, empirical, doctrinal, interpretive, bridge, or scenario
whether it could be replaced by:
  executable definition
  theorem from lower-level facts
  encapsulate constraint
  defun-sk witness
  external empirical record
```

Also include:

```text
number of defaxioms before v5.2
number of defaxioms after v5.2
number of assumptions demoted to lower-level facts
number of conclusions converted into theorems
highest-risk remaining axioms
```

The key purpose is to show serious ACL2 users that the project knows where its trusted base is.

### 14.2 Proof Dependency Report

Create:

```text
reports/proof_dependency_report.md
```

This report should list major final theorems and their dependency chains.

For example:

```text
challenger-model-finds-conflict
  depends on:
    statutory text facts
    document insufficiency facts
    no adequate alternative assumption
    burden theorem
    invalid regulation doctrine theorem
    constitutional conflict definition

government-model-no-conflict
  depends on:
    statutory text facts
    important government interest assumption
    reasonable fit assumption
    adequate alternative process assumption
    valid regulation doctrine theorem
```

The point is to distinguish:

```text
proved by ACL2
assumed from source text
assumed empirically
assumed doctrinally
assumed interpretively
```

This will matter to legal professionals.

### 14.3 v5.2 ACL2 Proof Assessment

Create:

```text
reports/v5_2_acl2_proof_assessment.md
```

Include:

1. Summary of v5.2 upgrade;
2. number of ACL2 books;
3. number of executable functions;
4. number of recursive functions;
5. number of induction proofs;
6. number of `defthm` events;
7. number of `defaxiom` events;
8. number of `encapsulate` blocks;
9. number of `defun-sk` / `defchoose` forms;
10. number of document-list theorems;
11. number of process-invariant theorems;
12. number of burden theorems;
13. number of doctrine theorems;
14. remaining trusted assumptions;
15. why this is stronger ACL2 theorem proving than v5.1;
16. why this is still not a judicial decision engine;
17. next proof-theoretic upgrades.

Suggested language:

```text
v5.2 focuses on ACL2 proof legitimacy, not general-engine reusability.
It deepens the Federal SAVE Act model through list induction, trace induction,
burden derivation, doctrine chaining, encapsulated legal theories, and explicit
trusted-base reporting.
```

---

## 15. README Update

Update `README.md`.

Add a section:

```text
v5.2: ACL2 Proof-Legitimacy Upgrade
```

This section should say:

```text
v5.2 does not build the future A Computational Amicus Brief engine.
v5.2 strengthens the Federal SAVE Act proof development itself.
The focus is on legitimate ACL2 theorem proving:
  recursive executable models,
  induction over traces and document lists,
  derived burden conclusions,
  doctrinal theorem chains,
  encapsulated theory components,
  source-traced trusted assumptions,
  and proof dependency reporting.
```

Avoid language that makes the repo sound like a generic legal engine yet.

Use forward-looking language only:

```text
A future project may generalize these methods into A Computational Amicus Brief.
For now, this repository remains focused on the Federal SAVE Act.
```

---

## 16. CI Update

Update GitHub Actions to run the new books:

```text
federal_save_act_deep_process_invariants.lisp
federal_save_act_document_proofs.lisp
federal_save_act_burden_proofs.lisp
federal_save_act_doctrine_proofs.lisp
federal_save_act_model_consistency.lisp
```

CI should continue to run:

```text
trace validator
all v5.1 books
all new v5.2 books
```

CI should fail if:

```text
ACL2 certification fails;
trace validation fails;
a new unclassified defaxiom appears;
a source ID is missing;
a report is stale or missing.
```

---

## 17. Acceptance Criteria

v5.2 is complete when:

1. Existing v5.1 ACL2 books still certify.
2. All new v5.2 ACL2 books certify.
3. CI passes.
4. At least 6 deeper process invariant theorems are added.
5. At least 6 document-list theorems are added.
6. At least 4 burden derivation theorems are added.
7. At least 3 existential/class-burden theorems are added.
8. At least 4 doctrine theorem-chain theorems are added.
9. At least 4 model-consistency/sanity theorems are added.
10. At least 4 total new induction proofs appear across trace/list reasoning.
11. At least 2 one-off legal conclusion assumptions are replaced or demoted.
12. At least 2 encapsulate blocks are improved or documented.
13. `reports/axiom_pressure_report.md` exists.
14. `reports/proof_dependency_report.md` exists.
15. `reports/v5_2_acl2_proof_assessment.md` exists.
16. README clearly states that v5.2 is about ACL2 proof legitimacy for the Federal SAVE Act only.

---

## 18. Future Direction: A Computational Amicus Brief

The future engine can come later. The staged path should be:

```text
v5.1 - source-traced Federal SAVE Act formal prototype
v5.2 - ACL2 proof-legitimacy upgrade for the Federal SAVE Act
v6 - possible framework and law-specific instances
v7 - A Computational Amicus Brief: automated construction and checking of conditional legal arguments
```

Required positioning language:

```text
A Computational Amicus Brief does not automate judicial judgment.
It automates the construction, checking, and comparison of conditional legal
arguments from source-traced assumptions.
```

---

## 19. Agent Completion Checklist

- [ ] Run trace validator.
- [ ] Run ACL2 certification for all existing books.
- [ ] Run ACL2 certification for all new v5.2 books.
- [ ] Confirm theorem counts and induction counts.
- [ ] Confirm no new unclassified `defaxiom`s.
- [ ] Confirm reports are present and updated.
- [ ] Confirm README uses **A Computational Amicus Brief** and contains no stale reference to the earlier project name.
- [ ] Push changes only after CI passes.

---

## 20. Final Instruction

For v5.2, make `federal_save_act` impressive enough that ACL2 experts see real theorem-proving discipline and legal professionals see a transparent, source-traced, formally checked argument structure.

The future **A Computational Amicus Brief** engine can come later.

For now, make the Federal SAVE Act proof development excellent.
