# SAVE Act § 2(a) / NVRA § 3(b) — documentary proof of United States citizenship

_Generated from the same IR as the ACL2 book; do not edit._

## Category `standalone-proof-types` — § 2(a) / NVRA § 3(b)(1)-(4)
Documents that are documentary proof of citizenship on their own.

- **real-id-indicating-citizenship** (§ 3(b)(1)): A form of identification issued consistent with the requirements of the REAL ID Act of 2005 that indicates the applicant is a citizen of the United States.
- **valid-us-passport** (§ 3(b)(2)): A valid United States passport.
- **military-id-with-us-birth** (§ 3(b)(3)): The applicant's official United States military identification card, together with a United States military record of service showing that the applicant's place of birth was in the United States.
- **govt-photo-id-showing-us-birth** (§ 3(b)(4)): A valid government-issued photo identification card issued by a Federal, State or Tribal government showing that the applicant's place of birth was in the United States.

## Category `anchor-photo-id-types` — § 2(a) / NVRA § 3(b)(5)
A government-issued photo ID that is NOT itself proof, but anchors a supporting document.

- **govt-photo-id** (§ 3(b)(5)): A valid government-issued photo identification card issued by a Federal, State or Tribal government other than an identification described in paragraphs (1) through (4).

## Category `supporting-document-types` — § 2(a) / NVRA § 3(b)(5)(A)-(F)
Documents that count only when presented together with an anchor photo ID.

- **certified-birth-certificate** (§ 3(b)(5)(A)): A certified birth certificate issued by a State, a unit of local government in a State, or a Tribal government (meeting clauses (i)-(vii)).
- **hospital-birth-record** (§ 3(b)(5)(B)): An extract from a United States hospital Record of Birth created at the time of the applicant's birth which indicates that the applicant's place of birth was in the United States.
- **final-adoption-decree** (§ 3(b)(5)(C)): A final adoption decree showing the applicant's name and that the applicant's place of birth was in the United States.
- **consular-report-of-birth-abroad** (§ 3(b)(5)(D)): A Consular Report of Birth Abroad of a citizen of the United States or a certification of the applicant's Report of Birth of a United States citizen issued by the Secretary of State.
- **naturalization-certificate** (§ 3(b)(5)(E)): A Naturalization Certificate or Certificate of Citizenship issued by the Secretary of Homeland Security or any other document or method of proof of United States citizenship issued by the Federal government pursuant to the Immigration and Nationality Act.
- **american-indian-card-kic** (§ 3(b)(5)(F)): An American Indian Card issued by the Department of Homeland Security with the classification 'KIC'.

## Rule `documentary-proof-bundlep(docs)` — § 2(a) / NVRA § 3(b)
> the term 'documentary proof of United States citizenship' means, with respect to an applicant for voter registration, any of the following: (1)-(4) [standalone]; (5) a valid government-issued photo identification card ... but only if presented together with one or more of the following: (A)-(F) [supporting]

`documentary-proof-bundlep` holds exactly when: at least one item of docs is a standalone proof types OR (at least one item of docs is a anchor photo id types AND at least one item of docs is a supporting document types).

## Rule `recognized-document-typep(d)` — § 2(a) / NVRA § 3(b)
> d is a document type the statute names anywhere in § 3(b).

`recognized-document-typep` holds exactly when: d is a standalone proof types OR d is a anchor photo id types OR d is a supporting document types.
