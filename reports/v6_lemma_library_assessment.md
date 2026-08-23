# v6.0 Lemma-Library Assessment

## Summary

v6.0 changes *how* the Federal SAVE Act books are proved, not *what* they conclude. The challenger and government conclusions, the hinge analysis, the burden chain and the doctrine chains are unchanged. What changed:

1. **Shared invariants were extracted into two generic, statute-independent lemma libraries** (`model/lib/lsm.lisp`, `model/lib/enum_list.lisp`). Every induction and every case analysis in the project now lives there, proved once, hint-free. The statute books *instantiate* them.
2. **Hard-to-verify code was replaced by provable data.** The registration state machine is a 13-row edge table instead of a 13-clause `cond`; the § 3(b) document categories are three `defconst` lists instead of seven hand-written predicates. Invariants are discharged by *evaluating* the tables.
3. **Statutory prose now compiles to math.** A deterministic clause IR (`data/parsed/federal_save_act_document_rules.json`) is compiled to the ACL2 book `federal_save_act_document_rules.lisp` and to a controlled-English paraphrase by one script; CI fails if the committed book drifts from the IR.
4. **A faithfulness bug was found and fixed** as a direct consequence of (3): since v3 the model treated a birth certificate or naturalization certificate *alone* as documentary proof. § 3(b)(5) counts them only when presented together with a government photo ID.
5. **The trusted base shrank** from 33 to 27 `defaxiom`s by stating the six conceded scenario facts once.

| | v5.3.2 | v6.0.0 |
|---|---|---|
| Theorems (Q.E.D.) | 126 | **204** (43 in `lib/`) |
| Books | 17 | **25** (12 clean) |
| defaxioms | 33 | **27** |
| `:induct` / `:cases` / cond-enable hints in statute process books | 13 | **0** |
| Inductive proofs in statute books | ~8 | **0** |
| Statute-specific `:use` instantiations of library lemmas | 0 | 15 |
| Generated books | 0 | 4 (`--check`ed in CI) |
| § 8(k) removal process modeled | no | yes (11 theorems, lsm client) |

---

## 1. Where the proof lines actually lived

Reading the v5 books confirmed the hypothesis that most proof effort was duplicated helper work rather than legal content:

- `register-requires-register-event`, `denied-requires-deny-event`, `register-requires-acceptance-state`, `denied-requires-denial-state`, `unsubmitted-requires-submit-to-leave`, `no-single-step-*` — **five case-splits over the same 13-clause `cond`**, each with `:in-theory (enable reg-next-state)`.
- `registered-implies-path-contains-register-event`, `denied-implies-path-contains-deny-event`, `registered-implies-prior-acceptance-path`, `denied-implies-prior-denial-path`, `no-registration-without-submission` — **five inductions over `reg-run-trace`**, structurally identical, differing only in the target state and the "predecessor" set.
- `trace-passed-through-acceptance-statep` and `trace-passed-through-denial-statep` — the same recursive function with a different hard-coded state list.
- `qualifying-document-listp`, `all-nonqualifying-documentsp`, `filter-qualifying-documents` plus their append/remove/member lemmas — the standard all/none/some/filter algebra over one membership predicate.
- "Valid regulation defeats conflict" — stated and proved in **five** books (`consistency_check`, `model_consistency`, `independence`, `doctrine_proofs`, `government_model`); the pivot `iff` in three.
- Six citizen-a scenario axioms and two lemmas — stated in **both** party models.

## 2. The libraries

### `lib/lsm.lisp` — labeled state machine (22 theorems)

A process is `edges` = list of `(from event to)`. `lsm-step` looks up the first match or stays put; `lsm-run` folds a trace. The legal questions become *table queries*:

| Query | Meaning | Used for |
|---|---|---|
| `lsm-sources-into T` | states that can enter target set T | "registration requires a prior acceptance state" |
| `lsm-events-into T` | events that can enter T | "registration requires the register event" |
| `lsm-events-from s` | events that can leave s | "nothing happens without submission" |
| `lsm-has-outgoing s` | s has any exit | terminal states are absorbing |
| `lsm-closedp S` | S closed under the table | the process never leaves its state space |
| `lsm-wf-tablep` | alphabets respected | well-formedness, by evaluation |

Generic theorems: `lsm-run-entry-guard`, `lsm-run-event-guard`, `lsm-run-exit-guard`, `lsm-step-no-skip`, `lsm-run-closed`, `lsm-run-absorbing`, `lsm-run-append`, plus step-level and lookup-level versions. The book is **layered**: lookup facts are proved with the accessors open; then accessors and `lsm-lookup` are disabled and step facts proved from lookup facts; then `lsm-step` is disabled and run facts proved from step facts. This is what made every lemma hint-free and is the reason client books never see a case split.

