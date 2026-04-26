# Federal SAVE Act — Constitutional ACL2 Stress Test (v5.2)

## Question Presented

Does the Safeguard American Voter Eligibility Act (H.R. 22), which requires documentary proof of United States citizenship to register to vote in federal elections, unconstitutionally burden the right to vote of eligible citizens who lack qualifying documents?

## Sources

| Document | Type | Authority | Status |
|---|---|---|---|
| `federal_save_act_bill_text.txt` | Bill (EH) | U.S. House of Representatives, 119th Congress | Passed House 220-208 (Apr 10, 2025); pending in Senate |
| `constitutional_language.txt` | Constitution | U.S. Constitution | Art. I §2; Art. I §4; Amend. V; Amend. XIV §1; Amend. XVII; Amend. XXIV §1 |

> **Version note**: This analysis uses the Engrossed in House (EH) text, BILLS-119hr22eh, which is the official text as passed by the House. The EH text is substantively identical to the Introduced (IH) version — no floor amendments altered the operative statutory language.

- **Jurisdiction**: Federal (United States)
- **Sponsor**: Rep. Chip Roy (R-TX-21)
- **Session**: 119th Congress, 1st Session
- **Effective Date**: Upon enactment (§ 8); not yet enacted as of April 2026

## Boundary Between Facts and Interpretation

### Text-Derived Facts (`federal_save_act_facts.lisp`)

The facts file contains **only** rules extracted directly from the SAVE Act text:

1. **TEXT_FACT**: The SAVE Act is a law (`text-save-act-is-law`)
2. **PROHIBITION**: States may not register voters who lack documentary proof of citizenship and are not approved through the alternative process (`text-save-act-documentary-proof-requirement`)
3. **BRIDGE_RULE**: A person has documentary proof if they possess any qualifying document from the statutory list (`text-documentary-proof-from-qualifying-documents`)

### Interpretive Assumptions (Separate Model Files)

The challenger and government models contain assumptions about constitutional meaning, doctrine, and policy. These are **intentionally separated** from the facts file and clearly labeled per the AGENTS.md boundary rules.

## Key Constitutional Hinge

The central question is: **Does the alternative attestation process (§ 8(j)(2)(A)) guarantee registration for eligible citizens whose citizenship is sufficiently established, or does it leave officials with discretionary denial power?**

The text says officials "shall make a determination as to whether the applicant has sufficiently established United States citizenship." But it does not say officials "shall register" the applicant once citizenship is established. The standard — "sufficiently established" — is undefined. This gap is the primary interpretive hinge:

- If "shall make a determination" means the official must register an applicant whose citizenship is adequately shown, the process is a genuine safety valve and the government's defense succeeds.
- If "shall make a determination" merely requires the official to consider the evidence but leaves discretion to deny registration, the process does not cure the constitutional burden and the challenger's theory succeeds.

### Constitutional Provisions Implicated

| Provision | Role |
|---|---|
| **Art. I, § 2** | Reserves voter *qualification* authority to the states |
| **Art. I, § 4** (Elections Clause) | Grants Congress power over the *manner* of federal elections |
| **Amend. V** (equal protection component) | Operative constitutional hook for challenging federal legislation for unequal treatment. See Bolling v. Sharpe, 347 U.S. 497 (1954) |
| **Amend. XIV, § 1** | Defines U.S. citizenship; source doctrine for equal protection principles; constrains *state* action only |
| **Amend. XVII** | Reinforces state authority over voter qualifications for Senate |
| **Amend. XXIV** | Prohibits poll taxes in federal elections |

> **Note on equal protection**: The SAVE Act is federal legislation. Equal protection challenges to federal action are brought under the **Fifth Amendment**, not the Fourteenth Amendment (which constrains only state action). The Fourteenth Amendment is the doctrinal source but not the operative hook.

> **Note on NVRA**: The National Voter Registration Act (52 U.S.C. §§ 20501–20511) is the **statutory baseline** that the SAVE Act amends. It is not a constitutional provision. Before the SAVE Act, the NVRA (as interpreted in *Arizona v. ITCA*, 570 U.S. 1 (2013)) prohibited states from requiring documentary proof of citizenship for federal voter registration. The SAVE Act reverses this statutory default.

### Interpretive Hinges

