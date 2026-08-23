# SAVE America Act § 3 / HAVA § 303A(a)(1) — in-person ballot lifecycle

_Generated from the same IR as the ACL2 book; do not edit._

## Process `vote` — SAVE America Act § 3 / HAVA § 303A(a)(1); HAVA § 302(a)
Lifecycle of one in-person ballot under new HAVA § 303A. TEXT_FACT edges are named in the statute; MODEL_STRUCTURE edges are the ordinary casting/counting bookkeeping of HAVA § 302(a).

| From | Event | To | Basis |
|---|---|---|---|
| at-polls | present-valid-photo-id | id-presented | TEXT_FACT § 303A(a)(1)(A) |
| id-presented | cast-regular-ballot | regular-cast | TEXT_FACT § 303A(a)(1)(A) ('may not provide a ballot ... unless') |
| at-polls | no-identification | provisional-cast | TEXT_FACT § 303A(a)(1)(B)(i) ('shall be permitted to cast a provisional ballot') |
| provisional-cast | cure-within-3-days | cured | TEXT_FACT § 303A(a)(1)(B)(i)(I)-(II) |
| provisional-cast | cure-deadline-lapses | rejected | TEXT_FACT § 303A(a)(1)(B)(i) ('may not make a determination ... that the individual is eligible ... unless, not later than 3 days') |
| regular-cast | count-ballot | counted | MODEL_STRUCTURE HAVA § 302(a) |
| cured | count-ballot | counted | TEXT_FACT § 303A(a)(1)(B)(i); HAVA § 302(a)(4) |
| provisional-cast | reject-ballot | rejected | MODEL_STRUCTURE HAVA § 302(a)(4) (no eligibility determination) |

Any (state, event) pair not listed leaves the state unchanged.
