# Adversarial audit of the party trusted bases

For each axiom A: flip exactly one stub value so A is false, and check whether every OTHER axiom of the theory still holds (complete finite-model check over the audit worlds). **independent** = the flipped world is a model of the rest ∧ ¬A. **coupled** = the flip also falsifies the listed axioms — these clusters are the theory's load-bearing joints (hinges). Run with `--acl2` to add kernel-checked redundancy attempts.

## Challenger theory — 14 axioms: 14 independent, 0 coupled, 0 no single-stub flip

| Axiom | Verdict | Flip used | Breaks |
|---|---|---|---|
| `text-s113-noncitizen-determination-removes` | **independent** | `statute-removes-registrantp['mega-act', 'registrant-r'] := nil` | — |
| `text-s113-noncitizen-removal-at-any-time` | **independent** | `removable-at-any-timep['registrant-r'] := nil` | — |
| `text-s113-residence-removal-requires-return-card` | **independent** | `removed-for-residence-changep['registrant-r'] := t` | — |
| `scenario-r-person` | **independent** | `personp['registrant-r'] := nil` | — |
| `scenario-r-citizen` | **independent** | `citizen-of-usp['registrant-r'] := nil` | — |
| `scenario-r-eligible` | **independent** | `eligible-voterp['registrant-r'] := nil` | — |
| `scenario-r-registered` | **independent** | `registered-voterp['registrant-r'] := nil` | — |
| `scenario-r-save-indicates-noncitizen` | **independent** | `save-indicates-noncitizenp['registrant-r'] := nil` | — |
| `scenario-r-no-notice` | **independent** | `adequate-notice-before-removalp['registrant-r'] := t` | — |
| `scenario-r-no-hearing` | **independent** | `opportunity-to-be-heardp['registrant-r'] := t` | — |
| `text-mega-act-is-law` | **independent** | `lawp['mega-act'] := nil` | — |
| `semantic-a-save-data-is-determination` | **independent** | `determined-ineligible-noncitizenp['registrant-r'] := nil` | — |
| `challenger-bridge-right-to-vote` | **independent** | `challenger-right-to-vote-establishedp['amend-v-due-process'] := t` | — |
| `challenger-bridge-removal-invalid` | **independent** | `valid-regulationp['mega-act', 'registrant-r'] := t` | — |

## Government theory — 17 axioms: 15 independent, 2 coupled, 0 no single-stub flip

| Axiom | Verdict | Flip used | Breaks |
|---|---|---|---|
| `text-s113-noncitizen-determination-removes` | **coupled** | `determined-ineligible-noncitizenp['registrant-r'] := t` | `text-s113-noncitizen-removal-at-any-time`, `semantic-b-determination-requires-notice` |
| `text-s113-noncitizen-removal-at-any-time` | **coupled** | `determined-ineligible-noncitizenp['amend-v-due-process'] := t & personp['amend-v-due-process'] := t` | `semantic-b-determination-requires-notice` |
| `text-s113-residence-removal-requires-return-card` | **independent** | `removed-for-residence-changep['registrant-r'] := t` | — |
| `scenario-r-person` | **independent** | `personp['registrant-r'] := nil` | — |
| `scenario-r-citizen` | **independent** | `citizen-of-usp['registrant-r'] := nil` | — |
| `scenario-r-eligible` | **independent** | `eligible-voterp['registrant-r'] := nil` | — |
| `scenario-r-registered` | **independent** | `registered-voterp['registrant-r'] := nil` | — |
| `scenario-r-save-indicates-noncitizen` | **independent** | `save-indicates-noncitizenp['registrant-r'] := nil` | — |
| `scenario-r-no-notice` | **independent** | `adequate-notice-before-removalp['registrant-r'] := t` | — |
| `scenario-r-no-hearing` | **independent** | `opportunity-to-be-heardp['registrant-r'] := t` | — |
| `text-mega-act-is-law` | **independent** | `lawp['mega-act'] := nil` | — |
| `semantic-b-determination-requires-notice` | **independent** | `determined-ineligible-noncitizenp['amend-v-due-process'] := t` | — |
| `government-bridge-removal-validates` | **independent** | `valid-regulationp['amend-v-due-process', 'registrant-r'] := nil` | — |
| `government-important-interest` | **independent** | `important-government-interestp['mega-act'] := nil` | — |
| `government-removal-procedure-evenhanded` | **independent** | `removal-procedure-evenhandedp['mega-act'] := nil` | — |
| `government-save-data-reliable` | **independent** | `save-data-reliablep['mega-act'] := nil` | — |
| `government-assume-right-to-vote-arguendo` | **independent** | `protected-right-to-votep['amend-v-due-process', 'registrant-r'] := nil` | — |

## Reading the clusters

A *coupled* verdict is not an error. It says the theory's axioms are not all free to vary independently: the listed axioms must move together. In the challenger theory the bridge rules and the scenario facts that instantiate them form one such joint; in the government theory the six-factor defense and its bridge form another. These joints are exactly the premises the explorer's presets toggle together, and the pivot theorems in `core` state the logic of each joint once.

