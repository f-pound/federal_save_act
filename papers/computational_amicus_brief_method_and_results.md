# The Computational Amicus Brief: Machine-Checked Conditional Legal Argument, with the Federal SAVE Act as a Worked Example

*Version 7.3 · August 2026 · Repository: https://github.com/f-pound/federal_save_act · Live demo: https://f-pound.github.io/federal_save_act/*

## Abstract

A *computational amicus brief* is a legal argument whose every inference has been checked by a theorem prover and whose every premise is stated explicitly, traced to a public legal source, and tagged with who decides it. This paper describes a method and a working system, and reports its application to the Federal SAVE Act (H.R. 22, 119th Congress; now the SAVE America Act, S. 1383 as amended by the House) and, as a portability test, to a section of a second bill (H.R. 7300 § 113). The system formalizes statutory text in ACL2 through a deterministic intermediate representation from which the ACL2 definitions, an Attempto Controlled English paraphrase and an interactive explorer are all generated; models each party's legal theory as an encapsulated ACL2 theory with traced axioms; proves each party's conditional conclusion; and subjects the premises to three mechanical audits — certification, a *consistency audit* (every axiom proved satisfiable in a concrete model) and an *adversarial audit* (every axiom denied in turn to find which premises are load-bearing). The SAVE Act development comprises 32 certified books, 594 theorems and 66 traced axioms, every quoted clause — statutory and judicial — verified verbatim against the fetched source text. Its findings include a statutory-faithfulness error in the earlier model (a birth certificate alone was treated as proof of citizenship; the statute requires a photo ID with it), two over-quantified bridge rules that would have let either party's registration theory decide an unrelated removal question, the mechanical rediscovery — by the adversarial audit, without annotation — of the project's central interpretive hinge as the only coupled premise in each party's theory, and, once quotes were checked against opinion text, the discovery that the model's most-cited line from *Crawford* was not in the opinion. We argue that the value of the approach lies not in deciding constitutional questions, which it does not do, but in making the structure of disagreement exact: which premises are shared, which are disputed, who decides each, and what follows from any chosen set.

---

## 1. Introduction

Legal argument is conditional. An advocate says: *if* the statute means X, *if* these facts obtain, and *if* the governing doctrine is Y, *then* the challenged provision is (or is not) valid. The conditional part — the *then* — is logic, and logic can be checked by machine. The antecedents — the *ifs* — are choices made by legislatures, courts, fact-finders, and the parties themselves. Most disagreement in a real case is about the *ifs*; most error in written argument, however, is in the *then*: an inference that does not follow, a condition silently dropped, a rule applied beyond its domain.

The computational amicus brief separates the two. Everything that is logic is proved by a theorem prover. Everything that is a choice is stated as an axiom, traced to its source, and tagged with its decider. A reader — lawyer, judge, scholar, citizen — then sees exactly where the argument could go the other way, and can try it.

This paper reports a complete instance of the method: a formalization of the documentary-proof-of-citizenship requirement, the alternative attestation process, the removal rule and the photo-ID-to-vote requirement of the SAVE Act / SAVE America Act, with competing challenger and government theories, an interactive explorer, and a set of audits that treat the premises themselves as objects of verification. It is written for two audiences at once. Legal readers will find the method, the modeling decisions and the findings in §§ 2–4 and 7; formal-methods readers will find the architecture, the proof engineering and the audits in §§ 5–6 and the appendices.

### 1.1 What the system proves, and what it does not

The system proves theorems of the form *premises ⊢ conclusion* in ACL2's first-order logic. It does **not** prove that the SAVE Act is constitutional or unconstitutional; it does not decide which reading of a statutory phrase a court will adopt; it does not decide empirical questions such as how many citizens lack documents or what obtaining them costs. Those are the premises. What it does establish — and this is the claim of the paper — is the exact structure of the argument: the set of premises each side needs, the single premise on which the sides' conclusions pivot, which premises are independent and which must move together, and which conclusions follow from structure alone with no legal premise at all.

### 1.2 Contributions

