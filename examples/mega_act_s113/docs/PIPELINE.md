# The pipeline — from public legal documents to a certified, auditable amicus brief

This repository is a worked example; the tools are a template. `tools/amicus_pipeline.py` chains them:

```
 public sources ──fetch──▶ inputs/ + status JSON
                ──extract─▶ data/parsed/<slug>_draft_rules.json      ← HUMAN REVIEW
                ──compile─▶ model/*.lisp + ACE (APE-validated) + docs/generated/*.md
                ──certify─▶ every book, every theorem (ACL2)
                ──audit───▶ consistency (toy worlds) · adversarial (flip each axiom) · trusted base
                ──hinges──▶ reports/hinges.md — which premises the outcomes turn on
```

## 0. Scaffold a new matter

```bash
python tools/amicus_pipeline.py init ../my_statute --title "My Statute — Computational Amicus Brief"
```
Copies the statute-independent parts — `model/lib/` (the lemma libraries), `tools/`, `scripts/`, the CI workflow, the explorer shell, this document — and creates empty `inputs/`, `data/parsed/`, `sources/`, a `pipeline.json`, an empty core book and an empty `data/audit_worlds.json`.

## 1. Fetch

```bash
python tools/amicus_pipeline.py fetch bill 119 hr 22 --version eh     # govinfo bill text
python tools/amicus_pipeline.py fetch status 119 s 1383               # BILLSTATUS XML → draft status JSON (votes, latest action, text versions)
python tools/amicus_pipeline.py fetch eo 14399                        # Federal Register executive order
COURTLISTENER_TOKEN=… python tools/amicus_pipeline.py fetch case "Crawford v. Marion County"
```
All fetchers fail soft and print the URL to retrieve by hand. Every fetched text carries its source URL in a header; add each to `sources/source_manifest.json` (the trace validator enforces it).

## 2. Extract (drafts, never compiled as-is)

```bash
python tools/amicus_pipeline.py extract inputs/119s1383_eah_text.txt --source-id s1383-eah --slug my_statute
```
Heuristics find **enumerated definitions** (“the term ‘X’ means … any of the following: (1) …”) and **prohibitions / duties** (“shall not … unless …”, “shall remove / establish a process / submit …”) and write a clause-IR draft with `requires_human_review: true`. Every `text` is a verbatim quote, so `check_text_stability.py` can verify it. On the SAVE America Act text this finds both statutory lists (§ 3(b), § 303A(c)) and the three operative prohibitions. What the extractor deliberately does **not** decide: the paired structure inside an enumeration (§ 3(b)(5)'s “only if presented together with”), predicate names, and which clauses are rules versus process edges. A person renames `<slug>_draft_rules.json` into the IR files listed in `pipeline.json`, following `tools/clause_ir_schema.json`:

- `categories` — enumerations (one `defconst` each) with `ace_noun` per member;
- `rules` — `defun` bodies over `some-in` / `member` / `and` / `or`, or `kind: axiom` text rules with `atoms` carrying ACE phrases;
- `process` — a labeled state machine table, each edge with its citation and, where the vehicle differs, its own `source_id` and quote.

## 3. Compile

```bash
python tools/amicus_pipeline.py compile --ace --validate-ace
```
One source file → three outputs that cannot disagree: the ACL2 book, the Attempto Controlled English (validated against the APE web service in strict mode), and a Markdown paraphrase. The generated books are byte-checked in CI.

Then write by hand, in this order, each a short book:
1. `core` — `defstub` vocabulary, factored conflict condition(s), pivot lemmas. **No axioms.**
2. `facts` / text rules — generated from the IR.
3. `scenario` — party-stipulated ground facts, shared.
4. `hinge_*` — one book per competing reading of the statute's pivotal phrase.
5. `challenger_model` / `government_model` — `encapsulate` for interpretive rules (local witness proves consistency), `defaxiom` for bridges, one `defthm` per conclusion.
6. Invariant books — instantiate `lib/lsm` (process) and `lib/enum_list` (enumerations) over the generated tables: `:use` a library lemma, let ACL2 evaluate the table. No statute-specific induction should be necessary; if one seems to be, add the missing generic lemma to `lib/`.

Every `defaxiom` needs a row in `sources/clause_trace.csv` with a **decider** (`legislature` / `court` / `fact-finder` / `party-stipulation`) — CI refuses untagged axioms and any axiom in a neutral book.

## 4. Certify

```bash
python tools/amicus_pipeline.py certify        # = scripts/certify_books.sh
```

## 5. Audit

```bash
python tools/amicus_pipeline.py audit --acl2
```
Fill `data/audit_worlds.json`: for each party, a toy world (named constants; every stub a membership test). The consistency audit generates and certifies a book proving every axiom and interpretive rule of the party in that world; the adversarial audit denies each axiom in turn and reports **independent / coupled / redundant**; `print_axioms.py` reports each book's trusted base. See `docs/AUDITS.md`.

## 6. Hinges and the explorer

```bash
python tools/amicus_pipeline.py hinges
```
`reports/hinges.md` lists the coupled clusters from the adversarial audit and, for every toggleable premise, the final conclusions downstream of it. Curate `data/parsed/explorer_graph.json` (nodes, edges, hypotheticals, presets) and `data/legislative_status.json`; `tools/build_explorer_data.py` assembles `web/data/explorer.json` with the census, trusted bases, audit verdicts, document tables and status for the interactive explorer.

## Human review points, explicitly

| Stage | What a person decides |
|---|---|
| extract → IR | structure of enumerations; predicate names; rule vs. process; which clauses matter |
| core | the vocabulary and the shape of the conflict condition |
| scenario / party books | which facts are stipulated; each party's legal theory and its sources |
| trace CSV | the decider tag and source citation for every axiom |
| audit worlds | a concrete world per party (the prover checks it) |
| explorer graph | what to show and how to label it |

Everything else — proofs, ACE, paraphrases, consistency, independence, trusted bases, status — is generated and re-checked on every commit.
