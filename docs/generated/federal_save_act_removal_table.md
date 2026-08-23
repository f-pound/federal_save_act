# NVRA § 8(k) (as added by SAVE Act § 2(f)) — removal of noncitizens from the rolls

_Generated from the same IR as the ACL2 book; do not edit._

## Process `rem` — SAVE Act § 2(f) / NVRA § 8(k); NVRA § 8(a)(3)(D)
Lifecycle of one registrant's record. § 8(k) (both texts) names two steps: receipt of documentation or verified information of noncitizenship, and removal 'at any time' upon receipt — no notice. The SAVE America Act vehicle (S. 1383 § 8(j)(4)(B)) adds a SYSTEMATIC path — DHS SAVE-system comparison of the State's list — on which removal comes only 'after notice is given ... and ... the opportunity to provide documentary proof'. DUE_PROCESS_OVERLAY edges are not in either text; they let theorems state what the texts do not require.

| From | Event | To | Basis |
|---|---|---|---|
| on-rolls | receive-noncitizen-information | info-received | TEXT_FACT § 2(f) / NVRA § 8(k) ('upon receipt of documentation or verified information') |
| info-received | remove | removed | TEXT_FACT § 2(f) / NVRA § 8(k) ('shall remove ... at any time') |
| info-received | notify-registrant | noticed | DUE_PROCESS_OVERLAY not in statute |
| noticed | remove | removed | DUE_PROCESS_OVERLAY not in statute |
| noticed | contest | contested | DUE_PROCESS_OVERLAY not in statute |
| contested | confirm-citizenship | on-rolls | DUE_PROCESS_OVERLAY not in statute |
| contested | remove | removed | DUE_PROCESS_OVERLAY not in statute |
| on-rolls | save-system-match | save-identified | TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B) — “Each State shall submit the complete, official list of individuals registered as eligible voters for Federal office in the State to the Department of Homeland Security for comparison through the Systematic Alien Verification for Entitlements ('SAVE') system for the purposes of identifying individuals who are not citizens of the United States” |
| save-identified | notify-registrant | noticed | TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B) — “taking the necessary steps to remove such individuals who are not citizens from the official list, after notice is given to such individuals and such individuals are given the opportunity to provide documentary proof of United States citizenship” |
| noticed | provide-documentary-proof | on-rolls | TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B) ('opportunity to provide documentary proof') |
| noticed | opportunity-lapses | removed | TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B) ('taking the necessary steps to remove') |

Any (state, event) pair not listed leaves the state unchanged.
