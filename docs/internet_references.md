# Internet References

External resources, tools, and prior work referenced during the development of the Federal SAVE Act constitutional stress-test. Each entry includes a brief description of what it is and why it is relevant to this project.

---

## Computational Law & Rules-as-Code

- **[Stanford Computable Contracts (CompLaw)](https://complaw.stanford.edu/complaw/public/index.php)**
  Interdisciplinary research program exploring machine-processable legal rules. Provides foundational prior work in the computational-law space that this project extends into ACL2-backed constitutional modeling.

- **[LegalRuleML Core Specification (OASIS)](https://docs.oasis-open.org/legalruleml/legalruleml-core-spec/v1.0/os/legalruleml-core-spec-v1.0-os.html)**
  XML standard for representing legal norms and rules in machine-readable form. Relevant as an alternative formalization approach; this project's ACE-normalized clauses and ACL2 axioms solve a similar problem with different tooling.

- **[Catala — A Programming Language for the Law (Microsoft Research)](https://www.microsoft.com/en-us/research/publication/catala-a-programming-language-for-the-law/)**
  Academic paper on Catala, a language designed to faithfully encode legislative texts as executable specifications. Catala represents a complementary approach to the statutory formalization done here in ACL2.

- **[Catala Language — Testing & CI Guide](https://book.catala-lang.org/en/3-3-test-ci.html)**
  Documentation on Catala's testing and continuous-integration workflows. Referenced as a model for this project's own CI-based proof certification pipeline.

- **[Legal Lean (GitHub)](https://github.com/edu-ap/legal-lean)**
  Experimental project formalizing legal reasoning in the Lean theorem prover. Relevant as a parallel effort in theorem-prover-based legal analysis using a different proof assistant.

- **[LogiKEy / Isabelle — Computational Legal Reasoning (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC7586073/)**
  Paper on using the Isabelle/HOL theorem prover for normative and legal reasoning. Part of the prior-work landscape this project acknowledges and builds upon.

---

## Attempto Controlled English (ACE)

- **[Attempto Project — Resources](https://attempto.ifi.uzh.ch/site/resources/)**
  Main resource page for the Attempto Controlled English project at the University of Zurich. ACE is the controlled natural language used in this project to produce machine-parseable formal prose translations of the README and statutory clauses.

- **[Attempto Parsing Engine (APE) — GitHub](https://github.com/Attempto/APE)**
  Source code for the Attempto Parsing Engine, which parses ACE text into discourse representation structures. This project's ACE validation pipeline (`tools/validate_ace_statements.py`) calls APE to verify strict-mode compliance.

- **[APE Web Service](https://attempto.ifi.uzh.ch/ape/)**
  Online interface for the Attempto Parsing Engine. Used interactively to validate and debug ACE statements during development of the formal prose appendix.

---

## Theorem Provers

- **[ACL2 v8-7 — Combined Manual (Pre-Built Binaries)](https://www.cs.utexas.edu/~moore/acl2/v8-7/combined-manual/index.html?topic=ACL2____PRE-BUILT-BINARY-DISTRIBUTIONS)**
  Official ACL2 documentation and binary download page. ACL2 is the theorem prover used for all 126 certified theorems in this project's formal constitutional model.

- **[PVS — Prototype Verification System (SRI)](https://pvs.csl.sri.com/)**
  Alternative higher-order logic theorem prover from SRI International. Referenced as a potential future tool for extending the formalization beyond ACL2's first-order logic.

---

## Static Analysis

- **[Kestrel Technology (GitHub)](https://github.com/kestreltechnology)**
  Open-source static analysis and program verification tools. Referenced for potential integration with code-level verification workflows.
