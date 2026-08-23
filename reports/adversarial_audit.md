# Adversarial audit of the party trusted bases

For each axiom A: flip exactly one stub value so A is false, and check whether every OTHER axiom of the theory still holds (complete finite-model check over the audit worlds). **independent** = the flipped world is a model of the rest ∧ ¬A. **coupled** = the flip also falsifies the listed axioms — these clusters are the theory's load-bearing joints (hinges). **ACL2 redundancy** = one ACL2 session per axiom attempts to prove A from the others; a success is a kernel-checked certificate that A is deletable.

## Challenger theory — 44 axioms: 43 independent, 1 coupled, 0 no single-stub flip

| Axiom | Verdict | Flip used | Breaks | ACL2 redundancy |
|---|---|---|---|---|
| `text-save-act-documentary-proof-requirement` | **independent** | `attempts-to-registerp['citizen-b', 'registration-attempt-a'] := t` | — | not provable from the others within 8s |
| `text-save-act-removal-upon-verified-information` | **independent** | `statute-removes-registrantp['federal-save-act', 'citizen-b'] := nil` | — | not provable from the others within 8s |
| `text-photo-id-required-for-regular-ballot` | **independent** | `statute-denies-regular-ballotp['federal-save-act', 'citizen-c', 'ballot-c'] := nil` | — | not provable from the others within 8s |
| `text-save-act-is-law` | **independent** | `lawp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `text-documentary-proof-from-qualifying-documents` | **independent** | `has-govt-photo-id-showing-us-birthp['amend-v-equal-protection'] := t` | — | not provable from the others within 8s |
| `scenario-person` | **independent** | `personp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `scenario-citizen` | **independent** | `citizen-of-usp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `scenario-eligible` | **independent** | `eligible-voterp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `scenario-application` | **independent** | `voter-registration-applicationp['registration-attempt-a'] := nil` | — | not provable from the others within 8s |
| `scenario-attempts-to-register` | **independent** | `attempts-to-registerp['citizen-a', 'registration-attempt-a'] := nil` | — | not provable from the others within 8s |
| `scenario-no-documentary-proof` | **independent** | `has-documentary-proofp['citizen-a'] := t` | — | not provable from the others within 8s |
| `scenario-b-person` | **independent** | `personp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-citizen` | **independent** | `citizen-of-usp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-eligible` | **independent** | `eligible-voterp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-registered` | **independent** | `registered-voterp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-verified-noncitizen-information` | **independent** | `verified-noncitizen-informationp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-no-notice` | **independent** | `adequate-notice-before-removalp['citizen-b'] := t` | — | not provable from the others within 8s |
| `scenario-b-no-hearing` | **independent** | `opportunity-to-be-heardp['citizen-b'] := t` | — | not provable from the others within 8s |
| `scenario-c-person` | **independent** | `personp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-citizen` | **independent** | `citizen-of-usp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-eligible` | **independent** | `eligible-voterp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-registered` | **independent** | `registered-voterp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-ballot` | **independent** | `ballotp['ballot-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-votes-in-person` | **independent** | `votes-in-personp['citizen-c', 'ballot-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-no-valid-photo-id` | **independent** | `presents-valid-photo-idp['citizen-c', 'ballot-c'] := t` | — | not provable from the others within 8s |
| `scenario-c-no-cure` | **independent** | `cures-within-deadlinep['citizen-c', 'ballot-c'] := t` | — | not provable from the others within 8s |
| `scenario-d-person` | **independent** | `personp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-citizen` | **independent** | `citizen-of-usp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-eligible` | **independent** | `eligible-voterp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-registered` | **independent** | `registered-voterp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-ballot` | **independent** | `ballotp['ballot-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-votes-in-person` | **independent** | `votes-in-personp['citizen-d', 'ballot-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-no-valid-photo-id` | **independent** | `presents-valid-photo-idp['citizen-d', 'ballot-d'] := t` | — | not provable from the others within 8s |
| `scenario-d-cures` | **independent** | `cures-within-deadlinep['citizen-d', 'ballot-d'] := nil` | — | not provable from the others within 8s |
| `semantic-b-discretionary-denial` | **independent** | `alternative-process-approvedp['amend-v-equal-protection', 'amend-v-equal-protection'] := t` | — | not provable from the others within 8s |
| `challenger-bridge-right-to-vote` | **independent** | `challenger-right-to-vote-establishedp['amend-v-equal-protection'] := t` | — | not provable from the others within 8s |
| `challenger-bridge-regulation-invalid` | **independent** | `valid-regulationp['federal-save-act', 'registration-attempt-a'] := t` | — | not provable from the others within 8s |
| `challenger-scenario-no-presentation` | **independent** | `presents-documentary-proofp['citizen-a', 'registration-attempt-a'] := t` | — | not provable from the others within 8s |
| `challenger-scenario-no-fault` | **independent** | `lacks-qualifying-documents-through-no-faultp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `challenger-scenario-material-burden` | **independent** | `cannot-obtain-qualifying-documents-without-material-burdenp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `challenger-scenario-alternative-process-denied` | **coupled** | `alternative-process-approvedp['citizen-a', 'registration-attempt-a'] := t` | `semantic-b-discretionary-denial` | not provable from the others within 8s |
| `challenger-bridge-removal-invalid` | **independent** | `valid-regulationp['federal-save-act', 'citizen-b'] := t` | — | not provable from the others within 8s |
| `challenger-bridge-voting-invalid` | **independent** | `valid-regulationp['federal-save-act', 'ballot-c'] := t` | — | not provable from the others within 8s |
| `challenger-scenario-c-material-burden` | **independent** | `cannot-obtain-valid-photo-id-without-material-burdenp['citizen-c'] := nil` | — | not provable from the others within 8s |

