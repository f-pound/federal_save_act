# SAVE America Act § 3 / HAVA § 303A(c) — valid photo identification to vote

_Generated from the same IR as the ACL2 book; do not edit._

## Category `valid-photo-id-types` — § 3 / HAVA § 303A(c)(1)-(5)
Documents that are 'valid photo identification' for casting a ballot. Note (1), (2) and (5) require a photo AND an expiration date; (3) and (4) do not mention expiration.

- **state-drivers-license-with-expiration** (§ 303A(c)(1)): A valid State-issued motor vehicle driver's license that includes a photo of the individual and an expiration date.
- **state-id-card-with-expiration** (§ 303A(c)(2)): A valid State-issued identification card that includes a photo of the individual and an expiration date issued by a State motor vehicle authority.
- **valid-us-passport** (§ 303A(c)(3)): A valid United States passport for the individual.
- **valid-military-identification** (§ 303A(c)(4)): A valid military identification for the individual.
- **tribal-id-with-expiration** (§ 303A(c)(5)): A valid identification document issued by a Tribal government that includes a photo of the individual and an expiration date.

## Category `religious-objection-affidavit-types` — § 3 / HAVA § 303A(a)(1)(B)(i)(II)
The only non-identification cure for an in-person provisional ballot.

- **religious-objection-affidavit** (§ 303A(a)(1)(B)(i)(II)): an affidavit developed and made available to the individual by the State attesting that the individual does not possess the identification required under subparagraph (A) because the individual has a religious objection to being photographed.

## Category `ssn-last-four-types` — § 3 / HAVA § 303A(a)(2)(A)(ii)
For ballots cast other than in person: the last four digits of the Social Security number, usable only with the inability affidavit.

- **ssn-last-four-digits** (§ 303A(a)(2)(A)(ii)): the last four digits of the individual's Social Security number

## Category `inability-affidavit-types` — § 3 / HAVA § 303A(a)(2)(A)(ii)
Affidavit that the voter cannot obtain a copy of a valid photo identification after reasonable efforts.

- **affidavit-unable-to-obtain-copy** (§ 303A(a)(2)(A)(ii)): an affidavit developed and made available to the individual by the State attesting that the individual is unable to obtain a copy of a valid photo identification after making reasonable efforts to obtain such a copy

## Rule `valid-photo-identification-bundlep(docs)` — § 3 / HAVA § 303A(c)
> a `valid photo identification' means, with respect to an individual who seeks to vote in a State, any of the following

`valid-photo-identification-bundlep` holds exactly when: at least one item of docs is a valid photo id types.

## Rule `provisional-cure-bundlep(docs)` — § 3 / HAVA § 303A(a)(1)(B)(i)
> not later than 3 days after casting the provisional ballot, the individual presents to the official ... the identification required under subparagraph (A) ... an affidavit developed and made available to the individual by the State

`provisional-cure-bundlep` holds exactly when: at least one item of docs is a valid photo id types OR at least one item of docs is a religious objection affidavit types.

## Rule `mail-ballot-identification-bundlep(docs)` — § 3 / HAVA § 303A(a)(2)(A)
> may not accept any ballot for an election for Federal office provided by an individual who votes other than in person unless the individual submits with the ballot ... a copy of a valid photo identification ... the last four digits of the individual's Social Security number and an affidavit

`mail-ballot-identification-bundlep` holds exactly when: at least one item of docs is a valid photo id types OR (at least one item of docs is a ssn last four types AND at least one item of docs is a inability affidavit types).
