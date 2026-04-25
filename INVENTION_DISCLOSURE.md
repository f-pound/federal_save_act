# Origin and Concept Disclosure

**Date**: 2026-04-25

**Author**: F-Pound Project Contributors

---

## Public Disclosure of Architecture

This document constitutes a dated public disclosure of the architecture and
methodology described below, establishing prior art as of the date above.

## Concept

This repository discloses a framework for **constitutional stress-testing** of
statutes, bills, referenda, and judicial decisions. The framework converts legal
text into controlled intermediate representations and formal ACL2
theorem-prover models that mechanically derive the assumptions required to prove
or disprove constitutional conflict.

The architecture enforces a strict separation between:

1. **Source-text facts** — propositions directly stated in the enacted or
   proposed legal text, labeled `TEXT_FACT`, `DEFINED_TERM`, `PROHIBITION`,
   `EXCEPTION`, `PENALTY`, or `PROCEDURAL_FACT`.

2. **Applications of defined terms** — propositions that apply a statutory
   definition to a specific object or scenario, labeled
   `APPLICATION_OF_DEFINED_TERM`.

3. **Empirical and technical classifications** — factual claims requiring
   evidence or expertise outside the legal text, labeled `EMPIRICAL_FACT` or
   `TECHNICAL_CLASSIFICATION`.

4. **Challenger interpretive assumptions** — assumptions favoring a
   constitutional challenge, labeled `INTERPRETATION_CHALLENGER` or
   `DOCTRINAL_ASSUMPTION`.

5. **Government (or Commonwealth) interpretive assumptions** — assumptions
   favoring defense of the law, labeled `INTERPRETATION_GOVERNMENT` or
   `POLICY_ASSUMPTION`.

6. **ACL2 proof obligations** — formal theorems that the prover attempts under
   each model's axioms, establishing whether constitutional conflict follows
   from the model's assumptions.

## Method

The workflow proceeds through a pipeline of specialized agents:

1. **Source Locator** — identifies and retrieves authoritative legal text.
2. **Parser** — splits text into structured sections with source provenance.
3. **Legal Structure Agent** — extracts definitions, prohibitions, exceptions,
   penalties, and procedural provisions.
4. **ACE Normalization Agent** — converts extracted clauses into Attempto
   Controlled English (ACE) statements, validated against the Attempto Parsing
   Engine (APE) where available, producing an auditable bridge between raw legal
   text and formal predicates.
5. **Predicate Extraction Agent** — converts normalized clauses into ACL2-ready
   predicates with source labels, confidence scores, and human-review flags.
6. **Constitutional Matcher** — maps statutory burdens against constitutional
   interests, proposes conflict predicates, and separates text facts from
   interpretive bridge rules.
7. **ACL2 Generation Agent** — emits four ACL2 books:
   - `*_core.lisp` — neutral vocabulary and generic conflict conditions
   - `*_facts.lisp` — text-derived axioms only
   - `*_challenger_model.lisp` — challenge-side interpretive assumptions
   - `*_government_model.lisp` — defense-side interpretive assumptions
8. **Proof Runner** — executes each model in an independent ACL2 session and
   records which theorems proved, which failed, and which assumptions were
   needed for each result.
9. **Report Agent** — produces human-readable analysis identifying the
   interpretive hinges, statutory ambiguities, and proof-controlling assumptions.

## Key Design Principles

- **The system does not decide constitutionality.** It identifies which
  assumptions are necessary to prove conflict or no conflict under competing
  legal theories.

- **Facts and interpretations are never mixed.** Every assertion carries a
  provenance label. Interpretive assumptions are quarantined in model-specific
  files and are never placed in the facts file.

- **Competing models are never loaded together.** The challenger and government
  models derive opposite conclusions and are intentionally incompatible. They
  run in separate ACL2 sessions.

- **Statutory ambiguities are surfaced, not resolved.** Where the enacted text
  does not clearly answer a constitutional question, the system identifies the
  ambiguity, shows how each model resolves it, and reports the interpretive
  distance each model travels from the plain text.

- **ACE normalization provides an auditable intermediate layer.** Before
  predicates are extracted, legal clauses are rewritten into controlled English
  and validated against a parser. This exposes hidden interpretation and
  preserves exact statutory thresholds.

## Scope of Disclosure

This disclosure covers:

- The overall architecture of separated fact/interpretation/proof layers
- The use of ACL2 as the theorem prover for constitutional reasoning
- The ACE/APE normalization pipeline as an intermediate representation
- The labeling taxonomy (TEXT_FACT through HUMAN_REVIEW_REQUIRED)
- The dual-model proof strategy (challenger vs. government)
- The interpretive-distance analysis methodology
- The statutory-ambiguity identification and binary-fact residual analysis
- The application of this framework to any jurisdiction's statutes, bills,
  constitutional provisions, referenda, or judicial decisions

## License

This disclosure is made publicly to establish prior art. The repository
contents are governed by the license file in this repository, if any,
or are otherwise made available for public reference.

---

*This document was created on 2026-04-25 and committed to a public GitHub
repository to establish a verifiable timestamp of disclosure.*
