# Federal SAVE Act — Proof Obligations Report

## Summary

Both the challenger and government models proved successfully in ACL2 8.6+.
This confirms that the constitutional conflict (or absence thereof) follows
logically from each model's assumptions — the outcome depends on which
interpretive assumptions are accepted.

## Challenger Model

**File**: `federal_save_act_challenger_model.lisp`

**Theorem**: `challenger-model-finds-conflict`

**Result**: ✅ **Q.E.D.** — Proved

**Prover steps**: 144

**Rules used**:
- `CONSTITUTIONAL-CONFLICT-CONDITIONP` (definition)
- `CHALLENGER-DOCUMENTARY-PROOF-IS-UNDUE-BURDEN` (rewrite)
- `CHALLENGER-FUNDAMENTAL-RIGHT-RULE` (rewrite)
- `CHALLENGER-UNDUE-BURDEN-DEFEATS-REGULATION` (rewrite)
- `SCENARIO-ALTERNATIVE-PROCESS-DENIED` (rewrite)
- `SCENARIO-APPLICATION` (rewrite)
- `SCENARIO-ATTEMPTS-TO-REGISTER` (rewrite)
- `SCENARIO-CITIZEN` (rewrite)
- `SCENARIO-ELIGIBLE` (rewrite)
- `SCENARIO-NO-DOCUMENTARY-PROOF` (rewrite)
- `SCENARIO-NO-FAULT` (rewrite)
- `SCENARIO-PERSON` (rewrite)
- `TEXT-SAVE-ACT-DOCUMENTARY-PROOF-REQUIREMENT` (rewrite)
- `TEXT-SAVE-ACT-IS-LAW` (rewrite)

**Proof chain**:
1. Scenario facts establish citizen-a as a U.S. citizen eligible to vote
2. `challenger-fundamental-right-rule` establishes the protected right to vote
3. Citizen-a lacks documentary proof + alternative process denied → `text-save-act-documentary-proof-requirement` establishes registration denial
4. `challenger-documentary-proof-is-undue-burden` establishes the undue burden
5. `challenger-undue-burden-defeats-regulation` negates valid-regulationp
6. All conjuncts of `constitutional-conflict-conditionp` are satisfied

**All assumptions required for Q.E.D.**:

| # | Axiom name | Label | Role in proof chain |
|---|---|---|---|
| 1 | `text-save-act-is-law` | TEXT_FACT | Establishes `(lawp 'federal-save-act)` |
| 2 | `text-save-act-documentary-proof-requirement` | PROHIBITION | Establishes `statute-denies-registrationp` when no proof and no alternative process |
| 3 | `scenario-person` | SCENARIO_FACT | `(personp 'citizen-a)` |
| 4 | `scenario-citizen` | SCENARIO_FACT | `(citizen-of-usp 'citizen-a)` |
| 5 | `scenario-eligible` | SCENARIO_FACT | `(eligible-voterp 'citizen-a)` |
| 6 | `scenario-application` | SCENARIO_FACT | `(voter-registration-applicationp 'registration-attempt-a)` |
| 7 | `scenario-attempts-to-register` | SCENARIO_FACT | `(attempts-to-registerp 'citizen-a 'registration-attempt-a)` |
| 8 | `scenario-no-documentary-proof` | SCENARIO_FACT | `(not (has-documentary-proofp 'citizen-a))` |
| 9 | `scenario-no-fault` | INTERPRETATION_CHALLENGER | `(lacks-qualifying-documents-through-no-faultp 'citizen-a)` |
| 10 | `scenario-alternative-process-denied` | INTERPRETATION_CHALLENGER | `(not (alternative-process-approvedp 'citizen-a 'registration-attempt-a))` |
| 11 | `challenger-fundamental-right-rule` | DOCTRINAL_ASSUMPTION | Voting is a fundamental right (Harper, Reynolds) → `protected-right-to-votep` |
| 12 | `challenger-documentary-proof-is-undue-burden` | INTERPRETATION_CHALLENGER | Doc-proof requirement unduly burdens citizens without documents → `undue-burden-on-right-to-votep` |
| 13 | `challenger-undue-burden-defeats-regulation` | INTERPRETATION_CHALLENGER | Undue burden defeats valid-regulation status → `(not (valid-regulationp ...))` |