1. An architecture for conditional legal argument in a theorem prover: a neutral core vocabulary, text-derived facts, party-stipulated scenarios, *hinge* books for competing readings of a pivotal phrase, and party theories as encapsulated ACL2 theories with traced bridge rules (§ 5).
2. A deterministic **clause intermediate representation** (IR) for enumerated statutory definitions, rules and process tables, compiled to ACL2, to APE-validated Attempto Controlled English and to a Markdown paraphrase from one source, with a CI check that every quoted clause is verbatim in the bill text (§ 5.2).
3. Two **statute-independent lemma libraries** — a labeled-state-machine library and an enumerated-category library — such that every process and document invariant in the statute books is an instance discharged by evaluating a data table, with no statute-specific induction (§ 5.3).
4. **Decider tagging** of every axiom (legislature / court / fact-finder / party stipulation), enforced by CI, with a neutrality lint guaranteeing the logic layer contains no legal choice (§ 5.4).
5. Three **audits of the trusted base**: a consistency audit proving each party's axioms satisfiable in a concrete model; an adversarial audit classifying each axiom as independent, coupled or redundant; and a per-book trusted-base report (§ 6).
6. A **pipeline and agent harness** that drive the method from a one-line issue description, with the audits as oracles, tested on a second statute (§ 8).

---

## 2. The legal setting

The SAVE Act amends the National Voter Registration Act of 1993 to require *documentary proof of United States citizenship* for registration in federal elections. Four provisions carry the constitutional weight:

- **§ 3(b) (definition).** Documentary proof means any of: a REAL ID that *indicates citizenship*; a U.S. passport; a military ID with a service record showing U.S. birth; a government photo ID showing U.S. birthplace; or — paragraph (5) — a government photo ID *presented together with* one of six supporting documents (certified birth certificate, hospital birth record, adoption decree, consular report of birth abroad, naturalization certificate, American Indian Card).
- **§ 4(b) / § 8(j)(1) (prohibition).** A State shall not accept and process an application without such proof; a State may not register an individual who does not provide it.
- **§ 8(j)(2)(A) (alternative process).** An applicant who cannot provide proof may sign an attestation under penalty of perjury and submit other evidence, and the official "shall make a determination as to whether the applicant has sufficiently established United States citizenship."
- **§ 8(k) (removal).** A State shall remove a registrant "at any time upon receipt of documentation or verified information that a registrant is not a United States citizen."

The SAVE America Act (S. 1383 as passed by the House, Feb. 11, 2026) keeps § 2 verbatim (the system checks this mechanically, § 5.2) and adds § 3, a photo-identification-to-vote requirement (new HAVA § 303A) with a three-day provisional-ballot cure, a name-discrepancy registration process, and a DHS/SAVE list-matching mandate under which SAVE-identified registrants are removed "after notice is given." As of August 2026 neither bill is law; the Senate failed cloture 53–47 on March 26, 2026.

The doctrinal frame is *Anderson–Burdick* balancing as applied in *Crawford v. Marion County* (photo ID upheld), the due-process line of *Mathews v. Eldridge* for removals, *Husted v. A. Philip Randolph Institute* for list maintenance, and the fundamental-right cases *Harper* and *Reynolds*.

---

## 3. The method, for legal readers

### 3.1 Premises are choices; the tag says whose

Every axiom in the system carries a **decider** tag:

| Decider | Meaning | Count (SAVE Act) |
|---|---|---|
| legislature | statutory text, quoted verbatim | 5 |
| court | doctrine, or the interpretation of a statutory phrase | 20 |
| fact-finder | an empirical finding | 4 |
| party stipulation | a fact both sides concede, or a concession *arguendo* | 31 |

The tags are not commentary; CI refuses an axiom without one, and refuses any axiom at all in the books that constitute the logic layer (§ 5.4). When the explorer shows a premise, it shows who decides it; when a theorem is shown, it says "nobody — proved from definitions."

### 3.2 Two parties, one pivot

The challenger's theory and the government's theory are separate ACL2 books that are never loaded together. Each introduces its interpretive rules as an *encapsulate* — a block whose local witness proves the rules jointly consistent — and connects them to the neutral vocabulary by *bridge* axioms. The challenger's conclusion is a constitutional-conflict condition; the government's is its negation. Both certify.