| Hinge | Challenger Position | Government Position |
|---|---|---|
| Is voting a fundamental right? | Yes — Harper, Reynolds establish this | Conceded arguendo |
| Does the doc-proof requirement burden eligible citizens? | Yes — millions lack qualifying documents through no fault | No — documents are widely available; requirement applies equally |
| Does the alternative process guarantee registration or leave discretion? | It leaves discretion — "sufficiently established" is undefined; officials can deny registration even after attestation | It guarantees a path — officials "shall" determine citizenship; EAC standards and affidavit constrain discretion |
| Is this a "manner" regulation or a "qualification" regulation? | Qualification — Art. I, § 2 reserves voter qualifications to states; Congress exceeded Elections Clause authority | Manner — Congress has broad power to regulate the manner of federal elections, including registration procedures |
| Does the cost of documents create a de facto poll tax? | Yes — functionally equivalent to a tax on voting | No — incidental cost for documents with multiple uses |

## Statutory Structure

### Definitions (§ 2(a) / NVRA § 3(b))

**Documentary proof of United States citizenship** — any of:
1. REAL ID indicating citizenship
2. Valid U.S. passport
3. Military ID + birth record showing U.S. birth
4. Government photo ID showing U.S. birth
5. Government photo ID + supporting document (birth certificate, naturalization certificate, adoption decree, Consular Report of Birth Abroad, hospital birth record, American Indian Card KIC)

### Prohibitions

1. **Primary prohibition** (§ 2(b) / NVRA § 4(b); § 2(f) / NVRA § 8(j)(1)): States shall not accept voter registration applications without documentary proof of citizenship
2. **Mail registration** (§ 2(d) / NVRA § 6(e)): Mail registrants must present documentary proof in person before the registration deadline
3. **Noncitizen removal** (§ 2(f) / NVRA § 8(k)): States shall remove noncitizens from voter rolls upon receipt of verified information

### Exceptions

1. **Alternative attestation process** (§ 2(f) / NVRA § 8(j)(2)(A)): Applicants who cannot provide documentary proof may sign an attestation under penalty of perjury and submit other evidence; a state/local official determines citizenship
2. **Provisional ballots** (§ 6): Nothing in the Act restricts provisional ballots; ballot is counted if citizenship is later verified
3. **State exemptions** (§ 2(k)): Certain states may adopt identical requirements independently

### Penalties

1. **Criminal penalties for officials** (§ 2(j) / NVRA § 12(2)(B)-(C)):
   - Executive branch officers who provide material assistance to noncitizens attempting to register
   - Officials who register applicants without documentary proof
2. **Private right of action** (§ 2(i)): Against officials who register applicants without proof

## ACL2 Files (v3 — Encapsulate Architecture)

| File | Role | Mechanism | Label |
|---|---|---|---|
| `federal_save_act_core.lisp` | Neutral vocabulary, factored intermediate predicates | `defstub` + `defun` | Neutral |
| `federal_save_act_facts.lisp` | Text-derived prohibition and bridge rules | `defaxiom` | TEXT_FACT, PROHIBITION, BRIDGE_RULE |
| `federal_save_act_challenger_model.lisp` | Assumptions proving constitutional conflict | `encapsulate` + witness | INTERPRETATION_CHALLENGER |
| `federal_save_act_government_model.lisp` | Assumptions defeating constitutional conflict | `encapsulate` + witness | INTERPRETATION_GOVERNMENT |
| `federal_save_act_consistency_check.lisp` | Core vocabulary sanity verification | `defthm` | Structural |

> **Architecture note**: The project uses a hybrid architecture (introduced in v3, extended in v5.2). Interpretive predicates and doctrinal standards use `encapsulate` with local witness functions (consistency-checked). Text-derived facts and scenario ground truths use `defaxiom` (self-evidently consistent constraints on `defstub` functions). Derived burden conclusions use executable `defun` chains. See [RIGOR_NOTES_V3.md](RIGOR_NOTES_V3.md) for the original v3 rationale and `reports/v5_2_acl2_proof_assessment.md` for v5.2 metrics.

## Model Separation

> **Important**: The challenger and government models must NEVER be loaded in the same ACL2 session. They derive opposite conclusions and are intentionally incompatible.

## ACL2 Proof Results

> **v5.2 certification results**: All 17 books pass ACL2 certification via Docker (`atwalter/acl2:latest`). 126 total theorems, all Q.E.D. See `reports/v5_2_acl2_proof_assessment.md` for the full event census.

### Challenger Model

**Expected result**: Q.E.D. for both `challenger-conflict-general` and `challenger-model-finds-conflict`

The challenger model proves that a constitutional conflict exists under these assumptions:
- The right to vote is fundamental (Harper v. Virginia, Reynolds v. Sims)
- The documentary proof requirement unduly burdens eligible citizens who lack qualifying documents through no fault and cannot obtain them without material burden
- The alternative process is discretionary, creating severe burden and substantial risk of erroneous denial
- The undue burden defeats the regulation's validity

