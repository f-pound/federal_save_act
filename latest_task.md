Upgrade federal_save_act ACL2 Model from Source-Traced Prototype to Stronger Formal-Theorem-Proving Legal Tool

Repository:

https://github.com/f-pound/federal_save_act
Objective

Upgrade the repo so it more clearly demonstrates how ACL2 can support formal theorem proving in legal analysis, not merely organize legal assumptions. The next version should deepen the ACL2 proof content by adding general invariants, quantified/existential modeling where appropriate, stronger separation of semantic interpretations, and machine-checkable source traceability.

The goal is not to make ACL2 “decide” whether the SAVE Act is constitutional. The goal is to make ACL2 formally prove:

which conclusions follow from statutory text facts;
which conclusions require empirical burden assumptions;
which conclusions require doctrinal assumptions;
which outcome turns on the mandatory-vs-discretionary interpretation of the alternative-attestation process;
which properties hold for all registration traces, not just handpicked examples.
Current Assessment

The current v4 repo is a significant improvement. It now includes:

source manifest and clause trace;
process model;
registration state machine;
hinge model;
challenger and government books;
consistency checks;
CI proof runs.

However, it is still mostly an intermediate ACL2 formalization. The next upgrade should make the ACL2 side less trivial by proving more general properties over recursive structures and reducing reliance on party-specific assumptions.

Required Work
1. Add general state-machine invariants

Current process proofs appear to focus on specific named traces. Add generalized theorems over arbitrary traces.

Create or update:

federal_save_act_process_invariants.lisp

Add theorems such as:

(defthm terminal-state-registered-not-denied
  ...)

(defthm terminal-state-denied-not-registered
  ...)

(defthm registered-implies-valid-path
  ...)

(defthm denied-implies-denial-trigger-or-discretionary-denial
  ...)

(defthm approval-event-prevents-denial-under-mandatory-semantics
  ...)

The exact theorem names may differ, but the substance should be:

no registration trace can validly terminate as both registered and denied;
if a trace reaches :registered, then the trace must contain either accepted documentary proof or approved alternative evidence;
if a trace reaches :denied, then the trace must contain a denial event or a failed proof/alternative path;
under mandatory alternative-process semantics, once sufficient alternative evidence is accepted, denial is impossible.

Use induction over reg-run-trace or the trace-processing function.

2. Split mandatory and discretionary hinge semantics into separate books

Right now the hinge model identifies the interpretive fork. Make the fork structural.

Create:

federal_save_act_hinge_common.lisp
federal_save_act_hinge_mandatory.lisp
federal_save_act_hinge_discretionary.lisp

hinge_common should contain shared definitions.

hinge_mandatory should prove government-favorable results under a rule like:

sufficient-alternative-evidence => must-register

hinge_discretionary should prove challenger-favorable results under a rule like:

official-determination-required
and
sufficiently-established-undefined
and
discretionary-denial-possible
=> risk-of-erroneous-denial

Do not allow both books to be included in one combined theory unless the semantics are explicitly parameterized and proven mutually exclusive.

3. Add existential modeling with defun-sk or defchoose

Legal burden analysis often depends on existence claims, not just named examples.

Add a file:

federal_save_act_existentials.lisp

Model propositions such as:

There exists an eligible citizen who lacks qualifying documentary proof.

There exists an eligible citizen who cannot reasonably obtain qualifying documents.

There exists a registration trace in which a qualified citizen is denied under discretionary alternative-process semantics.

Use ACL2 constructs such as defun-sk or defchoose where appropriate.

Then prove bridge theorems connecting those witnesses to challenger-side burden predicates.

Example target shape:

(defthm exists-burdened-citizen-implies-nontrivial-burden-class
  ...)

This will make the model stronger than a single hardcoded 'citizen-a scenario.

4. Add document-list and evidence-list theorems

The document model should do more than recognize individual document symbols. Add recursive list proofs.

Target properties:

(defthm no-documents-implies-no-qualifying-document
  ...)

(defthm member-qualifying-document-implies-has-qualifying-document
  ...)

(defthm append-preserves-qualifying-document
  ...)

(defthm removing-nonqualifying-documents-preserves-qualifying-status
  ...)

This gives the model real recursive list reasoning, closer to exemplar ACL2 proof developments.

5. Add source-trace validation tooling

The current sources/clause_trace.csv is good for human audit. Add a lightweight validator so the repo can check that source-traced ACL2 events remain aligned.

Create:

tools/validate_trace.py

The script should check:

