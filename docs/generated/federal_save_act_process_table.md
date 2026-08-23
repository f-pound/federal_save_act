# SAVE Act registration lifecycle — labeled state machine table

_Generated from the same IR as the ACL2 book; do not edit._

## Process `reg` — SAVE Act § 2(b)-(f); NVRA §§ 4, 6(e), 8(j)
Lifecycle of one voter registration application under the SAVE Act. TEXT_FACT edges are named in the statute; MODEL_STRUCTURE edges are neutral bookkeeping (submission, registration/denial as terminal acts) needed to make the statutory steps a process. Edges marked 'S. 1383 only' come from the SAVE America Act vehicle and are not in H.R. 22.

| From | Event | To | Basis |
|---|---|---|---|
| unsubmitted | submit-application | submitted | MODEL_STRUCTURE NVRA § 6(a) |
| submitted | present-documents | doc-presented | TEXT_FACT § 2(b) / NVRA § 4(b); § 2(d) / NVRA § 6(e)(1) |
| doc-presented | accept-documents | doc-accepted | TEXT_FACT § 2(b) / NVRA § 4(b) |
| doc-presented | reject-documents | doc-rejected | TEXT_FACT § 2(f) / NVRA § 8(j)(2)(B) (discrepancy) |
| doc-rejected | initiate-alternative-process | alt-initiated | TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i) |
| submitted | initiate-alternative-process | alt-initiated | TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i) ('cannot provide documentary proof') |
| alt-initiated | approve-alternative | alt-approved | TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i)-(ii) |
| alt-initiated | deny-alternative | alt-denied | TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i) ('shall make a determination as to whether') |
| doc-accepted | register | registered | MODEL_STRUCTURE NVRA § 8(a)(1) |
| alt-approved | register | registered | TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(iii)(I) ('register an applicant who cannot provide documentary proof') |
| doc-rejected | deny-registration | denied | TEXT_FACT § 2(f) / NVRA § 8(j)(1) |
| alt-denied | deny-registration | denied | TEXT_FACT § 2(f) / NVRA § 8(j)(1) |
| submitted | deny-registration | denied | TEXT_FACT § 2(b) / NVRA § 4(b) ('shall not accept and process ... unless') |
| doc-presented | name-discrepancy | name-discrepancy-review | TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(2)(A) — “presents with the application documentation that would constitute documentary proof of United States citizenship, except that the name on the documentation is not the name of the applicant” |
| name-discrepancy-review | establish-previous-name | doc-accepted | TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(2)(B) — “additional documentation as necessary to establish that the name on the documentation is a previous name of the applicant ... an affidavit signed by the applicant attesting that the name on the documentation is a previous name of the applicant” |
| name-discrepancy-review | reject-documents | doc-rejected | MODEL_STRUCTURE previous name not established |

Any (state, event) pair not listed leaves the state unchanged.
