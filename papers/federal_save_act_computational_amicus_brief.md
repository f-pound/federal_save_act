# A Computational Amicus Brief for the Federal SAVE Act: Source-Traced ACL2 Theorem Proving for Conditional Constitutional Argument

**Frank Pound**

April 2026

**Repository**: [https://github.com/f-pound/federal_save_act](https://github.com/f-pound/federal_save_act)
**Interactive Explorer**: [https://f-pound.github.io/federal_save_act/](https://f-pound.github.io/federal_save_act/)

---

## Abstract

This paper presents *A Computational Amicus Brief*: a public, reproducible, mechanically certified formal model of competing constitutional theories concerning the Safeguard American Voter Eligibility Act (H.R. 22, "SAVE Act," 119th Congress). The SAVE Act conditions federal voter registration on the presentation of documentary proof of United States citizenship. Whether this requirement survives constitutional scrutiny depends on assumptions about burden severity, the adequacy of a statutory alternative attestation process, and the applicable doctrinal standard—none of which are textually resolved by the statute itself.

We formalize this controversy in ACL2, a first-order industrial theorem prover with a 40-year pedigree in hardware and software verification. The development comprises 17 independently certifiable ACL2 books containing 126 machine-checked theorems (all Q.E.D.), 33 explicitly classified and source-traced axioms (defaxioms), 4 Skolemized existential propositions (defun-sk), 4 encapsulate blocks with local witness functions, and 24 executable recursive functions (defun) modeling voter-registration state transitions, document-list reasoning, burden derivation chains, and doctrinal standards.

The architecture enforces a strict separation between five epistemic categories: (1) text-derived statutory facts, drawn directly from the enacted or proposed legal text; (2) scenario facts stipulating the properties of a concrete hypothetical registrant; (3) empirical assumptions about the severity of documentary-proof burdens; (4) interpretive assumptions encoding competing readings of statutory ambiguities; and (5) doctrinal assumptions derived from case law. Every axiom carries a provenance label, a classification, a citation to an authoritative legal source, and a quoted clause from that source. Source traceability is machine-checkable: 38 axiom-to-source mappings reference 21 authoritative sources (H.R. 22, the National Voter Registration Act, the U.S. Constitution, and case law including *Crawford v. Marion County*, *Anderson v. Celebrezze*, *Burdick v. Takushi*, *Harper v. Virginia Board of Elections*, *Reynolds v. Sims*, *Arizona v. Inter Tribal Council*, *Bolling v. Sharpe*, and *Fish v. Kobach*) via a CSV trace validated in continuous integration.

The central technical contribution is the *dual-model conditional proof architecture*. The challenger model and the government model derive opposite constitutional conclusions from their respective assumption sets, and ACL2 certifies both derivations. Under the challenger's 14 assumptions—including that citizens lack qualifying documents through no fault of their own, that obtaining such documents imposes a material burden, and that the statutory alternative process provides discretionary rather than mandatory approval—ACL2 proves that a constitutional conflict condition holds. Under the government's 16 assumptions—including that the regulation is valid under rational-basis scrutiny, that the burden is not severe, and that the alternative attestation process is adequate—ACL2 proves that no constitutional conflict holds. The system does not decide which set of assumptions is correct. The formal pivot—whether the regulation is "valid" in the sense of `valid-regulationp`—is an unconstrained defstub in the neutral model. ACL2's soundness guarantees that neither the conflict nor the no-conflict conclusion is derivable from the statutory text alone, establishing structural independence.

The interpretive hinge is identified as the mandatory-versus-discretionary reading of the alternative attestation process under § 8(j)(2)(A) of the NVRA as amended. This is modeled as two separate ACL2 books with mutually exclusive semantics: one in which officials "shall" approve (mandatory reading) and one in which officials "shall make a determination" without mandating a specific outcome (discretionary reading). The formal system proves that the challenger's constitutional conflict theorem depends on the discretionary reading, and the government's no-conflict theorem depends on the mandatory reading (or, equivalently, on the regulation being independently valid).

Beyond the conditional constitutional conclusions, the development includes substantial structural verification. An executable 10-state, 9-event voter-registration state machine models the full lifecycle from application submission through document evaluation, alternative-process determination, and final registration or denial. Twenty-four theorems establish structural invariants over arbitrary event traces by induction: terminal states are absorbing, denial requires a prior denial-triggering path, registration requires prior submission, and acceptance paths pass through designated intermediate states. Nine document-list theorems prove, by list induction, that a collection of entirely nonqualifying documents cannot satisfy the statutory documentary-proof requirement—a structural denial result independent of any interpretive assumption. Eight burden theorems derive intermediate burden conclusions (material burden, denial risk, severe burden) from executable predicate chains rather than assuming them axiomatically, reducing the trusted base. Seven doctrine theorems formalize the Anderson-Burdick balancing standard via an encapsulate block with local witnesses, proving bidirectional conditional implications between regulatory validity and the conflict condition.

The project includes an Attempto Controlled English (ACE) normalization layer. Thirteen statutory clauses from the SAVE Act have been formalized as ACE sentences and validated against the Attempto Parsing Engine (APE) in strict mode (no automatic word-class guessing), achieving 0 errors and 0 warnings across all statements. Each ACE sentence carries explicit word-class prefixes (`n:` for nouns, `v:` for verbs, `a:` for adjectives), proper determiners, and resolved anaphoric reference chains. Additionally, 13 prose paragraphs from the project's README have been translated into APE-validated ACE, producing a dual-layer document that is simultaneously human-readable and machine-parseable into Discourse Representation Structures (DRS). The ACE layer serves as an auditable bridge between raw statutory text and the formal ACL2 predicates, exposing hidden interpretive choices that occur during formalization.

The project is accompanied by an interactive web-based proof-dependency explorer that visualizes the certified proof structure across six layers (sources → formalization → executable model → derivations → theorems → conclusions). Users can toggle empirical, interpretive, and doctrinal assumptions to see which conditional conclusions remain supported, which become unsupported, and which are contested. This makes the proof dependencies navigable by legal professionals without ACL2 expertise.

We position this work within the established fields of computational law, rules-as-code, controlled natural languages, and theorem-prover-based legal reasoning, acknowledging substantial prior work including Stanford's computational-law program, the OASIS LegalRuleML specification, the Catala domain-specific language for legislative programming, the Attempto ACE/RACE controlled-language reasoning system, the LogiKEy ethical and legal reasoning workbench for Isabelle/HOL, and emerging projects in Lean- and Coq-based legal verification. The claimed contribution is narrower than these broad programs: to the author's knowledge, this is the first public ACL2 `certify-book`-backed Computational Amicus Brief for a live U.S. election-law controversy, combining source-traced statutory assumptions, ACE-style normalization, competing constitutional models, certified theorem books, proof-dependency and axiom-pressure reporting, and an interactive assumptions explorer. The entire development—17 books, 126 theorems, 33 axioms, ACE validation, explorer data, and CI pipeline—is publicly available under the Apache 2.0 license.

---

## Keywords

ACL2, theorem proving, computational law, formal methods, election law, constitutional analysis, voter registration, documentary proof of citizenship, SAVE Act, Attempto Controlled English, controlled natural language, proof dependencies, source traceability, Anderson-Burdick, computational amicus brief

---

## JEL Classification

K16 (Election Law), K40 (Legal Procedure, the Legal System, and Illegal Behavior: General)

## ACM Classification

D.2.4 Software/Program Verification — Formal methods; I.2.3 Deduction and Theorem Proving; J.1 Administrative Data Processing — Law

## MSC Classification

03B70 (Logic in computer science), 68T27 (Logic in artificial intelligence)

---

## Availability

- **Source code**: [https://github.com/f-pound/federal_save_act](https://github.com/f-pound/federal_save_act) (Apache 2.0)
- **Interactive explorer**: [https://f-pound.github.io/federal_save_act/](https://f-pound.github.io/federal_save_act/)
- **Citation**: See `CITATION.cff` in the repository root
- **Reproduction**: `./scripts/certify_all.sh` (Linux/macOS) or `.\scripts\certify_all.ps1` (Windows)
- **ACE validation**: `python tools/validate_ace_statements.py`
