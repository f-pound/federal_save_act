# Relation to Prior Work and Claimed Contribution

This project builds on substantial prior work in computational law, rules-as-code, controlled natural languages, legal knowledge representation, and theorem proving. It is **not** the first attempt to formalize law, nor the first use of controlled English or formal logic in legal reasoning.

## Prior Work Acknowledged

### Computational Law / Rules as Code

Stanford's [computational-law materials](https://complaw.stanford.edu/) describe the field as using computational techniques to formalize and automate legal rules and legal reasoning. This project operates within that established field.

### LegalRuleML

The [OASIS LegalRuleML](https://www.oasis-open.org/committees/legalruleml/) specification extends RuleML with formal features specific to legal norms, policies, guidelines, and legal reasoning. It represents a mature standardization effort for machine-processable legal rules.

### Catala

[Catala](https://catala-lang.org/) is probably the closest "law as executable formal system" precedent. It is a domain-specific language for literate programming of legislative texts, especially socio-fiscal law, where statutory text is annotated line-by-line with code to derive implementations with a high degree of code-law faithfulness. Its authors also report compiler-correctness work using F* and evaluations on tax/benefits law.

### Attempto Controlled English (ACE)

[ACE](https://attempto.ifi.uzh.ch/) is a controlled subset of English with restricted syntax and semantics, intended for precise, computer-processable knowledge representation. ACE/RACE work supports automatic reasoning over ACE texts. This project's ACE layer is not new in isolation — what is distinctive is how it serves as a traceability bridge into ACL2 proof artifacts.

### LogiKEy / Isabelle Legal and Ethical Reasoning

The [LogiKEy](https://logikey.org/) workbench supports development and deployment of formal logics and ethical/legal theories using Isabelle/HOL theory files. It represents a serious theorem-prover line of work in legal and ethical reasoning.

### Emerging Formal Legal Verification

Projects such as "LegalLean" (verified legal reasoning in Lean 4) and "Legalis-Verifier" (integrations with Coq, Lean, Isabelle/HOL, ACL2, and PVS for legal statute verification) represent emerging work in multi-prover legal verification.

### ACL2

[ACL2](https://www.cs.utexas.edu/~moore/acl2/) is a serious industrial theorem prover with decades of history in hardware verification, software assurance, and mathematical proofs. The [ACL2 Workshop](https://www.cs.utexas.edu/~moore/acl2/workshop.html) is the established technical forum for ACL2 applications. This project's novelty is framed within that ecosystem — theorem proving itself is not new.

## Claimed Contribution

The claimed contribution is narrower and more concrete:

> To the author's knowledge, this is the first public ACL2 `certify-book`-backed **Computational Amicus Brief** for the Federal SAVE Act, combining:
>
> - ACE-style statutory normalization (APE-validated in strict mode);
> - source-traced legal assumptions from public legal sources;
> - executable voter-registration process semantics;
> - competing challenger and government constitutional models;
> - certified ACL2 books (126 Q.E.D. theorems across 17 books);
> - proof-dependency and axiom-pressure reporting; and
> - an interactive assumptions/dependency explorer.

The project does not decide whether the SAVE Act is constitutional. It proves conditional consequences from disclosed premises and makes the legal pivot points mechanically inspectable.

## What This Is Not

This project:

- Is **not** the first computational law system
- Is **not** the first theorem prover for law
- Is **not** the first AI legal proof tool
- Is **not** the first legal formalization

It is a concrete, public, reproducible ACL2 "Computational Amicus Brief" for a live U.S. election-law dispute — a specific fusion of established techniques applied to a specific legal controversy.
