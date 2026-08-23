# The agent harness — point it at a legal issue

`tools/amicus_agent.py` turns the pipeline into an autonomous loop of the shape Vero (arXiv:2608.13522) found to work: **draft (model) → verify (mechanical oracle) → repair (model, given the oracle's output)**, per stage, until green or out of repairs. Nothing the model writes is trusted until the oracles accept it.

```bash
python tools/amicus_agent.py run --issue "H.R. 7300, 119th Congress, § 113" --project ../mega_act_s113
python tools/amicus_agent.py run ... --record RUNDIR      # keep every stage output for replay
python tools/amicus_agent.py run ... --dry-run RUNDIR     # replay recorded outputs, oracles live (no API)
```

Model: `claude-opus-5`, adaptive thinking, streaming, JSON-schema structured outputs, effort `high`. Credentials: `ANTHROPIC_API_KEY` or an `ant auth login` profile.

## Stages and oracles

| Stage | The model drafts | The oracle that must go green |
|---|---|---|
| 1 sources | bill ids + text version, cases with the proposition each supports, EOs | `amicus_pipeline.py fetch` succeeds; texts registered for the stability checker |
| 2 IR | clause-IR JSON (enumerations, text rules with ACE atoms, process tables) | compiler → ACL2 books; **every quote verbatim in the bill text**; **APE strict** on every generated ACE statement |
| 3 core | stubs, conflict condition, pivot lemmas | certification; neutrality lint |
| 4 parties | scenario, hinge books, challenger + government (adversarial), trace rows with deciders, audit worlds | certification; trace validator; **consistency audit** (both theories satisfiable); **adversarial audit** (independence / coupling / redundancy) |
| 5 graph | — (deterministic from books, trace CSV, audits) | explorer data validator |

Sign-off point: after stage 3 the conflict-condition rationale is printed; `--no-signoff` skips it.

## The § 113 case study (examples/mega_act_s113)

The harness was exercised on a statute the SAVE Act project never modeled: H.R. 7300 (MEGA Act) § 113, removal of ineligible voters. **Honesty note:** no API credentials were available in the build environment, so the four model outputs in `runs/mega_act_s113/` were authored by Claude acting as the model (Claude Code session, Aug 2026) and replayed with `--dry-run`; every oracle ran live. The loop behaved as designed:

- **Stage 2, attempt 0 → red.** APE rejected 3 of 4 generated ACE statements ("by reason of", "determines that … is an"). The recorded repair rephrased three atoms; attempt 1 green (4/4 APE strict; 16 statutory quotes verbatim).
- **Stage 3 → green** first time (core certified, 2 pivot lemmas).
- **Stage 4, attempt 0 → red.** The trace validator's stability check found two trace quotes that were paraphrases, not verbatim text. Repair quoted the text; attempt 1 green: 14 books certified (99 Q.E.D.), 20 axioms all decider-tagged, both theories satisfiable (35-theorem audit book), adversarial audit: challenger 14/14 independent; government 15 independent, **2 coupled** — the "determination requires notice" hinge, the noncitizen text rule and the any-time clause form one joint.

What the statute turned out to say, mechanically: § 113 removes on the noncitizen ground (E) *at any time* — exempt from the 15-day pre-election freeze — on DHS SAVE data, with the return-card notice procedure applying to residence removals only (`save-path-removes-without-notice`, `residence-removal-requires-return-card`). That is the same due-process gap as SAVE Act § 8(k), in a different text, found by the same tools.

## What stays human

- naming the issue; owning the conflict condition (stage 3 sign-off);
- the premises the deciders decide — still toggles with decider tags, never decided by the tool;
- publication under a person's name.

Everything else is generated and re-verified on every commit of the resulting project.