### `lib/enum_list.lisp` — enumerated categories (21 theorems)

`all-in-catsp` / `some-in-catsp` / `none-in-catsp` / `filter-in-cats` over an arbitrary category list. Append algebra, duality (`some ⇔ ¬none`), membership, removal, filtering, and the **widening lemmas** (`some-in-catsp-widen`, `none-in-catsp-narrow`): if an amendment adds categories, everything that qualified still qualifies. That last family is the reusable "statutory amendment" invariant; `document_proofs` instantiates it as `widening-standalone-list-preserves-proof`.

### What instantiation looks like

```lisp
(defthm registered-implies-prior-acceptance-path
  (implies (and (not (equal start *state-registered*))
                (equal (reg-run-trace start events) *state-registered*))
           (trace-passed-through-acceptance-statep start events))
  :hints (("Goal" :use ((:instance lsm-run-entry-guard
                                   (targets (list *state-registered*))
                                   (s start) (edges *reg-edges*))))))
```

`*reg-acceptance-states*` is *defined* as `(lsm-sources-into (list *state-registered*) *reg-edges*)`, so the library conclusion matches the statute predicate syntactically; ACL2 evaluates the table and is done. The model was never told that `doc-accepted` and `alt-approved` are the acceptance states — a documentation theorem (`reg-acceptance-states-are-doc-accepted-and-alt-approved`) *reports* that the table implies it.

## 3. Refactor instead of grind: two cases

- **`lsm-run-closed` failed** on first attempt. The cause was not a missing lemma but theory control: `lsm-edge-to` was still enabled when the run-level theorem was tried, so the rewriter opened it to `caddr` and the lookup lemma stopped matching. The fix was layering the book (disable accessors/lookup/step between levels), not a hint.
- **`lsm-run-exit-guard` failed** because the rewriter needed the *contrapositive* of `lsm-step-exit-guard` oriented as a rewrite (`e ∉ events-from s ⇒ step is identity`). One extra step-level lemma (`lsm-step-noop-when-not-outgoing-event`) and the run-level theorem went through with no hint.

In both cases the repair was a change to the library's shape; no client proof needed attention.

## 4. Prose → IR → math

`tools/clause_ir_schema.json` defines a small IR: **categories** (an enumerated definition: name, source, members with symbol/source/text) and **rules** (name, args, a boolean tree over `and`/`or`/`not`/`some-in`/`all-in`/`none-in`/`member`/`pred`). `tools/clauses_to_acl2.py`:

- emits `model/<book>.lisp` with one `defconst` per category and one `defun` per rule, carrying each member's statutory citation and quoted text as comments;
- rejects unbound variables, unknown categories, duplicate symbols, and a symbol appearing in two categories (a symbol must mean one thing);
- is byte-reproducible (`--check` diffs the committed book against the IR; wired into `validate-traces` in CI and into `scripts/certify_books.sh`);
- emits `docs/generated/<book>.md`, an English paraphrase from the *same* tree, so the sentence a lawyer reads and the term ACL2 proves about cannot diverge.

The same tree also renders to **Attempto Controlled English** (`--ace`): the body is put into disjunctive normal form over statutory members and each disjunct becomes one `If a person has a n:X [and the person has a n:Y] then the person has a n:documentary-proof-of-citizenship.` sentence, upserted into `federal_save_act_ace.json` and APE-validated in strict mode. Because every member yields its own sentence, the ACE text cannot cover fewer statutory items than the ACL2 table — which is precisely what had happened: the hand-written `ace-005` listed 3 of the 6 § 3(b)(5) documents, and (more importantly) had the pairing rule *right* while the lisp had it wrong, with nothing comparing them.

**Process tables and axioms are in the IR too.** `federal_save_act_process_table.json` generates the registration states, events and `*reg-edges*` (each edge with a § citation and a TEXT_FACT / MODEL_STRUCTURE label), a Markdown edge table, and a 13-sentence ACE statement; the compiler rejects undeclared states/events and duplicate `(state, event)` pairs — a duplicate would make `lsm-step` silently nondeterministic, which the old `cond` could also have hidden. `federal_save_act_text_rules.json` generates the `defaxiom` for the documentary-proof prohibition and its ACE, via an `atoms` section that gives every predicate an ACE phrase (`ace`, `ace_neg`, constant renderings) so that `If p is a person and … and p does not present a documentary proof … then the SAVE Act denies a registration of p …` is produced from the same hypothesis tree that ACL2 sees.