every defaxiom has a row in sources/clause_trace.csv;
every source-traced theorem or axiom has a source_id;
every source_id in clause_trace.csv exists in source_manifest.json;
no row in clause_trace.csv references a missing ACL2 event;
legal proposition labels are one of:
TEXT_FACT
DOCTRINAL_RULE
EMPIRICAL_ASSUMPTION
INTERPRETIVE_ASSUMPTION
PROCESS_RULE
BRIDGE_RULE
SCENARIO_FACT

Add this validator to CI.

6. Reduce or classify remaining defaxioms

Do not necessarily eliminate every defaxiom. But every remaining defaxiom must be classified.

Acceptable classes:

TEXT_FACT
SCENARIO_FACT
BRIDGE_RULE
EMPIRICAL_ASSUMPTION
DOCTRINAL_RULE
INTERPRETIVE_ASSUMPTION

Rules:

statutory text propositions may remain as TEXT_FACT;
named citizen facts may remain as SCENARIO_FACT;
legal doctrine should preferably be encoded as reusable rules, not one-off outcome axioms;
party-specific legal judgments should move into challenger/government books or encapsulated theory modules;
empirical claims should be explicitly labeled and source-linked when possible.

Add a report:

reports/axiom_inventory.md

Include:

event name
file
classification
source_id
reason this remains an axiom
future replacement path
7. Add non-entailment / independence checks

The repo should demonstrate that neutral statutory facts alone do not decide the constitutional outcome.

Add:

federal_save_act_independence.lisp

Goal:

show that neutral facts are compatible with a government-favorable interpretation;
show that neutral facts are compatible with a challenger-favorable interpretation;
show that the outcome depends on additional doctrine/empirical/interpretive assumptions.

ACL2 does not directly prove “not derivable” in the usual legal-philosophy sense, so implement this through separate consistent model books or countermodel-style encapsulates.

Target result:

(defthm neutral-model-does-not-force-conflict
  ...)

(defthm neutral-model-does-not-force-no-conflict
  ...)

If exact theorem names are not feasible, document the approach clearly.

8. Improve documentation to distinguish legal rigor from proof complexity

Update:

README.md
Overview.md

The documentation should say:

This project does not prove the SAVE Act constitutional or unconstitutional.
It proves conditional legal conclusions inside explicitly stated formal models.
The value is in exposing assumptions, statutory hinges, process behavior, and doctrinal dependencies.

Add a section:

What ACL2 proves
What ACL2 does not prove
What remains assumed
What is source-traced
What is empirically contestable

Also add a short comparison to ordinary ACL2 proof complexity:

The project now uses recursive functions, event traces, encapsulate, local witnesses, and CI-certified theorems.
It remains less complex than major ACL2 industrial proofs because it has limited arithmetic, limited induction depth, and no large refinement stack.
9. Strengthen CI

Update GitHub Actions so CI runs:

trace validator
ACL2 certification
axiom inventory generation/check
all process invariant books
all hinge books
all challenger/government/consistency books

CI should fail if:

ACL2 certification fails;
a defaxiom lacks trace classification;
a source ID is missing;
generated reports are stale;
mandatory and discretionary hinge books are accidentally combined into an inconsistent theory.
10. Produce a final v5 report

Add:

reports/v5_formal_methods_assessment.md

The report should summarize:

number of ACL2 events;
number of recursive functions;
number of induction proofs;
number of encapsulate blocks;
number of defaxioms by classification;
number of source-traced propositions;
number of process invariant theorems;
remaining limitations;
next recommended ACL2 upgrades.
Acceptance Criteria

The task is complete when:

All ACL2 books certify successfully.
CI passes on a clean checkout.
The repo contains generalized process invariants over arbitrary traces.
Mandatory and discretionary alternative-process semantics are separated.
Existential burden modeling is present.
Remaining defaxioms are inventoried and source-classified.
Source trace validation runs in CI.
Documentation accurately states what ACL2 proves and what remains assumed.
The final report explains why this is a stronger formal-theorem-proving tool for law than the prior version.
Preferred Design Principle

Favor this style:

public legal source
→ normalized legal proposition
→ classified ACL2 event
→ executable model or abstract constrained predicate
→ theorem obligation
→ certified result

Avoid this style:

legal conclusion
→ defaxiom
→ theorem restating conclusion

The upgraded repo should make the formal legal argument auditable, reproducible, and mechanically checked while remaining honest that constitutional judgment still depends on disputed doctrine, facts, and interpretive assumptions.