**Proof chain** (factored through intermediate predicates):
`challenger-fundamental-right-rule` → `challenger-lack-of-docs-implies-severity` → `challenger-documentary-proof-is-undue-burden` → `challenger-undue-burden-defeats-regulation` → `challenger-conflict-general` → `challenger-model-finds-conflict` (corollary)

**Assumptions** (encapsulate-backed):

| # | Constraint | Label | What it does |
|---|---|---|---|
| 1 | `challenger-scenario-person` | SCENARIO_FACT | citizen-a is a person |
| 2 | `challenger-scenario-citizen` | SCENARIO_FACT | citizen-a is a U.S. citizen |
| 3 | `challenger-scenario-eligible` | SCENARIO_FACT | citizen-a is eligible to vote |
| 4 | `challenger-scenario-application` | SCENARIO_FACT | registration-attempt-a is a voter reg application |
| 5 | `challenger-scenario-attempts-to-register` | SCENARIO_FACT | citizen-a attempts to register |
| 6 | `challenger-scenario-no-documentary-proof` | SCENARIO_FACT | citizen-a lacks documentary proof |
| 7 | `challenger-scenario-no-presentation` | SCENARIO_FACT | citizen-a does not present proof |
| 8 | `challenger-scenario-no-fault` | INTERPRETATION_CHALLENGER | citizen-a lacks documents through no fault |
| 9 | `challenger-scenario-material-burden` | INTERPRETATION_CHALLENGER | citizen-a cannot obtain documents without material burden (v3 new) |
| 10 | `challenger-scenario-process-discretionary` | INTERPRETATION_CHALLENGER | alternative process is discretionary for citizen-a (v3 new) |
| 11 | `challenger-scenario-alternative-process-denied` | INTERPRETATION_CHALLENGER | alternative process does not guarantee registration |
| 12 | `challenger-fundamental-right-rule` | DOCTRINAL_ASSUMPTION | voting is a fundamental right (Harper, Reynolds) |
| 13 | `challenger-lack-of-docs-implies-severity` | INTERPRETATION_CHALLENGER | lack of docs + material burden + discretion → severe burden + risk (v3 new) |
| 14 | `challenger-documentary-proof-is-undue-burden` | INTERPRETATION_CHALLENGER | doc-proof requirement unduly burdens citizens without documents |
| 15 | `challenger-undue-burden-defeats-regulation` | INTERPRETATION_CHALLENGER | undue burden + severity + risk defeats valid-regulation status (v3 expanded) |
| 16 | `text-save-act-is-law` | TEXT_FACT | the SAVE Act is a law (from facts file) |
| 17 | `text-save-act-documentary-proof-requirement` | PROHIBITION | registration denied without proof + no alternative (from facts file) |

### Government Model

**Expected result**: Q.E.D. for both `government-no-conflict-general` and `government-model-no-conflict`

The government model proves that **no** constitutional conflict exists under these assumptions:
- The SAVE Act serves an important election integrity interest
- The documentary proof requirement is reasonable, evenhanded, and rationally connected
- The alternative attestation process is constitutionally adequate
- Therefore the SAVE Act is a valid regulation

**Proof chain** (5-factor Anderson-Burdick / Crawford rule):
`government-important-interest` + `government-election-integrity-interest` + `government-reasonable-requirement` + `government-procedure-evenhanded` + `government-rationally-connected` + `government-adequate-alternative` → `government-valid-regulation-rule` → `government-no-conflict-general` → `government-model-no-conflict` (corollary)

**Note**: The government model defeats the conflict through **two independent paths**:
1. The regulation is valid (valid-regulationp is true)
2. Registration is not denied (alternative process approved for citizen-a)

**Assumptions** (encapsulate-backed):

