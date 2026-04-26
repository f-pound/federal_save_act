# Top 5 Theorems

These five theorems best demonstrate genuine ACL2 theorem-proving work in this project. They are selected for **technical strength**, not legal drama.

---

## 1. `registered-implies-prior-acceptance-path`

**File**: `federal_save_act_process_invariants.lisp`

**ACL2 feature demonstrated**: Induction over registration traces.

**Plain-English statement**: If the registration process reaches the `:registered` state, the trace must have passed through an acceptance state — either documentary proof was accepted (`:doc-accepted`) or the alternative process was approved (`:alt-approved`).

**Why it matters legally**: Registration is not an arbitrary terminal state in the model. It must be preceded by a legally meaningful acceptance path. This is a procedural due-process property: the model guarantees that registration decisions are substantively grounded.

**Why it matters to ACL2 reviewers**: This is a genuine invariant over arbitrary traces, not a hardcoded example. The proof uses structural induction on the event list, with a helper theorem (`register-requires-acceptance-state`) establishing the base case via case analysis on `reg-next-state`.

**Dependencies**: `reg-run-trace` (defun), `reg-next-state` (defun), `trace-passed-through-acceptance-statep` (defun), `register-requires-acceptance-state` (defthm — case analysis).

**Trusted assumptions**: None. This theorem depends only on executable definitions.

**Reviewer command**:
```bash
docker compose run --rm acl2 acl2 < federal_save_act_process_invariants.lisp
```

---

## 2. `denied-implies-prior-denial-path`

**File**: `federal_save_act_deep_process_invariants.lisp`

**ACL2 feature demonstrated**: Induction over registration traces with explicit measure.

**Plain-English statement**: If a trace starting from a non-denied state reaches the `:denied` state, it must have passed through a denial-triggering state: `:doc-rejected`, `:alt-denied`, or `:submitted` (direct denial without attempting documents or alternative).

**Why it matters legally**: Denial cannot occur arbitrarily. The model requires that the applicant's documentary proof failed, the alternative process was denied, or the applicant was denied directly from submission. This is the denial-side dual of theorem #1.

**Why it matters to ACL2 reviewers**: The proof uses induction on the event list with a helper function `trace-passed-through-denial-statep` that tracks denial-triggering states through the trace. The measure declaration `(acl2-count events)` ensures termination.

**Dependencies**: `reg-run-trace` (defun), `reg-next-state` (defun), `trace-passed-through-denial-statep` (defun), `denied-requires-denial-state` (defthm — case analysis).

**Trusted assumptions**: None. This theorem depends only on executable definitions.

**Reviewer command**:
```bash
docker compose run --rm acl2 acl2 < federal_save_act_deep_process_invariants.lisp
```

---

## 3. `all-nonqualifying-implies-no-documentary-proof`

**File**: `federal_save_act_document_proofs.lisp`

**ACL2 feature demonstrated**: Induction over document lists (structural denial).

**Plain-English statement**: If every document in a collection fails the `qualifying-document-typep` test, then the collection cannot satisfy the documentary proof requirement.

**Why it matters legally**: This is the key "structural denial" theorem. A citizen who possesses only nonqualifying documents is **structurally unable** to satisfy the SAVE Act requirement through the documentary proof path. The denial is mandated by the document structure, not by official discretion.

**Why it matters to ACL2 reviewers**: The proof chains through `all-nonqualifying-implies-not-qualifying-list` (a helper proved by induction showing that all-nonqualifying lists fail `qualifying-document-listp`) to the main conclusion. This demonstrates ACL2 reasoning over recursive list structures with legal significance.

**Dependencies**: `all-nonqualifying-documentsp` (defun), `qualifying-document-typep` (defun), `qualifying-document-listp` (defun), `has-qualifying-docs-from-listp` (defun).

**Trusted assumptions**: None. This theorem depends only on executable definitions.

**Reviewer command**:
```bash
docker compose run --rm acl2 acl2 < federal_save_act_document_proofs.lisp
```

---

## 4. `conflict-condition-pivots-on-valid-regulation`

**File**: `federal_save_act_model_consistency.lisp`

**ACL2 feature demonstrated**: Biconditional (iff) rewriting with definitional expansion.

**Plain-English statement**: Given all other preconditions (qualified voter, protected right, registration transaction, statutory denial), the constitutional conflict condition is logically equivalent to `(not (valid-regulationp law x))`.

**Why it matters legally**: This theorem identifies the exact structural pivot of the constitutional analysis. The entire legal dispute reduces to a single predicate. Neither statutory text, process model, document lists, nor burden derivation determines its value — only the interpretive/doctrinal inputs do. This is the formal basis for the "interpretive hinge" architecture.

**Why it matters to ACL2 reviewers**: This is a pure structural theorem with no axioms in its dependency chain. It demonstrates definitional expansion of three nested `defun` predicates (`constitutional-conflict-conditionp`, `qualified-federal-voterp`, `registration-transactionp`) into a single biconditional. The `:in-theory (enable ...)` hint shows controlled theory management.

**Dependencies**: `constitutional-conflict-conditionp` (defun), `qualified-federal-voterp` (defun), `registration-transactionp` (defun).

**Trusted assumptions**: None. This is the strongest class of ACL2 proof — depends only on executable definitions.

**Reviewer command**:
```bash
docker compose run --rm acl2 acl2 < federal_save_act_model_consistency.lisp
```

---

## 5. `terminal-state-remains-terminal-under-run-trace`

**File**: `federal_save_act_deep_process_invariants.lisp`

**ACL2 feature demonstrated**: Induction over event traces with case analysis on terminal states.

**Plain-English statement**: If a registration state is terminal (`:registered` or `:denied`), running any further trace of events leaves it unchanged.

**Why it matters legally**: Once a registration decision is made, subsequent administrative events do not retroactively alter the legal status. This is a formal model of administrative finality — a basic requirement of procedural due process.

**Why it matters to ACL2 reviewers**: The proof uses the `:cases` hint to split on the two terminal states, then relies on `reg-terminal-statep` and the structure of `reg-run-trace` to show that the recursive trace executor returns immediately when starting from a terminal state. This demonstrates ACL2's case-splitting mechanism combined with recursive function reasoning.

**Dependencies**: `reg-run-trace` (defun), `reg-terminal-statep` (defun), `reg-next-state` (defun).

**Trusted assumptions**: None. This theorem depends only on executable definitions.

**Reviewer command**:
```bash
docker compose run --rm acl2 acl2 < federal_save_act_deep_process_invariants.lisp
```

---

## Summary

| # | Theorem | Technique | Axioms Used |
|---|---|---|---|
| 1 | `registered-implies-prior-acceptance-path` | Trace induction | 0 |
| 2 | `denied-implies-prior-denial-path` | Trace induction | 0 |
| 3 | `all-nonqualifying-implies-no-documentary-proof` | List induction | 0 |
| 4 | `conflict-condition-pivots-on-valid-regulation` | Biconditional rewriting | 0 |
| 5 | `terminal-state-remains-terminal-under-run-trace` | Case split + trace induction | 0 |

All five theorems depend on **zero axioms** — they are proved entirely from executable definitions. This is the strongest class of ACL2 proof work in the project.