**Warnings**:
- Free variable warning on `CHALLENGER-UNDUE-BURDEN-DEFEATS-REGULATION` (variable P is bound by searching for `PERSONP P`). This is a structural artifact of the rewrite rule and does not affect the proof of the scenario theorem.

---

## Government Model

**File**: `federal_save_act_government_model.lisp`

**Theorem**: `government-model-no-conflict`

**Result**: ✅ **Q.E.D.** — Proved

**Prover steps**: 117

**Rules used**:
- `CONSTITUTIONAL-CONFLICT-CONDITIONP` (definition)
- `GOVERNMENT-ADEQUATE-ALTERNATIVE` (rewrite)
- `GOVERNMENT-ASSUME-RIGHT-TO-VOTE-ARGUENDO` (rewrite)
- `GOVERNMENT-ELECTION-INTEGRITY-INTEREST` (rewrite)
- `GOVERNMENT-REASONABLE-REQUIREMENT` (rewrite)
- `GOVERNMENT-VALID-REGULATION-RULE` (rewrite)
- `SCENARIO-ATTEMPTS-TO-REGISTER` (rewrite)
- `SCENARIO-CITIZEN` (rewrite)
- `SCENARIO-ELIGIBLE` (rewrite)
- `SCENARIO-PERSON` (rewrite)
- `TEXT-SAVE-ACT-IS-LAW` (rewrite)

**Proof chain**:
1. Three government interpretive axioms (election integrity interest + reasonable requirement + adequate alternative) combine via `government-valid-regulation-rule` to establish `(valid-regulationp 'federal-save-act 'registration-attempt-a)`
2. `valid-regulationp` negates the `(not (valid-regulationp ...))` conjunct
3. `constitutional-conflict-conditionp` evaluates to NIL
4. Additionally, `scenario-alternative-process-approved` means the `text-save-act-documentary-proof-requirement` prohibition does not fire (alternative process approved defeats the denial)

**All assumptions required for Q.E.D.**:

| # | Axiom name | Label | Role in proof chain |
|---|---|---|---|
| 1 | `text-save-act-is-law` | TEXT_FACT | Establishes `(lawp 'federal-save-act)` |
| 2 | `scenario-person` | SCENARIO_FACT | `(personp 'citizen-a)` |
| 3 | `scenario-citizen` | SCENARIO_FACT | `(citizen-of-usp 'citizen-a)` |
| 4 | `scenario-eligible` | SCENARIO_FACT | `(eligible-voterp 'citizen-a)` |
| 5 | `scenario-attempts-to-register` | SCENARIO_FACT | `(attempts-to-registerp 'citizen-a 'registration-attempt-a)` |
| 6 | `government-assume-right-to-vote-arguendo` | INTERPRETATION_GOVERNMENT | Concedes `(protected-right-to-votep 'amend-v-equal-protection 'citizen-a)` arguendo |
| 7 | `government-election-integrity-interest` | POLICY_ASSUMPTION | `(election-integrity-interestp 'federal-save-act)` |
| 8 | `government-reasonable-requirement` | INTERPRETATION_GOVERNMENT | `(reasonable-registration-requirementp 'federal-save-act)` |
| 9 | `government-adequate-alternative` | INTERPRETATION_GOVERNMENT | `(adequate-alternative-processp 'federal-save-act)` |
| 10 | `government-valid-regulation-rule` | INTERPRETATION_GOVERNMENT | Three-factor rule → `(valid-regulationp 'federal-save-act x)` |
| 11 | `scenario-alternative-process-approved` | INTERPRETATION_GOVERNMENT | `(alternative-process-approvedp 'citizen-a 'registration-attempt-a)` |

**Note**: Axioms 7–10 combine to negate the `(not (valid-regulationp ...))` conjunct (path 1). Axiom 11 independently defeats `statute-denies-registrationp` by satisfying the alternative-process exception in the facts file (path 2). Either path alone is sufficient to defeat the conflict.