| # | Constraint | Label | What it does |
|---|---|---|---|
| 1 | `government-scenario-person` | SCENARIO_FACT | citizen-a is a person |
| 2 | `government-scenario-citizen` | SCENARIO_FACT | citizen-a is a U.S. citizen |
| 3 | `government-scenario-eligible` | SCENARIO_FACT | citizen-a is eligible to vote |
| 4 | `government-scenario-application` | SCENARIO_FACT | registration-attempt-a is a voter reg application |
| 5 | `government-scenario-attempts-to-register` | SCENARIO_FACT | citizen-a attempts to register |
| 6 | `government-scenario-no-documentary-proof` | SCENARIO_FACT | citizen-a lacks documentary proof |
| 7 | `government-assume-right-to-vote-arguendo` | INTERPRETATION_GOVERNMENT | concedes right to vote arguendo |
| 8 | `government-scenario-alternative-process-approved` | INTERPRETATION_GOVERNMENT | alternative process approves citizen-a |
| 9 | `government-important-interest` | POLICY_ASSUMPTION | government interest is important (v3 new) |
| 10 | `government-election-integrity-interest` | POLICY_ASSUMPTION | SAVE Act serves election integrity |
| 11 | `government-reasonable-requirement` | INTERPRETATION_GOVERNMENT | documentary proof is reasonable |
| 12 | `government-procedure-evenhanded` | INTERPRETATION_GOVERNMENT | procedure applies equally (v3 new) |
| 13 | `government-rationally-connected` | INTERPRETATION_GOVERNMENT | requirement rationally connected to interest (v3 new) |
| 14 | `government-adequate-alternative` | INTERPRETATION_GOVERNMENT | § 8(j)(2)(A) process is adequate |
| 15 | `government-burden-not-severe` | INTERPRETATION_GOVERNMENT | burden is not severe (v3 new) |
| 16 | `government-valid-regulation-rule` | INTERPRETATION_GOVERNMENT | valid regulation if 6-factor test met (v3 expanded) |
| 17 | `text-save-act-is-law` | TEXT_FACT | the SAVE Act is a law (from facts file) |

## What the System Can and Cannot Conclude

### What it demonstrates

1. **Both models are internally consistent** — no contradictions in either model
2. **Both proof obligations succeed** — the conflict and no-conflict results follow logically from the respective assumptions
3. **The outcome depends entirely on interpretive assumptions** — specifically, on whether the alternative attestation process is adequate and whether the documentary proof requirement imposes an undue burden
4. **The primary interpretive hinge is the adequacy of § 8(j)(2)(A)** — if the alternative process guarantees registration for eligible citizens, no conflict exists under the government model; if it is discretionary, a conflict exists under the challenger model

### What it cannot decide

1. Whether the right to vote is "fundamental" in the doctrinal sense (this is settled law under Harper, but the weight of that precedent is not something the model resolves)
2. Whether the alternative attestation process is genuinely discretionary or provides a guaranteed path — this is a question of statutory interpretation and administrative practice
3. The empirical question of how many eligible citizens lack qualifying documents
4. Whether the cost of obtaining documents constitutes a de facto poll tax under the Twenty-Fourth Amendment
5. The federalism question of whether Congress can impose documentary proof requirements that states cannot impose under NVRA/ITCA
6. Whether the noncitizen removal process (§ 8(k)) satisfies procedural due process

### Assumptions controlling the outcome

| Assumption | Controls | Model |
|---|---|---|
| The right to vote is fundamental | Whether the right triggers heightened scrutiny | Challenger |
| Documentary proof imposes an undue burden | Whether the requirement is constitutionally infirm | Challenger |
| The alternative process is discretionary (not guaranteed) | Whether citizen-a can register despite lacking documents | Challenger |
| The SAVE Act serves election integrity | Whether the government interest is sufficient | Government |
| The requirement is reasonable | Whether the means are proportional to the interest | Government |
| The alternative process guarantees a path to registration | Whether the safety valve cures any burden | Government |

## Proof Obligations

See `reports/federal_save_act_proof_obligations.md` for detailed proof results.

## Limits

This system does not decide constitutionality. It identifies the assumptions necessary to prove conflict or no conflict under competing interpretive models.

**Limitations**: The encapsulate witnesses are vacuously true for some constraints (the hypothesis is false under the default defstub interpretation). This is logically valid but represents a weaker consistency guarantee than a constructive witness. See [RIGOR_NOTES_V3.md](RIGOR_NOTES_V3.md) for details.

## Interpreting the Output

The SAVE Act stress test reveals that the constitutional question reduces to a factual and interpretive dispute about the **alternative attestation process**.

The question in plain terms: **Does § 8(j)(2)(A) guarantee registration for eligible citizens whose citizenship is sufficiently established, or does it leave officials with discretionary denial power?**

- The text says officials "shall make a determination" — but "determination" is not "registration." An official could "determine" that citizenship was not "sufficiently established" and deny registration even to an actual citizen.
- "Sufficiently established" is an undefined standard. The EAC must develop "minimum standards," but the Act does not specify what those standards are or guarantee that an applicant who meets them will be registered.

This maps directly to the analytical framework of *Crawford v. Marion County Election Board* (2008), where the plurality balanced the state's interest in election integrity against the burden on voters. The SAVE Act presents a stronger government interest (federal authority under the Elections Clause) but also a potentially broader burden (documentary proof of citizenship, not merely photo ID).

**The model cannot resolve this factual question — it can only show that the legal outcome turns on it.**
