# Federal SAVE Act — Constitutional ACL2 Stress Test

Formal constitutional stress-test of the Safeguard American Voter Eligibility Act (H.R. 22, 119th Congress), which requires documentary proof of U.S. citizenship to register to vote in federal elections.

This project uses the [AGENTS.md](../AGENTS.md) framework to separate text-derived statutory facts from interpretive assumptions, then runs competing ACL2 proof obligations to identify which assumptions control the constitutional outcome.

## Quick Start

```powershell
# Run challenger proof (expects constitutional conflict)
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_challenger_model.lisp"

# Run government proof (expects no conflict)
cmd /c "docker compose run --rm acl2 acl2 < federal_save_act_government_model.lisp"
```

> **Important**: Never load both models in the same ACL2 session. They derive opposite conclusions and are intentionally incompatible.

## Results

| Model | Theorem | Result | Steps |
|---|---|---|---|
| Challenger | `challenger-model-finds-conflict` | ✅ Q.E.D. | 144 |
| Government | `government-model-no-conflict` | ✅ Q.E.D. | 117 |

**Primary interpretive hinge**: Whether the alternative attestation process (§ 8(j)(2)(A)) provides a constitutionally adequate safety valve for eligible citizens who lack standard documentary proof of citizenship.

## Project Structure

```
federal_save_act/
├── README.md                           # This file
├── Overview.md                         # Full analysis report
├── agents-config.md                    # Project configuration
├── constitutional_language.txt         # U.S. Constitution provisions
├── federal_save_act_bill_text.txt      # H.R. 22 full text
├── federal_save_act_core.lisp          # Neutral vocabulary
├── federal_save_act_facts.lisp         # Text-derived facts only
├── federal_save_act_challenger_model.lisp   # Challenge-side model
├── federal_save_act_government_model.lisp   # Government defense model
├── docker-compose.yml                  # ACL2 Docker config
├── data/
│   └── parsed/
│       ├── federal_save_act.json           # Parsed bill sections
│       ├── federal_save_act_predicates.json # Normalized predicates
│       └── federal_save_act_ace.json       # ACE-normalized clauses
└── reports/
    └── federal_save_act_proof_obligations.md  # Proof results
```

## Scenario

- **citizen-a**: An elderly U.S. citizen born at home in a rural area, who lacks a REAL ID, passport, birth certificate, or other qualifying document under the SAVE Act
- **registration-attempt-a**: A mail voter registration application for a federal election

## Constitutional Provisions

- U.S. Constitution, Article I, § 4 (Elections Clause)
- Fourteenth Amendment, § 1 (Equal Protection / Due Process)
- Twenty-Fourth Amendment, § 1 (Poll Tax Prohibition)

## Framework

This project follows the [AGENTS.md](../AGENTS.md) constitutional stress-test framework. See [templates/NEW_PROJECT_PROMPT.md](../templates/NEW_PROJECT_PROMPT.md) for instructions on bootstrapping new stress tests.

## License

This is a legal analysis tool, not legal advice. The ACL2 models do not decide constitutionality — they identify the proof obligations and assumptions needed to prove either a constitutional conflict or no conflict under competing interpretive models.
