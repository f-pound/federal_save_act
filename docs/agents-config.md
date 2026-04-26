# agents-config.md — Federal SAVE Act Project Configuration

## Project identity

| Field | Value |
|---|---|
| Slug | `federal_save_act` |
| Jurisdiction | Federal (United States) |
| Bill | H.R. 22, Safeguard American Voter Eligibility Act, 119th Congress, 1st Session |
| Sponsor | Rep. Chip Roy (R-TX-21) |
| Effective date | Upon enactment (§ 8); not yet enacted as of April 2026 |
| Defense label | `government` |

## Source documents

```json
{
  "slug": "federal_save_act",
  "jurisdiction": "Federal",
  "source_documents": [
    {
      "id": "federal_save_act_source",
      "type": "bill",
      "authority": "U.S. House of Representatives, 119th Congress",
      "path_or_url": "federal_save_act_bill_text.txt",
      "status": "passed_house",
      "notes": "Engrossed in House (EH) version, BILLS-119hr22eh. Passed House 220-208 on April 10, 2025; pending in Senate. EH text is substantively identical to Introduced (IH) version."
    }
  ],
  "constitutional_references": [
    {
      "id": "voter_qualifications_house",
      "type": "constitution",
      "authority": "U.S. Constitution",
      "section": "Article I, Section 2, Clause 1",
      "path_or_url": "constitutional_language.txt",
      "notes": "Voter qualifications for House elections set by state law. Relevant to whether SAVE Act regulates manner (Art I §4) or qualifications (Art I §2)."
    },
    {
      "id": "elections_clause",
      "type": "constitution",
      "authority": "U.S. Constitution",
      "section": "Article I, Section 4, Clause 1",
      "path_or_url": "constitutional_language.txt"
    },
    {
      "id": "fifth_amendment_equal_protection",
      "type": "constitution",
      "authority": "U.S. Constitution",
      "section": "Amendment V (equal protection component)",
      "path_or_url": "constitutional_language.txt",
      "notes": "Federal equal protection claims are brought under the Fifth Amendment, not the Fourteenth (which constrains only state action). See Bolling v. Sharpe, 347 U.S. 497 (1954)."
    },
    {
      "id": "fourteenth_amendment_citizenship",
      "type": "constitution",
      "authority": "U.S. Constitution",
      "section": "Amendment XIV, Section 1",
      "path_or_url": "constitutional_language.txt",
      "notes": "Defines U.S. citizenship; source doctrine for equal protection principles; constrains state action only."
    },
    {
      "id": "voter_qualifications_senate",
      "type": "constitution",
      "authority": "U.S. Constitution",
      "section": "Amendment XVII",
      "path_or_url": "constitutional_language.txt",
      "notes": "Voter qualifications for Senate elections set by state law. Parallel to Art I §2 for House."
    },
    {
      "id": "poll_tax_prohibition",
      "type": "constitution",
      "authority": "U.S. Constitution",
      "section": "Amendment XXIV, Section 1",
      "path_or_url": "constitutional_language.txt"
    }
  ],
  "statutory_baseline": [
    {
      "id": "nvra",
      "type": "statute",
      "authority": "U.S. Congress",
      "section": "52 U.S.C. §§ 20501-20511",
      "notes": "The National Voter Registration Act is the statutory baseline that the SAVE Act amends. It is NOT a constitutional provision. Before the SAVE Act, the NVRA (as interpreted in Arizona v. ITCA) prohibited states from requiring documentary proof of citizenship for federal voter registration."
    }
  ]
}
```

## ACE / APE configuration

ACE output file: `data/parsed/federal_save_act_ace.json`

### APE checker

Preferred method: Local APE command if installed.

```
ape.exe -text "<ACE statement>"
```

Fallback method: Dockerized APE wrapper if available.

```
docker run --rm attempto/ape ape -text "<ACE statement>"
```

If APE is unavailable:
- Set `ape_status` to `NOT_RUN`.
- Set `requires_human_review` to true.
- Continue generating draft ACE statements, but do not mark them as validated.

### ACE normalization examples

**Source text** (§ 4(b) — documentary proof requirement):

> Under any method of voter registration in a State, the State shall not accept and process an application to register to vote in an election for Federal office unless the applicant presents documentary proof of United States citizenship with the application.

**ACE output**:

- If a person submits a voter-registration-application for a federal-election and the person does not present documentary-proof-of-citizenship with the voter-registration-application then the State does not accept the voter-registration-application.

**Human review flags**:
- "any method of voter registration" — scope of coverage requires legal interpretation.
- "presents ... with the application" — timing and form of presentation may vary.

---

**Source text** (§ 8(j)(2)(A)(i) — alternative process):

> each State shall establish a process under which an applicant who cannot provide documentary proof of United States citizenship under paragraph (1) may, if the applicant signs an attestation under penalty of perjury that the applicant is a citizen of the United States and eligible to vote in elections for Federal office, submit such other evidence to the appropriate State or local official demonstrating that the applicant is a citizen of the United States and such official shall make a determination as to whether the applicant has sufficiently established United States citizenship

**ACE output**:

- If a person cannot provide documentary-proof-of-citizenship and the person signs an attestation-under-perjury that the person is a citizen-of-the-United-States then the person may submit other-evidence to a State-or-local-official.
- If a person submits other-evidence to a State-or-local-official then the State-or-local-official determines whether the person has established citizenship.

**Human review flags**:
- "sufficiently established" — vague standard; discretionary determination (`UNKNOWN_OR_AMBIGUOUS`).
- Whether this process provides a constitutionally adequate alternative is interpretive.

## Constitutional provisions

### Article I, Section 2, Clause 1 (Voter Qualifications — House)