## Government theory — 50 axioms: 49 independent, 1 coupled, 0 no single-stub flip

| Axiom | Verdict | Flip used | Breaks | ACL2 redundancy |
|---|---|---|---|---|
| `text-save-act-documentary-proof-requirement` | **independent** | `alternative-process-approvedp['citizen-b', 'registration-attempt-a'] := nil & attempts-to-registerp['citizen-b', 'registration-attempt-a'] := t` | — | not provable from the others within 8s |
| `text-save-act-removal-upon-verified-information` | **independent** | `statute-removes-registrantp['federal-save-act', 'citizen-b'] := nil` | — | not provable from the others within 8s |
| `text-photo-id-required-for-regular-ballot` | **independent** | `statute-denies-regular-ballotp['federal-save-act', 'citizen-c', 'ballot-c'] := nil` | — | not provable from the others within 8s |
| `text-save-act-is-law` | **independent** | `lawp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `text-documentary-proof-from-qualifying-documents` | **independent** | `has-govt-photo-id-showing-us-birthp['amend-v-equal-protection'] := t` | — | not provable from the others within 8s |
| `scenario-person` | **independent** | `personp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `scenario-citizen` | **independent** | `citizen-of-usp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `scenario-eligible` | **independent** | `eligible-voterp['citizen-a'] := nil` | — | not provable from the others within 8s |
| `scenario-application` | **independent** | `voter-registration-applicationp['registration-attempt-a'] := nil` | — | not provable from the others within 8s |
| `scenario-attempts-to-register` | **independent** | `attempts-to-registerp['citizen-a', 'registration-attempt-a'] := nil` | — | not provable from the others within 8s |
| `scenario-no-documentary-proof` | **independent** | `has-documentary-proofp['citizen-a'] := t` | — | not provable from the others within 8s |
| `scenario-b-person` | **independent** | `personp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-citizen` | **independent** | `citizen-of-usp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-eligible` | **independent** | `eligible-voterp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-registered` | **independent** | `registered-voterp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-verified-noncitizen-information` | **independent** | `verified-noncitizen-informationp['citizen-b'] := nil` | — | not provable from the others within 8s |
| `scenario-b-no-notice` | **independent** | `adequate-notice-before-removalp['citizen-b'] := t` | — | not provable from the others within 8s |
| `scenario-b-no-hearing` | **independent** | `opportunity-to-be-heardp['citizen-b'] := t` | — | not provable from the others within 8s |
| `scenario-c-person` | **independent** | `personp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-citizen` | **independent** | `citizen-of-usp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-eligible` | **independent** | `eligible-voterp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-registered` | **independent** | `registered-voterp['citizen-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-ballot` | **independent** | `ballotp['ballot-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-votes-in-person` | **independent** | `votes-in-personp['citizen-c', 'ballot-c'] := nil` | — | not provable from the others within 8s |
| `scenario-c-no-valid-photo-id` | **independent** | `presents-valid-photo-idp['citizen-c', 'ballot-c'] := t` | — | not provable from the others within 8s |
| `scenario-c-no-cure` | **independent** | `cures-within-deadlinep['citizen-c', 'ballot-c'] := t` | — | not provable from the others within 8s |
| `scenario-d-person` | **independent** | `personp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-citizen` | **independent** | `citizen-of-usp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-eligible` | **independent** | `eligible-voterp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-registered` | **independent** | `registered-voterp['citizen-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-ballot` | **independent** | `ballotp['ballot-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-votes-in-person` | **independent** | `votes-in-personp['citizen-d', 'ballot-d'] := nil` | — | not provable from the others within 8s |
| `scenario-d-no-valid-photo-id` | **independent** | `presents-valid-photo-idp['citizen-d', 'ballot-d'] := t` | — | not provable from the others within 8s |
| `scenario-d-cures` | **independent** | `cures-within-deadlinep['citizen-d', 'ballot-d'] := nil` | — | not provable from the others within 8s |
| `semantic-a-mandatory-approval` | **independent** | `alternative-process-approvedp['citizen-a', 'amend-v-equal-protection'] := nil & attestation-evidence-satisfies-standardsp['citizen-a', 'amend-v-equal-protection'] := t` | — | not provable from the others within 8s |
| `government-bridge-defense-validates` | **independent** | `valid-regulationp['amend-v-equal-protection', 'registration-attempt-a'] := nil` | — | not provable from the others within 8s |
| `government-election-integrity-interest` | **independent** | `election-integrity-interestp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-important-interest` | **independent** | `important-government-interestp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-reasonable-requirement` | **independent** | `reasonable-registration-requirementp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-procedure-evenhanded` | **independent** | `registration-procedure-evenhandedp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-rationally-connected` | **independent** | `documentary-proof-requirement-rationally-connectedp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-adequate-alternative` | **independent** | `adequate-alternative-processp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-burden-not-severe` | **independent** | `burden-not-severep['federal-save-act', 'amend-v-equal-protection'] := nil` | — | not provable from the others within 8s |
| `government-assume-right-to-vote-arguendo` | **independent** | `protected-right-to-votep['amend-v-equal-protection', 'citizen-a'] := nil` | — | not provable from the others within 8s |
| `government-scenario-alternative-process-approved` | **coupled** | `alternative-process-approvedp['citizen-a', 'registration-attempt-a'] := nil` | `semantic-a-mandatory-approval` | not provable from the others within 8s |
| `government-bridge-removal-validates` | **independent** | `valid-regulationp['amend-v-equal-protection', 'citizen-b'] := nil` | — | not provable from the others within 8s |
| `government-removal-procedure-evenhanded` | **independent** | `removal-procedure-evenhandedp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-bridge-voting-validates` | **independent** | `valid-regulationp['amend-v-equal-protection', 'ballot-c'] := nil` | — | not provable from the others within 8s |
| `government-photo-id-evenhanded` | **independent** | `photo-id-requirement-evenhandedp['federal-save-act'] := nil` | — | not provable from the others within 8s |
| `government-provisional-cure-adequate` | **independent** | `provisional-cure-adequatep['federal-save-act'] := nil` | — | not provable from the others within 8s |

## Reading the clusters

A *coupled* verdict is not an error. It says the theory's axioms are not all free to vary independently: the listed axioms must move together. In the challenger theory the bridge rules and the scenario facts that instantiate them form one such joint; in the government theory the six-factor defense and its bridge form another. These joints are exactly the premises the explorer's presets toggle together, and the pivot theorems in `core` state the logic of each joint once.

