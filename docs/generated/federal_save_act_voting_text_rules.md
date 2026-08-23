# SAVE America Act § 3 / HAVA § 303A — text-derived constraints (defaxiom)

_Generated from the same IR as the ACL2 book; do not edit._

## Axiom `text-photo-id-required-for-regular-ballot(p, b)` — § 3 / HAVA § 303A(a)(1)(A)
> the appropriate State or local election official may not provide a ballot for an election for Federal office to an individual who desires to vote in person unless the individual presents to the official a valid physical photo identification

If personp(p) AND registered-voterp(p) AND ballotp(b) AND votes-in-personp(p, b) AND it is not the case that presents-valid-photo-idp(p, b), then statute-denies-regular-ballotp('federal-save-act, p, b).