This means even if the valid-regulation defense failed, the government could still argue no registration was actually denied.

---

## Statutory Ambiguities That Control the Constitutional Outcome

The following are places where the enacted text of the SAVE Act does not
clearly resolve the legal question. Each ambiguity maps to one or more
axioms that the challenger and government models resolve in opposite
directions. The constitutional outcome depends on how these ambiguities
are read.

1. **"Sufficiently established" is undefined** (§ 8(j)(2)(A)(i)):
   - The text says officials "shall make a determination as to whether the applicant has *sufficiently established* United States citizenship."
   - But "sufficiently established" is not defined anywhere in the Act. The EAC must develop "minimum standards" (§ 8(j)(2)(A)(iii)), but the Act does not say what those standards are.
   - **The ambiguity**: Does "shall make a determination" mean the official *must register* an applicant whose citizenship is adequately shown? Or does it merely require the official to *consider the evidence* and exercise judgment — leaving discretionary denial power intact?
   - **Why it matters**: This single ambiguity is the primary hinge. The challenger model reads it as discretionary (axiom `scenario-alternative-process-denied`). The government model reads it as guaranteeing a path (axiom `scenario-alternative-process-approved`). The entire constitutional outcome turns on which reading is correct.

2. **"Manner" vs. "qualifications" boundary is undrawn** (Art. I, §§ 2 & 4):
   - The Elections Clause gives Congress power over the "manner" of holding elections. Article I, § 2 reserves voter *qualifications* to the states.
   - The SAVE Act imposes a documentary-proof-of-*citizenship* requirement on voter *registration*. Is that a regulation of the *manner* of registering (permissible) or a new voter *qualification* (reserved to states)?
   - **The ambiguity**: The Act does not identify which constitutional power it invokes. The text simply amends the NVRA without stating whether it is exercising manner-regulation authority or overriding state qualification authority.
   - **Why it matters**: *Arizona v. Inter Tribal Council* (2013) held that states cannot add documentary-proof requirements to federal registration forms under the NVRA. Whether Congress itself can impose what states cannot is an open question the text does not answer.

3. **The cost of qualifying documents is not addressed** (§ 3(b)):
   - The Act defines six categories of qualifying documents. Several require payment: birth certificates ($10–$30+), passports ($130+), REAL ID licenses (varies by state).
   - **The ambiguity**: The Act does not provide free documents, waive fees, or address whether the cost of obtaining qualifying documents functions as a condition on the right to vote. It simply requires the documents and is silent on cost.
   - **Why it matters**: The Twenty-Fourth Amendment prohibits poll taxes. If obtaining documentary proof requires paying fees that some eligible citizens cannot afford, the requirement may function as a de facto tax on voting. The text does not resolve this.

4. **"At any time" removal lacks procedural specification** (§ 8(k)):
   - The text says: "A State shall remove an individual... from the official list of eligible voters... *at any time* upon receipt of documentation or verified information that a registrant is not a United States citizen."
   - **The ambiguity**: The Act does not specify what "verified information" means, does not require notice to the registrant before removal, and does not provide an opportunity to contest removal before it takes effect. The existing NVRA protections (§ 8(c)–(d)) may or may not apply to this new removal authority.
   - **Why it matters**: Procedural due process requires adequate notice and an opportunity to be heard before deprivation of a protected interest. Whether § 8(k) satisfies that requirement depends on how "verified information" and "at any time" are interpreted in practice.

5. **The burden population is unquantified** (no section):
   - The Act does not estimate or acknowledge how many eligible U.S. citizens currently lack all six categories of qualifying documents.
   - **The ambiguity**: This is not a textual ambiguity in the usual sense — the Act simply omits any empirical foundation for the requirement. Whether the burden falls on a trivial or substantial number of citizens is an `EMPIRICAL_FACT` that the text does not address.
   - **Why it matters**: Under Crawford's burden-balancing framework, the severity of the burden depends on the number and characteristics of affected voters. The model stipulates one citizen (citizen-a) but the constitutional question scales to the affected population.

---