This is deliberately narrower than the existing ACE pipeline: ACE validates that prose is parseable; the IR makes a specific class of statutory clause — "X means any of the following … but only if presented together with …" — *deterministically* executable. The two complement each other.

## 5. The § 3(b)(5) faithfulness bug

Writing the IR forced a reading of § 3(b) as structure rather than as a flat list, which surfaced the error immediately:

> "(5) A valid government-issued photo identification card … **but only if presented together with** one or more of the following: (A) A certified birth certificate … (E) A Naturalization Certificate …"

v3 had "fixed" a v2 omission by adding `has-certified-birth-certificatep` and `has-naturalization-certificatep` as standalone disjuncts of `has-any-qualifying-documentp`, and v5 proved `birth-cert-is-qualifying` and `nat-cert-is-qualifying` over document lists. Both are false under the statute. The scenario narrative ("lacks a REAL ID, passport, birth certificate") was unaffected, but any future scenario about a citizen with a birth certificate and no photo ID would have been modeled wrongly — in the government's favour.

v6 models the pairing: `documentary-proof-bundlep` = some standalone document, or (some anchor photo ID and some supporting document). Theorems now state `birth-cert-alone-is-not-qualifying`, `birth-cert-with-photo-id-is-qualifying`, `singleton-supporting-list-has-no-proof`, `anchor-and-supporting-pair-has-proof`, and `pairing-two-insufficient-bundles-can-create-proof`. Core's person-level predicate mirrors it: `has-govt-photo-id-with-supporting-docp` is now a `defun` over `has-govt-photo-idp` and six supporting-document stubs (§ 3(b)(5)(A)–(F), all six now present; v5 had two).

## 5a. § 8(k) as a second `lsm` client

`federal_save_act_removal_table.json` holds the two edges § 8(k) names (receive verified noncitizen information; remove "at any time") and five DUE_PROCESS_OVERLAY edges (notify, contest, confirm citizenship) that the statute does not contain. `federal_save_act_removal_invariants.lisp` is 11 theorems, every one a `lib/lsm` instance: `removal-implies-prior-information-receipt` (exit guard), `removal-requires-remove-event` (event guard), `statutory-path-has-no-notice-or-hearing` and `text-edges-alone-reach-removal` (evaluation), `removed-is-absorbing` (no statutory reinstatement), `reinstatement-requires-contest-path` (only through the overlay). The due-process argument now has a precise mechanical target; the book takes no position on its merits. Writing it took a table and six `:use` lines — which is the point of the library.

## 5c. Removal → conflict bridge (v6.1)

Removal acts on a registrant, not an application, so it gets its own conflict condition rather than being forced through `statute-denies-registrationp`. Doing this exposed an over-quantification in both v5 party models: the challenger's undue-burden rule concluded `(not (valid-regulationp law x))` and the government's six-factor defense concluded `(valid-regulationp law x)` for **every** x — so whichever party's registration theory was loaded would have decided the removal question for free. Both bridges are now conditioned on `(voter-registration-applicationp x)`; every registration theorem still certifies. The removal branches are new encapsulates with their own traced sources (Mathews v. Eldridge; Husted) and a second shared scenario, `citizen-b`.

## 5b. Explorer

The curated graph gained the library layer, the clause-IR node, the § 8(k) model and its neutral conclusion, and a "Due-Process Overlay (not in statute)" toggle that is *off* by default — so the first thing a visitor sees is the statute alone, with removal reachable and no reinstatement path; switching the overlay on lights the reinstatement lemma. While wiring this up I found that the published demo has shown every conclusion card as "Unsupported" since v5.3 (an init-ordering bug — statuses were computed before assumptions were seeded). Fixed in `web/app.js`.

## 6. What did not change

- No conclusion changed: `challenger-model-finds-conflict` and `government-model-no-conflict` certify with the same statements.
- Every v5 theorem name referenced by the explorer graph still exists with the same statement.
- No `defaxiom` was added; six duplicates were removed.
- The hinge, burden, doctrine, existential, independence and model-consistency books are untouched except for the removal of nothing — they still compile; their restated pivot lemmas are now corollaries of `core-conflict-pivots-on-valid-regulation`.

## 7. Recommended next steps

