(in-package "ACL2")

(include-book "lib/enum_list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_document_rules.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_document_rules.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : 4b0d13caea3e265f707e76da1ed025895dfb0d66ce5df449691df26f9415d2e4
;; SAVE Act § 2(a) / NVRA § 3(b) — documentary proof of United States citizenship
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; CATEGORY standalone-proof-types   [§ 2(a) / NVRA § 3(b)(1)-(4)]
;;; Documents that are documentary proof of citizenship on their own.
;;; =========================================================================
;;   real-id-indicating-citizenship       § 3(b)(1)
;;       "A form of identification issued consistent with the requirements of the REAL ID Act of 2005 that indicates the applicant is a citizen of the United States."
;;   valid-us-passport                    § 3(b)(2)
;;       "A valid United States passport."
;;   military-id-with-us-birth            § 3(b)(3)
;;       "The applicant's official United States military identification card, together with a United States military record of service showing that the applicant's place of birth was in the United States."
;;   govt-photo-id-showing-us-birth       § 3(b)(4)
;;       "A valid government-issued photo identification card issued by a Federal, State or Tribal government showing that the applicant's place of birth was in the United States."
(defconst *standalone-proof-types*
  '(real-id-indicating-citizenship
    valid-us-passport
    military-id-with-us-birth
    govt-photo-id-showing-us-birth))

;;; =========================================================================
;;; CATEGORY anchor-photo-id-types   [§ 2(a) / NVRA § 3(b)(5)]
;;; A government-issued photo ID that is NOT itself proof, but anchors a supporting document.
;;; =========================================================================
;;   govt-photo-id                        § 3(b)(5)
;;       "A valid government-issued photo identification card issued by a Federal, State or Tribal government other than an identification described in paragraphs (1) through (4)."
(defconst *anchor-photo-id-types*
  '(govt-photo-id))

;;; =========================================================================
;;; CATEGORY supporting-document-types   [§ 2(a) / NVRA § 3(b)(5)(A)-(F)]
;;; Documents that count only when presented together with an anchor photo ID.
;;; =========================================================================
;;   certified-birth-certificate          § 3(b)(5)(A)
;;       "A certified birth certificate issued by a State, a unit of local government in a State, or a Tribal government which-- [clauses (i)-(vii)]"
;;   hospital-birth-record                § 3(b)(5)(B)
;;       "An extract from a United States hospital Record of Birth created at the time of the applicant's birth which indicates that the applicant's place of birth was in the United States."
;;   final-adoption-decree                § 3(b)(5)(C)
;;       "A final adoption decree showing the applicant's name and that the applicant's place of birth was in the United States."
;;   consular-report-of-birth-abroad      § 3(b)(5)(D)
;;       "A Consular Report of Birth Abroad of a citizen of the United States or a certification of the applicant's Report of Birth of a United States citizen issued by the Secretary of State."
;;   naturalization-certificate           § 3(b)(5)(E)
;;       "A Naturalization Certificate or Certificate of Citizenship issued by the Secretary of Homeland Security or any other document or method of proof of United States citizenship issued by the Federal government pursuant to the Immigration and Nationality Act."
;;   american-indian-card-kic             § 3(b)(5)(F)
;;       "An American Indian Card issued by the Department of Homeland Security with the classification 'KIC'."
(defconst *supporting-document-types*
  '(certified-birth-certificate
    hospital-birth-record
    final-adoption-decree
    consular-report-of-birth-abroad
    naturalization-certificate
    american-indian-card-kic))

;;; =========================================================================
;;; RULE documentary-proof-bundlep   [DEFINED_TERM]  § 2(a) / NVRA § 3(b)
;;; "the term 'documentary proof of United States citizenship' means, with respect to an applicant for voter registration, any of the following ... but only if presented together with one or more of the following"
;;; =========================================================================
(defun documentary-proof-bundlep (docs)
  (or (some-in-catsp docs *standalone-proof-types*)
      (and (some-in-catsp docs *anchor-photo-id-types*)
           (some-in-catsp docs *supporting-document-types*))))

;;; =========================================================================
;;; RULE recognized-document-typep   [DEFINED_TERM]  § 2(a) / NVRA § 3(b)
;;; d is a document type the statute names anywhere in § 3(b).
;;; =========================================================================
(defun recognized-document-typep (d)
  (or (member-equal d *standalone-proof-types*)
      (member-equal d *anchor-photo-id-types*)
      (member-equal d *supporting-document-types*)))