What makes the two conclusions compatible with one consistent system is the *pivot*: the core book proves that, with every other precondition fixed, the conflict condition is logically equivalent to "the regulation is not valid as applied" (`core-conflict-pivots-on-valid-regulation`). The parties differ on exactly that predicate, and the system shows why: the challenger's bridge makes it false through an undue-burden rule; the government's makes it true through a six-factor *Crawford* defense. Everything else they share.

### 3.3 The hinge

The phrase "shall make a determination as to whether the applicant has sufficiently established United States citizenship" is read two ways. Reading A: if the evidence satisfies the standards, the official *must* approve. Reading B: the official *decides*, and may deny. The system keeps both as separate *hinge* books. Under A the denial trigger cannot fire for an applicant who attests and submits evidence; under B it can. Which reading a court adopts is a `court` premise. § 6.3 reports that the adversarial audit finds this hinge, without being told where to look, as the only coupled premise in each party's theory.

### 3.4 Three scenarios

The parties argue over named individuals with stipulated facts, shared by both sides:

- **citizen-a** — a citizen born at home in a rural area who holds no § 3(b) document and applies by mail (registration).
- **citizen-b** — a registered citizen erroneously matched by a database to "verified information" of noncitizenship and removed with no notice (removal, § 8(k)).
- **citizen-c / citizen-d** — registered citizens at the polls without valid photo identification; c does not cure within three days, d does (voting, § 303A).

For each, the challenger proves a conflict and the government proves none — except citizen-d, for whom the system proves, with no party premise at all, that a cured ballot is never a conflict.

### 3.5 What the reader does with it