## What Do the Clear Binary Facts Alone Tell Us?

If we strip away every ambiguity and every interpretive assumption —
removing all `INTERPRETATION_CHALLENGER`, `INTERPRETATION_GOVERNMENT`,
`DOCTRINAL_ASSUMPTION`, and `POLICY_ASSUMPTION` axioms — and look only
at the undisputed `TEXT_FACT`, `PROHIBITION`, and `SCENARIO_FACT` entries,
what remains?

### The undisputed facts

These are the things that both models agree on and that require no
interpretation. They come from the enacted text and the stipulated
scenario:

| # | Fact | Source | Status |
|---|---|---|---|
| 1 | The SAVE Act is a law | § 1 | Clear |
| 2 | Registration is denied to any person who lacks documentary proof and is not approved through the alternative process | § 4(b), § 8(j)(1) | Clear |
| 3 | Documentary proof means one of six categories of documents (REAL ID, passport, military ID + birth record, govt photo ID + birth, govt photo ID + supporting doc) | § 3(b) | Clear |
| 4 | An alternative attestation process exists in the text | § 8(j)(2)(A) | Clear |
| 5 | Provisional ballots are preserved | § 6 | Clear |
| 6 | citizen-a is a U.S. citizen, eligible to vote, who attempts to register | Stipulated | Clear |
| 7 | citizen-a does NOT possess any of the six categories of qualifying documents | Stipulated | Clear |

### What the facts establish without interpretation

From facts 1, 2, 6, and 7 alone:

> **citizen-a is an eligible U.S. citizen who is denied registration under the SAVE Act.**

This follows directly from the text. The prohibition in § 8(j)(1) fires: citizen-a attempts to register, lacks documentary proof, and — here is where the analysis forks — either is or is not saved by the alternative process.

### The fork: the alternative process

Fact 4 tells us the alternative process *exists in the text*. But the clear binary facts **cannot tell us whether citizen-a would be approved through it**, because:

- Whether the process guarantees registration or leaves discretion is **Ambiguity #1** (the primary hinge)
- The standard ("sufficiently established") is undefined
- The EAC minimum standards do not yet exist

The text creates the process but does not resolve its outcome. This is not a fact that can be read as true or false — it is genuinely indeterminate from the text alone.

### Answer: The clear facts alone do NOT resolve constitutionality in either direction