- **Textual interest**: Voter qualifications for the House are set by state law ("Qualifications requisite for Electors of the most numerous Branch of the State Legislature").
- **Structural principles**: This reserves voter *qualification* authority to the states, distinct from the *manner* regulation power in Art. I, § 4.
- **Key interpretive hinge**: Is a documentary-proof-of-citizenship requirement a regulation of the *manner* of holding elections (permissible under Art. I, § 4), or a regulation of voter *qualifications* (reserved to states under Art. I, § 2)?

### Article I, Section 4, Clause 1 (Elections Clause)

- **Textual interest**: Congress's power to regulate the "Times, Places and Manner" of federal elections.
- **Structural principles**: States have primary authority over election procedures; Congress has override power.
- **Key interpretive hinge**: Does "manner" include voter qualification procedures like documentary-proof requirements, or is voter qualification reserved to the States under Article I, § 2?

### Amendment V (Federal Equal Protection)

- **Textual interest**: No person shall be deprived of life, liberty, or property without due process of law.
- **Structural principles**: The Fifth Amendment's Due Process Clause is the source of federal equal protection. Challenges to federal legislation for violating equal protection are brought under the Fifth Amendment, NOT the Fourteenth (which constrains only state action). See Bolling v. Sharpe, 347 U.S. 497 (1954).
- **Key interpretive hinge**: Does the documentary-proof requirement impose a disparate burden on eligible citizens who lack qualifying documents?

### Amendment XIV, Section 1 (Citizenship Definition; State Equal Protection)

- **Textual interest**: Defines U.S. citizenship ("born or naturalized in the United States"). Equal Protection and Due Process Clauses constrain *state* action.
- **Structural principles**: Source doctrine for equal protection principles applied to the federal government via the Fifth Amendment. Also defines the citizenship status relevant to voter qualification.
- **Key interpretive hinge**: Not directly operative against the SAVE Act (which is federal legislation), but provides the doctrinal foundation.

### Amendment XVII (Voter Qualifications — Senate)

- **Textual interest**: Senate voter qualifications are set by state law, paralleling Art. I, § 2.
- **Structural principles**: Reinforces state authority over voter qualifications for both chambers.

### Amendment XXIV, Section 1 (Poll Tax Prohibition)

- **Textual interest**: Right to vote shall not be denied by failure to pay any tax.
- **Structural principles**: Extends to primary and general elections for federal office.
- **Key interpretive hinge**: If obtaining documentary proof requires paying fees (e.g., for a birth certificate or passport), does the requirement function as a de facto poll tax?

### Statutory Baseline: NVRA (52 U.S.C. §§ 20501–20511)

- **Status**: Federal statute (NOT a constitutional provision).
- **Role**: The NVRA is the statutory baseline that the SAVE Act amends. Before the SAVE Act, the NVRA (as interpreted in *Arizona v. Inter Tribal Council*, 570 U.S. 1 (2013)) prohibited states from requiring documentary proof of citizenship for federal voter registration.
- **Key interpretive hinge**: The SAVE Act reverses this statutory default. Whether Congress can impose what states cannot under the NVRA as originally enacted is a question of Elections Clause authority.

## Numeric threshold boundary

- **30-day deadline**: States must establish a noncitizen identification program within 30 days of enactment (§ 8(j)(3)). This is a `TEXT_FACT`.
- **24-hour response time**: Federal agencies must respond to state verification requests within 24 hours (§ 8(j)(5)(A)). This is a `TEXT_FACT`.
- **60-day adoption deadline**: Exempt states must adopt identical requirements at least 60 days before the first federal election after enactment (§ 4(d)). This is a `TEXT_FACT`.
- **10-day EAC guidance deadline**: EAC must issue guidance within 10 days of enactment (§ 3). This is a `TEXT_FACT`.

Whether these deadlines are reasonable, adequate, or burdensome is interpretive.

## Predicate examples

```json
{
  "label": "PROHIBITION",
  "source_ref": "SAVE Act § 4(b) / NVRA § 8(j)(1)",
  "predicate": "(statute-denies-registrationp 'federal-save-act p x)",
  "condition": "(and (personp p) (voter-registration-applicationp x) (attempts-to-registerp p x) (not (has-documentary-proofp p)) (not (alternative-process-approvedp p x)))",
  "confidence": 0.95,
  "requires_human_review": false
}
```

## Interpretive hinges

| Hinge | Challenger Position | Government Position |
|---|---|---|
| Does "manner" include documentary-proof requirements? | No — voter qualifications are reserved to states; Congress exceeded Elections Clause authority | Yes — Congress has broad power to regulate the manner of federal elections |
| Does the requirement burden eligible citizens? | Yes — millions of citizens lack qualifying documents; disparate impact on elderly, low-income, minority, rural, and Native American voters | No — the requirement is reasonable; alternative process exists; documents are widely available |
| Is the alternative process (§ 8(j)(2)(A)) adequate? | No — it depends on discretionary official judgment; no guaranteed right to register. The text says officials "shall make a determination" but does not say they "shall register" the applicant. "Sufficiently established" is undefined, giving officials discretionary denial power over eligible citizens. | Yes — it provides a safety valve for citizens without standard documents. Officials "shall" make a determination, which means they must evaluate the evidence. The EAC affidavit and minimum standards constrain official discretion. |
| Does the cost of obtaining documents create a de facto poll tax? | Yes — birth certificates and passports cost money; functionally equivalent to a tax on voting | No — the documents serve other purposes; cost is incidental, not a tax |
| Does the removal process (§ 8(k)) satisfy due process? | No — allows removal based on "verified information" without adequate notice or hearing | Yes — existing NVRA protections apply; removal is based on documentary proof |

## Workflow commands

```powershell
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_challenger_model.lisp"
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_government_model.lisp"
```