1. **Generate the remaining hand-written ACE** (`ace-008` exception, `ace-010/011` penalties, `ace-012` provisional ballots) — these have no ACL2 counterpart yet; adding them to the IR would also add their predicates to the model.
2. **Connect the removal process to the conflict condition** (a removed citizen is a denied voter): a bridge from `*rem-removed*` to `statute-denies-registrationp`-style predicates, so the § 8(k) book feeds the doctrine chain. `*reg-edges*` is still hand-written in ACL2. A `process` section in the clause IR (states, events, edges with § citations for each edge) would close the loop: the state machine, its English description, and the explorer's process diagram would all derive from one file.
4. **Functional instantiation.** The libraries make it cheap to exhibit concrete witnesses for the encapsulates via `:functional-instance`, the open item from v5.3.
5. **Retire the restated pivot theorems** in `independence`, `model_consistency`, `consistency_check` in favour of the core versions once the explorer graph is repointed, to keep the inventory honest.
6. **Second scenario** (naturalized citizen with certificate but no photo ID) — now that § 3(b)(5) is modeled correctly, this scenario is both legally interesting and mechanically cheap.

## 8. Legislative currency (v6.2) and scope for the SAVE America Act

The repo was frozen at H.R. 22 EH (Apr. 2025). The live vehicle is the SAVE America Act as the House amendment to S. 1383 (Feb. 11, 2026), stalled in the Senate. v6.2 tracks that text, checks in CI that every clause the model quotes is verbatim in both texts (it is; only the short title differs), and records the Senate/EO status in `data/legislative_status.json`.

Three things in the new text are **not modeled**, in rough order of value:

1. **§ 3 — photo identification to vote (new HAVA § 303A).** A *voting*-stage burden, distinct from the registration-stage documentary-proof burden. Model: a third `lsm` table (`vote` process: arrives-at-polls → id-presented / no-id → ballot-cast / provisional-cast → counted / rejected), a generated category table for "valid photo identification" (state DL, state non-driver ID, passport, military ID, tribal ID — all requiring photograph + expiration date), and a Crawford chain: the government's burden-not-severe premise now has to cover two requirements. The challenger's interesting theorem is structural: a citizen with documentary proof of citizenship (registered) but no *expiring* photo ID is registered yet cannot cast a counted regular ballot — two enumerations, two gaps. ~3 IR files, ~25 theorems, reuses `lib/lsm` + `lib/enum_list` unchanged.
2. **Name-discrepancy process** (registration). One new edge pair in the registration table (`doc-presented --name-discrepancy--> discrepancy-review --resolve--> doc-accepted`) and a narrower scenario (married citizen whose birth certificate and ID differ). Cheap; it also narrows `citizen-a`'s structural denial: the v5 "structurally mandated denial" theorem must now carve out the discrepancy path.
3. **30-day DHS/SAVE list submission + quarterly matching.** Feeds the § 8(k) removal table: a new TEXT_FACT edge `on-rolls --save-match--> info-received` makes "verified information" *systematic* rather than incidental, which strengthens the challenger's erroneous-removal scenario (scenario B) and is the natural hook for an error-rate empirical assumption.

None of these changes § 2, so the existing 216 theorems would stay valid against the new vehicle; they would be *additions*.

## 9. § 303A photo identification to vote (v6.5) and functional instantiation

The § 3 layer reused the libraries unchanged except for one new generic lemma, `lsm-run-closed-except` ("a set is left only through a gate event"), needed to state that a provisional ballot is counted *only if* a cure event occurred. Everything else was tables and instantiation: three IR files verbatim-checked against the S. 1383 text, a 16-theorem neutral book, scenario C, and one encapsulate per party.

The structurally interesting results are the **two-enumerations** theorems. § 3(b) (registration) and § 303A(c) (voting) are different lists; the model proves a passport satisfies both, that the § 3(b)(5) photo-ID-plus-birth-certificate pairing registers a citizen yet is not valid photo identification at the polls, and that a driver's licence is valid at the polls yet is not proof of citizenship at registration. Whether the gap between the lists burdens anyone is, as always, a premise — `challenger-scenario-c-material-burden`, tagged fact-finder.

`federal_save_act_functional_instantiation.lisp` closes the v5.3 open item: for each party an abstract encapsulated predicate, a generic theorem with the bridge stated as a *hypothesis*, a concrete conjunction of that party's factors, and a `:functional-instance` transfer in which ACL2 proves the concrete predicate satisfies the exported constraint. The book is neutral (no `defaxiom`), which is the point: it shows the encapsulates admit non-trivial models without importing either party's axioms.

Remaining unmodeled SAVE America Act material: the name-discrepancy registration process and the 30-day DHS/SAVE list submission.
