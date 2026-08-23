# H.R. 7300 § 113 — text-derived constraints (defaxiom)

_Generated from the same IR as the ACL2 book; do not edit._

## Axiom `text-s113-noncitizen-determination-removes(p)` — § 113(a)(1), (a)(1)(E)
> to remove from the official list of eligible voters in elections for Federal office in the State registrants who are determined to be ineligible voters by reason of ... the registrant's status as a noncitizen

If personp(p) AND registered-voterp(p) AND determined-ineligible-noncitizenp(p), then statute-removes-registrantp('mega-act, p).

## Axiom `text-s113-noncitizen-removal-at-any-time(p)` — § 113(b)(1)
> the removal of names from official lists of voters at any time on a basis described in paragraph (1)(A), (1)(B), or (1)(E) of subsection (a)

If personp(p) AND determined-ineligible-noncitizenp(p), then removable-at-any-timep(p).

## Axiom `text-s113-residence-removal-requires-return-card(p)` — § 113(c)(2)-(3)
> If the pre-addressed return card described in paragraph (2) is not returned, or if the notice described in such paragraph is returned as undeliverable-- (A) the registrant shall be removed from the official list of eligible voters

If personp(p) AND registered-voterp(p) AND removed-for-residence-changep(p), then notice-card-sentp(p).
