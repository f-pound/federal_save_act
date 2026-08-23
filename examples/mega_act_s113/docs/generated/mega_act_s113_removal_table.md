# H.R. 7300 § 113 — registrant record lifecycle

_Generated from the same IR as the ACL2 book; do not edit._

## Process `mrem` — H.R. 7300 § 113(a)-(c)
A registrant's record under § 113. The noncitizen ground (a)(1)(E) is fed by DHS SAVE data and is exempt from the pre-election freeze (b)(1); residence removals (a)(1)(D) go through the return-card procedure (c)(2)-(3). Notice for SAVE-based removals is NOT in the text; overlay edges make that statable.

| From | Event | To | Basis |
|---|---|---|---|
| on-rolls | save-noncitizen-match | save-flagged | TEXT_FACT § 113(a)(1)(E) — “information with respect to citizenship status supplied by the Department of Homeland Security through the Systematic Alien Verification for Entitlements (``SAVE'') system that demonstrates a registrant is not a citizen of the United States” |
| save-flagged | remove | removed | TEXT_FACT § 113(a)(1)(E), (b)(1) — “the removal of names from official lists of voters at any time on a basis described in paragraph (1)(A), (1)(B), or (1)(E)” |
| on-rolls | residence-change-indicated | residence-flagged | TEXT_FACT § 113(a)(2) — “change-of-address information supplied by the Postal Service through its licensees is used to identify registrants whose addresses may have changed” |
| residence-flagged | send-return-card | card-sent | TEXT_FACT § 113(c)(2) — “a postage prepaid and pre-addressed return card, sent by nonforwardable mail, on which the registrant may state his or her current address” |
| card-sent | card-returned | on-rolls | TEXT_FACT § 113(c)(2)(A) — “the registrant should return the card not later than the time provided for mail registration” |
| card-sent | card-not-returned | removed | TEXT_FACT § 113(c)(3)(A) — “the registrant shall be removed from the official list of eligible voters as described in paragraph (1)” |
| save-flagged | notify-registrant | noticed | DUE_PROCESS_OVERLAY not in statute |
| noticed | provide-proof | on-rolls | DUE_PROCESS_OVERLAY not in statute |
| noticed | remove | removed | DUE_PROCESS_OVERLAY not in statute |

Any (state, event) pair not listed leaves the state unchanged.