The explorer lets a reader pick a point of view (a preset that switches on one party's premises), untick any single premise, and watch the conclusions' status change; it lists the dispute as common ground versus what each side needs; it shows, for any box, its source, its ACL2 name, who decides it and whether it is load-bearing; and it exports the current configuration as a memo with a link that reproduces it.

---

## 4. Findings

### 4.1 A statutory-faithfulness error (§ 3(b)(5))

Versions 3–5 of the model treated a certified birth certificate or a naturalization certificate, *alone*, as documentary proof. The statute counts them only "if presented together with" a government photo ID. The error was introduced as a "fix" (adding two omitted stubs as standalone disjuncts) and survived three releases and a published theorem (`birth-cert-is-qualifying`). It was found when the definition was rewritten as structured data: writing § 3(b) as an enumeration with a paired clause forces the question the flat list hid. The corrected model proves `birth-cert-alone-is-not-qualifying` and `birth-cert-with-photo-id-is-qualifying`. Notably, the project's Attempto Controlled English statement of § 3(b)(5) had encoded the pairing correctly since version 5.3; the ACE and the ACL2 disagreed for three versions and nothing compared them — the reason the IR now generates both from one source.

### 4.2 Over-quantified bridges

Both parties' registration bridges concluded about `valid-regulationp` for *every* object x: the challenger's undue-burden rule made every regulation invalid, the government's six-factor defense made every regulation valid. Neither error was visible while the model contained only the registration question. Adding removal (§ 8(k)) exposed them: either party's *registration* theory would have decided the *removal* question for free. Both bridges are now conditioned on `voter-registration-applicationp x`; every registration theorem still certifies. This is the class of defect — a missing domain condition — that the Vero benchmark reports as the largest category of latent error in curated formal specifications [Ye et al. 2026].

### 4.3 Removal without notice, and a difference between the two vehicles

Over a 7-state table generated from the text, the system proves that the § 8(k) path — receipt of verified information, removal — contains no notice or hearing event, that `removed` is absorbing, and that no statutory route returns a registrant to the rolls (`statutory-path-has-no-notice-or-hearing`, `removed-is-absorbing`). The model takes no position on whether this is unconstitutional; it gives a due-process argument an exact target. When the SAVE America Act text was tracked (v6.2), its § 8(j)(4)(B) — SAVE-list matching with removal "after notice is given" — was added as edges with their own source and quote. The system then proves *both* that the systematic path requires the notify event (`save-match-removal-requires-notice`) *and* that the § 8(k) "at any time" path survives unchanged. Three documentation theorems that enumerated the derived state sets failed until updated — the library refusing a stale description of a changed table.

### 4.4 Two enumerations (§ 3(b) vs § 303A(c))

Registration proof and voting identification are different lists. The system proves a passport satisfies both; that the § 3(b)(5) photo-ID-plus-birth-certificate pairing registers a citizen but is not valid photo identification at the polls; and that a driver's licence gets a ballot but is not proof of citizenship. Whether the gap burdens anyone is a `fact-finder` premise.

### 4.5 The hinge, rediscovered

§ 6.3 below: denying each of the 94 party axioms in turn, the only premise in each theory that cannot be denied without falsifying another is the scenario's alternative-process fact, which is locked to the hinge reading. No axiom is provable from the others.

### 4.6 A quotation that was not in the opinion

When judicial quotes were put under the same verbatim check as statutory ones (v7.3, against opinion text fetched from the Caselaw Access Project), 19 of the trace file's court-sourced "quotes" failed. Most were paraphrases; one was worse. The model's most-cited authority for the challenger's burden premise — *Crawford*, "the burden of obtaining a birth certificate … will be nontrivial for some voters" — does not appear in the plurality opinion. "Nontrivial burdens" is Justice Souter's *dissent*. The plurality's actual words are narrower and more interesting: "a somewhat heavier burden may be placed on a limited number of persons … elderly persons born out of State, who may have difficulty obtaining a birth certificate; persons who because of economic or other personal limitations may find it difficult either to secure a copy of their birth certificate or to assemble the other required documentation." The axiom's *content* was defensible; its *citation* was not. The trace now carries the plurality's words.

### 4.7 Overdetermination at the pivot

Adding the poll-tax argument (Amend. XXIV; *Harper*: "whenever it makes the affluence of the voter or payment of any fee an electoral standard") as a second challenger route produced a new coupling in the adversarial audit: the poll-tax bridge and the undue-burden bridge both conclude "not valid as to the application," so neither can be denied alone. This is not an inconsistency; it is the audit reporting that the challenger's registration case is *overdetermined* — two independent legal theories reach the same pivot — and that the government must defeat both (it does so with one premise: free identification is available, *Crawford*).

### 4.8 A second statute (H.R. 7300 § 113)

Run through the pipeline on a text the project had never modeled, the system proved that the MEGA Act's removal section removes on DHS SAVE data "at any time" — exempt from its own 15-day pre-election freeze — while its notice-card procedure applies to residence removals only (`save-path-removes-without-notice`, `residence-removal-requires-return-card`): the same structural gap as § 8(k), in different words, found by the same tools (§ 8).

---

## 5. Architecture, for formal-methods readers

### 5.1 Books

| Layer | Books | Axioms | Role |
|---|---|---|---|
| Libraries | `lib/enum_list`, `lib/lsm` | 0 | statute-independent lemma libraries (46 theorems) |
| Core | `core` | 0 | `defstub` vocabulary; factored conflict conditions (registration, removal, voting); pivot lemmas |
| Generated | `document_rules`, `process_table`, `removal_table`, `voting_id_rules`, `voting_table`, `text_rules`, `voting_text_rules` | 3 (text rules) | compiled from the clause IR |
| Facts / scenario | `facts`, `scenario` | 2 + 29 | verbatim text facts; party-stipulated facts for four named individuals |
| Hinges | `hinge_common`, `hinge_mandatory`, `hinge_discretionary` | 1 + 1 | competing readings of § 8(j)(2)(A) |
| Parties | `challenger_model`, `government_model` | 9 + 15 | encapsulated theories, bridges, conclusions |
| Invariants | `process`, `process_invariants`, `deep_process_invariants`, `document_proofs`, `removal_invariants`, `voting_invariants` | 0 | library instances over the generated tables |
| Derivations | `burden_proofs`, `doctrine_proofs`, `existentials`, `independence`, `model_consistency`, `consistency_check` | 0 own | burden chain, doctrine chains, `defun-sk` existentials, neutrality |
| Audits | `functional_instantiation`, `consistency_audit` (generated) | 0 | `:functional-instance` transfers; satisfiability of each party's trusted base |

Total: 32 books, 594 theorems, 66 `defaxiom`s, 11 `encapsulate`s, 4 `defun-sk`s. 18 books have an empty trusted base.

### 5.2 The clause IR

`tools/clause_ir_schema.json` defines a small JSON IR: **categories** (an enumerated definition: name, source, members with symbol, citation, verbatim `text` and an ACE noun); **rules** (a `defun` over `and`/`or`/`not`/`some-in`/`all-in`/`none-in`/`member`/`pred`, or a `kind: axiom` text rule with hypotheses and conclusion over **atoms** that carry ACE verb phrases); and **process** tables (states, events, edges, each edge with its citation and optionally its own `source_id` and quote). `tools/clauses_to_acl2.py` compiles an IR to (i) an ACL2 book — `defconst` per category, `defun` or `defaxiom` per rule, `defconst` edge table — rejecting unbound variables, unknown categories, duplicate symbols, a symbol in two categories, and duplicate `(state, event)` pairs (which would make the table nondeterministic); (ii) Attempto Controlled English, by putting the rule body in disjunctive normal form over members and emitting one `If … then …` sentence per disjunct, with first-mention/anaphora handling, validated in strict mode against the APE web service (13/13 pass); (iii) a Markdown paraphrase. CI fails if any generated artifact differs from its IR, and `check_text_stability.py` fails if any quoted `text` is not verbatim in the tracked bill text(s) — for the SAVE Act, in *both* H.R. 22 and S. 1383 (32/32; the only difference is the short title).

### 5.3 Lemma libraries and instantiation

`lib/lsm.lisp` models a legal process as a table of `(from event to)` edges with `lsm-step` (first match, else identity) and `lsm-run`. Table queries — `lsm-sources-into`, `lsm-events-into`, `lsm-events-from`, `lsm-has-outgoing`, `lsm-closedp`, `lsm-closedp-except`, `lsm-wf-tablep` — are executable. The library proves, once and hint-free, entry guards (reaching a target set from outside visits a source state), event guards, exit guards, no-skip, closed-set invariance, a gated-exit lemma (a set closed except via events E is left only by an event in E), absorbing states and trace composition. The book is layered: lookup facts with accessors enabled; then accessors and lookup disabled and step facts proved from lookup facts; then step disabled and run facts proved from step facts. This layering is what makes every client proof a one-line `:use` with the table evaluated by the executable counterparts.

`lib/enum_list.lisp` proves the algebra of `all-in-catsp` / `some-in-catsp` / `none-in-catsp` / `filter-in-cats` over an arbitrary category list: append, removal, duality, membership, filtering, and widening (if an amendment adds categories, everything that qualified still qualifies).

Effect on the statute books: the v5 registration machine was a 13-clause `cond` with five case-split helpers and five structurally identical inductions; v6 has a 13-row table, derived acceptance/denial sets (`(lsm-sources-into '(registered) *reg-edges*)`), and **zero** `:induct`/`:cases`/cond-enable hints in any statute book. Adding the § 303A process needed one new generic lemma (`lsm-run-closed-except`) and was otherwise tables and instantiation. This matches the Vero benchmark's finding that 72–74% of proof text in completed verified repositories lives in shared helper lemmas [Ye et al. 2026].

### 5.4 Enforced discipline

`validate_trace.py` checks, on every commit: every `defaxiom` has a trace row with a valid label, a source in the manifest and a decider; no `defaxiom` in a neutral book (libraries, core, generated tables, invariants, proofs, checks, audits — 22 books); no proof-trivialising construct (`skip-proofs`, `defttag`, `defattach`, `progn!`, `include-raw`, `sys-call`, `:skip-proofs-okp`, `set-ld-skip-proofsp`) anywhere in `model/`. `print_axioms.py` computes, per book, the `defaxiom`s in its include closure by decider — a sound upper bound on every theorem's trusted base, the ACL2 analogue of Lean's `#print axioms`.

### 5.5 Encapsulation and functional instantiation

Interpretive rules are introduced as `encapsulate`s with local witnesses, so their joint consistency is proved at admission. `functional_instantiation.lisp` shows the encapsulates admit non-trivial models: for each party, a generic theorem about the abstract predicate (with the bridge stated as a hypothesis) is transferred by `:functional-instance` to a concrete conjunction of that party's factors, ACL2 discharging the constraint obligation. The book is neutral.

---

## 6. Auditing the premises

`certify-book … :defaxioms-okp t` accepts an axiom set without checking that it is satisfiable. The project therefore audits the trusted base in three ways, all statute-independent and all run in CI. The design follows the formal audit mechanism of the Vero benchmark [Ye et al. 2026], which accepts machine-checked negative evidence (a specification is unsatisfiable; a set of specifications is jointly inconsistent; a reference implementation is wrong) and found that 45% of latent defects in curated specifications were missing domain conditions — precisely § 4.2 above.

### 6.1 Consistency audit (satisfiability)

`gen_consistency_audit.py` reads, for each party theory (core + facts + text rules + scenario + its hinge + its party book), every `defstub` and encapsulate signature, every core `defun`, every `defaxiom` and every encapsulate-exported constraint. From `data/audit_worlds.json` it generates a concrete *toy world* — every stub a membership test over the scenario constants — re-defines the core `defun`s over that world, and restates each axiom and constraint as a theorem. The generated book is neutral and certifies: challenger 44 axioms + 7 constraints, government 50 + 5 (107 theorems). Both trusted bases are satisfiable. A propositional theorem records that the two registration bridges cannot share a world. The audit caught nothing in the model and one error in the author's first toy world — which is the point of having the prover check the world.

### 6.2 Adversarial audit (independence, coupling, redundancy)

`adversarial_audit.py` takes each axiom A and constructs a *flipped world*: the base world with one stub value (or two at the same witness point) changed so that A is false, with the flip search descending into core `defun`s. It then evaluates every other axiom of the theory in the flipped world. Because the worlds are finite (membership over named constants plus one fresh symbol), evaluation over the universe is a complete finite-model check. Verdicts: **independent** (the flipped world is a model of T∖{A} ∧ ¬A); **coupled** (the flip falsifies the listed axioms — a load-bearing joint). With `--acl2` it also asserts T∖{A} in a fresh ACL2 session and attempts A as a theorem under a time limit: a success is a kernel-checked certificate of **redundancy**.

Since v7.3 the independence verdicts are themselves kernel-checked. The consistency-audit generator reads the adversarial audit's recorded flips and witnesses and emits a *flip-parameterised* world: every stub takes a `flip` argument naming the axiom being denied, and the one or two stub values the audit changed are overridden only when `flip` names that axiom. For each audited axiom A the book then proves two theorems — `aud-<party>-flip-A-falsifies` (A is false at its witness in the flipped world) and `aud-<party>-flip-A-preserves-rest` (the conjunction of every other proposition of the theory holds there; for a coupled A, the named coupled propositions are proved false instead). ACL2 certifies all 434 audit theorems in a few seconds; the evaluator is now a search procedure whose every verdict is checked by the kernel.

### 6.3 Results

| Theory | axioms | independent | coupled | redundant |
|---|---|---|---|---|
| Challenger | 47 | 45 | 2 | 0 |
| Government | 51 | 50 | 1 | 0 |

The hinge coupling on each side is `challenger-scenario-alternative-process-denied ⇄ semantic-b-discretionary-denial` and its government mirror `…-approved ⇄ semantic-a-mandatory-approval`: the scenario's alternative-process fact cannot be denied without contradicting the hinge reading. Early runs reported several more couplings; each traced to a toy world that was too broad (a predicate true for every p lets a flip at an unrelated constant trip another bridge), and each tightening was re-proved by the certified audit book before the verdict was accepted. The challenger's second coupling (v7.3) is the overdetermination of § 4.7: the poll-tax and undue-burden bridges share the pivot. On the second statute (§ 8), the audit likewise found exactly the government theory's hinge joint.

The interpretation for legal readers: the claim that the whole dispute turns on one reading of "shall make a determination" is not an editorial framing. It is a structural property of the two axiom sets, computed.

---

## 7. Limitations and threats to validity

Several limitations reported in earlier versions have been removed; the remainder are stated here with what mitigates them.

**Removed in v7.3.**
- *Independence verdicts were evaluator-checked.* They are now kernel-checked: every verdict of the adversarial audit has a certified ACL2 theorem behind it (§ 6.2).
- *Case-law quotes were traced but not verbatim-checked.* They now are, against opinion text fetched from the Caselaw Access Project, for 7 of the 10 cited cases; the check found and corrected 19 paraphrases including a mis-attributed dissent line (§ 4.6). The three cases the archive does not carry (*Reynolds v. Sims* volume page, *Husted*, and the 2025 district-court ruling) remain traced by citation only.
- *Burden was boolean.* The Anderson–Burdick standard of review is now an explicit decision table over ordinal burden levels (`burden_tiers`): which standard applies at which level is logic; the level assigned is a fact-finder premise.
- *The poll-tax and mail-ballot branches were unmodeled.* Both are now modeled (§ 4.7; `mail-ballot-identification-bundlep` and six theorems).

**Remaining.**
- **The weighing itself is a premise.** Within a tier, whether the state's interest meets the selected standard is still stated, not computed. Magnitudes (costs, error rates, counts) are not represented as numbers.
- **Finite scenarios.** Four named individuals; class-wide claims are `defun-sk` existentials or premises.
- **Worlds are authored.** The audit's toy worlds are hand-written. A too-broad world produces spurious couplings (observed and corrected); a too-narrow world could mask one. Mitigation: the consistency book must certify for every world used, and the flipped-world certificates are checked by ACL2, so a world cannot make a false verdict certify — it can only fail to find a true independence.
- **Legal completeness.** The Elections-Clause structural argument, § 8(j)(4)(C) "other data sources," and the UOCAVA / disability exceptions of § 303A(a)(2)(B) are not modeled.
- **The second-statute run was replayed.** Its four model-stage outputs were authored by a language model in an interactive session and replayed through the harness with every oracle live; a credentialed live run has not been performed.
- **Opinion-text coverage.** Verbatim checking of judicial quotes depends on an archive that stops before 2018 for the Supreme Court; recent cases need another source.

## 8. Pipeline and agent harness

`tools/amicus_pipeline.py` chains the method: `fetch` (govinfo bill text and BILLSTATUS votes, Federal Register executive orders, CourtListener opinions), `extract` (draft IR from statutory text — enumerated definitions, prohibitions and duties, every quote verbatim, flagged for review), `compile`, `certify`, `audit`, `hinges`; `init` scaffolds a new project from the statute-independent parts. `tools/amicus_agent.py` drives it from a one-line issue description as a draft → verify → repair loop in which the repository's own CI checks are the oracles (compiler, verbatim-quote check, APE strict, certification, trace validation, both audits), with structured JSON outputs per stage and a sign-off point at the conflict condition.

Applied to H.R. 7300 § 113, the loop behaved as designed: the IR stage went red (APE rejected three of four generated ACE statements) and green on repair; the core certified first time; the parties stage went red (two trace quotes were paraphrases) and green on repair. The resulting project has 14 certified books, 99 theorems, 20 decider-tagged axioms, both theories satisfiable, and an adversarial audit that finds the government theory's hinge joint. Its explorer is published alongside the SAVE Act's.

---

## 9. Related work

Formal approaches to law span rules-as-code (LegalRuleML; Catala), controlled natural languages (Attempto ACE), and theorem-prover formalizations (LogiKEy / Isabelle). Verified-software benchmarks such as Vero [Ye et al. 2026] motivate the audit design and the lemma-library discipline. The present work's distinguishing commitments are: proofs of *conditional* conclusions for *competing* theories in one certified development; generation of logic, controlled English and UI from one deterministic IR with verbatim-quote checking; decider tagging with enforced neutrality; and auditing the premises themselves for satisfiability, independence and redundancy.

## 10. Conclusion

A theorem prover cannot decide a constitutional case, and this system does not try. What it can do — and what the SAVE Act development shows at full scale — is make the *then* of a legal argument incontestable and the *if* exact: every premise stated, sourced and attributed to its decider; every inference checked; every premise tested for consistency, independence and redundancy; and the result explorable by anyone who can tick a box. The method found real errors in its own earlier model, qualified a headline claim when the statutory text changed, and rediscovered the case's central hinge from the axioms alone. It transfers to a new statute with the same tools.

---

## Appendix A. Reproducibility

```
git clone https://github.com/f-pound/federal_save_act && cd federal_save_act
brew install acl2            # or use the atwalter/acl2 Docker image via $ACL2_CMD
./scripts/certify_books.sh   # pre-checks + 32 books; expect "Certified: 32 … Q.E.D.: 594"
python tools/validate_trace.py
python tools/fetch_opinions.py && python tools/check_text_stability.py
python tools/adversarial_audit.py --acl2
python tools/serve_explorer.py
```

## Appendix B. Theorem inventory by book

| Book | Theorems | Axioms in closure |
|---|---|---|
| lib/enum_list | 21 | 0 |
| lib/lsm | 25 | 0 |
| core | 7 | 0 |
| process | 30 | 0 |
| process_invariants | 16 | 0 |
| deep_process_invariants | 11 | 0 |
| document_proofs | 20 | 0 |
| removal_invariants | 16 | 0 |
| voting_invariants | 22 | 0 |
| consistency_check | 17 | 0 |
| functional_instantiation | 6 | 0 |
| consistency_audit (generated) | 434 | 0 |
| burden_tiers | 7 | 0 |
| burden_proofs / doctrine_proofs / existentials / independence / model_consistency | 8 / 7 / 6 / 3 / 7 | 4 |
| hinge_common / hinge_mandatory / hinge_discretionary | 4 / 2 / 3 | 4 / 5 / 5 |
| scenario | 12 | 34 |
| challenger_model | 23 | 47 |
| government_model | 12 | 51 |

## Appendix C. The five structural theorems most worth reading

1. `core-conflict-pivots-on-valid-regulation` — the pivot (0 axioms).
2. `registered-implies-prior-acceptance-path` — registration requires documents accepted or the alternative approved; an instance of `lsm-run-entry-guard`.
3. `birth-cert-alone-is-not-qualifying` / `birth-cert-with-photo-id-is-qualifying` — § 3(b)(5), corrected.
4. `statutory-path-has-no-notice-or-hearing` / `save-match-removal-requires-notice` — § 8(k) and S. 1383 § 8(j)(4)(B).
5. `registration-proof-does-not-entail-voting-id` — the two enumerations.

## References

- Ye, Z., Lou, H., Sun, Y., et al. *Vero: Can AI Agents Build Formally Verified Software Repositories?* arXiv:2608.13522 (2026).
- *Crawford v. Marion County Election Board*, 553 U.S. 181 (2008). *Anderson v. Celebrezze*, 460 U.S. 780 (1983). *Burdick v. Takushi*, 504 U.S. 428 (1992). *Mathews v. Eldridge*, 424 U.S. 319 (1976). *Husted v. A. Philip Randolph Institute*, 584 U.S. 756 (2018). *Harper v. Virginia Board of Elections*, 383 U.S. 663 (1966). *Reynolds v. Sims*, 377 U.S. 533 (1964). *Fish v. Kobach*, 840 F.3d 710 (10th Cir. 2016).
- H.R. 22, 119th Cong. (EH, Apr. 10, 2025); S. 1383, 119th Cong. (EAH, Feb. 11, 2026); H.R. 7300, 119th Cong. (IH, Jan. 30, 2026). CRS In Focus IF12902 (v4, Feb. 24, 2026). Executive Orders 14248 (2025) and 14399 (2026); *LULAC v. Executive Office of the President*, No. 1:25-cv-00946 (D.D.C.).
- Kaufmann, M., Moore, J S. *ACL2*. Fuchs, N. E., et al. *Attempto Controlled English*.