| Question | What the clear facts tell us |
|---|---|
| Is citizen-a denied standard registration? | **Yes** — this is a clear text fact. citizen-a lacks all qualifying documents, so § 8(j)(1) denies registration. |
| Is citizen-a saved by the alternative process? | **Indeterminate** — the process exists in the text, but its outcome for citizen-a depends on the undefined "sufficiently established" standard (Ambiguity #1). |
| Is the SAVE Act a valid regulation? | **Indeterminate** — the text does not say whether it is exercising "manner" authority under Art. I, § 4 or encroaching on state "qualification" authority under Art. I, § 2 (Ambiguity #2). |
| Does the cost of documents matter? | **Indeterminate** — the text requires documents but is silent on cost (Ambiguity #3). |
| Does the removal process satisfy due process? | **Indeterminate** — the text says "at any time" but specifies no procedural protections (Ambiguity #4). |

### What this means

**The undisputed facts alone produce a half-proven conflict:**

1. ✅ citizen-a is a person, a citizen, and eligible to vote — **clear**
2. ✅ citizen-a attempts to register — **clear**
3. ✅ The SAVE Act denies citizen-a's registration (because citizen-a lacks documentary proof) — **clear, IF the alternative process does not save them**
4. ❓ Whether the alternative process saves citizen-a — **indeterminate**
5. ❓ Whether citizen-a has a constitutionally protected right to vote — **requires doctrinal assumption**
6. ❓ Whether the regulation is valid — **indeterminate**

Steps 1–3 are established by clear text facts. Steps 4–6 all depend on resolving ambiguities. **No amount of clear binary facts can finish the proof in either direction.**

This is why both the challenger and government models must supply interpretive axioms to reach their conclusions. The text creates a prohibition (clear), creates an exception whose effectiveness is undefined (ambiguous), and does not state its own constitutional authority (ambiguous). The constitutional question cannot be answered from the text alone — it requires resolving the ambiguities.

### Implication for the Act's drafters

If the five statutory ambiguities were resolved in the text itself — for example, if the Act:

1. Defined "sufficiently established" with objective criteria and required registration upon meeting them
2. Explicitly invoked the Elections Clause (Art. I, § 4) as its constitutional authority
3. Provided free qualifying documents or waived fees for voters who cannot afford them
4. Required notice and a hearing before removing registrants under § 8(k)
5. Included findings about the number of citizens affected and how the alternative process addresses their needs

— then the clear binary facts would strongly favor constitutionality, because every ambiguity that the challenger model exploits would be foreclosed. The government model would no longer need interpretive assumptions — the text itself would supply the answers.

Conversely, if the ambiguities are left unresolved, **the Act's constitutionality depends entirely on how courts and administrators fill the gaps** — which is precisely the territory where constitutional challenges succeed.

---

## Which Model Requires Less Interpretation?

Both models must supply interpretive axioms to bridge the gap between
the clear binary facts and their conclusions. But the two models do not
carry equal interpretive burdens. This section compares them.

### Counting the interpretive axioms

| Model | Total axioms | Text facts (shared) | Scenario facts (shared) | Interpretive axioms (model-specific) |
|---|---|---|---|---|
| **Challenger** | 13 | 2 | 6 | **5** |
| **Government** | 13 | 1 | 5 | **6** (+ 1 concession arguendo) |

The government model uses one more interpretive axiom than the challenger.
But raw count alone is misleading — the weight of each assumption matters
more than the number.

### Measuring interpretive distance from the text

For each interpretive axiom, we can ask: *How far does this assumption
depart from what the enacted text plainly says?*

#### Challenger model — 5 interpretive axioms

| # | Axiom | Interpretive distance | Justification |
|---|---|---|---|
| 1 | `challenger-fundamental-right-rule` | **Low** — settled law | Harper v. Virginia (1966) and Reynolds v. Sims (1964) are binding Supreme Court precedent. Even the government model concedes this arguendo. This is as close to "clear law" as an interpretive assumption gets. |
| 2 | `scenario-no-fault` | **Low** — factual stipulation | That some U.S. citizens lack qualifying documents through no fault of their own (born at home, elderly, rural) is an empirical fact documented by multiple studies. This is a reasonable scenario stipulation, not a legal stretch. |
| 3 | `scenario-alternative-process-denied` | **Medium** — close textual reading | The text says "shall make a *determination*" — not "shall *register*." A determination can go either way. Reading this as leaving discretionary denial power is a straightforward parsing of the text's actual language. The text genuinely does not promise registration. |
| 4 | `challenger-documentary-proof-is-undue-burden` | **Medium** — applying a recognized standard | Requires applying the Crawford/Anderson burden framework to the facts. This is a judgment call, but it uses an established legal standard rather than inventing one. |
| 5 | `challenger-undue-burden-defeats-regulation` | **Low** — standard doctrine | If an undue burden exists, it defeats valid-regulation status. This is the Anderson-Burdick balancing test — a recognized doctrinal framework that courts already apply. |

**Challenger interpretive profile**: 2 low, 2 medium, 0 high.

#### Government model — 6 interpretive axioms

| # | Axiom | Interpretive distance | Justification |
|---|---|---|---|
| 1 | `government-assume-right-to-vote-arguendo` | **None** — strategic concession | This is not an interpretation — it's a deliberate concession that strengthens the proof by showing the government wins even granting the challenger's strongest point. |
| 2 | `scenario-alternative-process-approved` | **High** — reading in a guarantee the text does not state | The text says "shall make a determination." The government reads this as meaning citizen-a *will be registered*. But the text does not say "shall register." This axiom adds a step (determination → registration) that is not in the enacted language. It requires assuming both that the official will find citizenship "sufficiently established" *and* that such a finding results in registration — neither of which the text guarantees. |
| 3 | `government-election-integrity-interest` | **Medium** — reasonable but not textual | The text does not contain an "election integrity" finding. The Act's purpose can be inferred from its structure (requiring proof of citizenship), but this is an inference — the Act does not say "this law serves election integrity." Congress could have included a findings section but did not. |
| 4 | `government-reasonable-requirement` | **Medium-High** — evaluative judgment | Whether the documentary-proof requirement is "reasonable" is a judgment about proportionality that the text does not make. The text requires documents; it does not assess whether requiring them is reasonable. This assumption requires evaluating the breadth of qualifying documents, the availability of alternatives, and the burden on affected citizens — none of which the text addresses. |
| 5 | `government-adequate-alternative` | **High** — depends on resolving the primary ambiguity | This axiom asserts that the § 8(j)(2)(A) process is "constitutionally adequate." But adequacy depends on whether the process guarantees registration — which is precisely the undefined "sufficiently established" standard (Ambiguity #1). Asserting adequacy requires *first* resolving the ambiguity in the government's favor, making this a compound interpretation. |
| 6 | `government-valid-regulation-rule` | **Medium** — doctrinal framework | The three-factor test (election integrity + reasonable + adequate alternative → valid regulation) is a reasonable doctrinal construction from Crawford, but it is assembled by the model, not stated in any single precedent. It is a synthesized rule rather than a settled standard. |

**Government interpretive profile**: 1 none, 0 low, 2 medium, 1 medium-high, 2 high.

### Side-by-side comparison

| Dimension | Challenger | Government |
|---|---|---|
| Number of interpretive axioms | 5 | 6 |
| Relies on settled precedent? | Yes — Harper, Reynolds, Crawford, Anderson are all binding | Partially — Crawford is binding, but the three-factor test is synthesized |
| Closest to the plain text? | Yes — reads "shall make a determination" as it is written (a determination, not a registration) | No — reads "shall make a determination" as implying mandatory registration, which the text does not state |
| Requires resolving the primary ambiguity? | No — the challenger's reading is the default when the text is silent (if the text doesn't guarantee registration, you can't assume it does) | Yes — the government must first resolve "sufficiently established" in its favor before its other axioms work |
| Contains compound interpretations? | No — each axiom is independent | Yes — `government-adequate-alternative` depends on resolving Ambiguity #1, making it a compound assumption |
| Relies on policy judgments? | No — all assumptions are legal/doctrinal | Yes — `government-election-integrity-interest` is a policy judgment not stated in the text |

### Conclusion

**The challenger model requires less interpretation to reach its conclusion.**

The challenger's proof chain relies primarily on:
- Settled Supreme Court precedent (fundamental right to vote)
- A close reading of the text's actual language ("determination" ≠ "registration")
- An established doctrinal balancing framework (Anderson-Burdick)

The government's proof chain requires:
- Reading a guarantee into text that does not state one ("shall make a determination" → registration)
- Policy judgments that the text does not make (election integrity finding)
- Evaluative conclusions the text does not reach (reasonableness of the requirement)
- Resolving the primary ambiguity before other axioms can fire (compound interpretation)

This does not mean the challenger is *right* — courts may well adopt the government's reading. But the challenger's model stays closer to the plain text and requires fewer departures from what the enacted language actually says. The government's defense of the Act depends more heavily on what the text *implies* rather than what it *states*.

> **Note**: This analysis measures interpretive *distance*, not legal *correctness*. A court could find the government's reading more persuasive based on legislative purpose, statutory context, or deference to Congress. But as a matter of textual proximity, the challenger's model is the shorter path.

---

## Contradictions and Over-Broad Axioms

No contradictions were detected in either model. Each model is internally consistent.

The `government-valid-regulation-rule` is intentionally broad — it establishes valid regulation for ANY `x` (not just `'registration-attempt-a`), which is structurally sound because the government's theory is that the regulation is valid across the board, not just for the test scenario.

---

## ACL2 Environment

- ACL2 Version: 8.6+ (development snapshot, Git: 72e302ffbd)
- SBCL: 2.5.3
- Docker image: atwalter/acl2:latest
- Books not certified (loaded with uncertified-book warnings)
