# NVRA § 8(k) (as added by SAVE Act § 2(f)) — removal of noncitizens from the rolls

_Generated from the same IR as the ACL2 book; do not edit._

## Process `rem` — SAVE Act § 2(f) / NVRA § 8(k); NVRA § 8(a)(3)(D)
Lifecycle of one registrant's record under § 8(k). The statute names exactly two steps: receipt of documentation or verified information that the registrant is not a citizen, and removal 'at any time' upon that receipt. Notice and an opportunity to contest are NOT in the text; they are included as DUE_PROCESS_OVERLAY edges so that theorems can state, mechanically, that the statutory path to removal does not pass through them.

| From | Event | To | Basis |
|---|---|---|---|
| on-rolls | receive-noncitizen-information | info-received | TEXT_FACT § 2(f) / NVRA § 8(k) ('upon receipt of documentation or verified information') |
| info-received | remove | removed | TEXT_FACT § 2(f) / NVRA § 8(k) ('shall remove ... at any time') |
| info-received | notify-registrant | noticed | DUE_PROCESS_OVERLAY not in statute |
| noticed | remove | removed | DUE_PROCESS_OVERLAY not in statute |
| noticed | contest | contested | DUE_PROCESS_OVERLAY not in statute |
| contested | confirm-citizenship | on-rolls | DUE_PROCESS_OVERLAY not in statute |
| contested | remove | removed | DUE_PROCESS_OVERLAY not in statute |

Any (state, event) pair not listed leaves the state unchanged.
