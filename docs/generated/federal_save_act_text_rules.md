# SAVE Act text-derived constraints on the neutral vocabulary (defaxiom)

_Generated from the same IR as the ACL2 book; do not edit._

## Axiom `text-save-act-documentary-proof-requirement(p, x)` — § 2(b) / NVRA § 4(b); § 2(d) / NVRA § 6(e)(1); § 2(f) / NVRA § 8(j)(1)
> the State shall not accept and process an application to register to vote in an election for Federal office unless the applicant presents documentary proof of United States citizenship with the application ... a State may not register an individual to vote in elections for Federal office held in the State unless, at the time the individual applies to register to vote, the individual provides documentary proof of United States citizenship

If personp(p) AND voter-registration-applicationp(x) AND attempts-to-registerp(p, x) AND it is not the case that presents-documentary-proofp(p, x) AND it is not the case that alternative-process-approvedp(p, x), then statute-denies-registrationp('federal-save-act, p, x).

## Axiom `text-save-act-removal-upon-verified-information(p)` — § 2(f) / NVRA § 8(k); NVRA § 8(a)(3)(D)
> A State shall remove an individual who is not a citizen of the United States from the official list of eligible voters for elections for Federal office held in the State at any time upon receipt of documentation or verified information that a registrant is not a United States citizen.

If personp(p) AND registered-voterp(p) AND verified-noncitizen-informationp(p), then statute-removes-registrantp('federal-save-act, p).
