(in-package "ACL2")

(include-book "lib/enum_list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mega_act_s113_removal_grounds.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/mega_act_s113_removal_grounds.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : 42e661aa6d70ca05fd10ccb6ffd53fa41bad0053c79ac8d3498527b81afca6d6
;; H.R. 7300 § 113(a)(1) — grounds for removal from the official list
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; CATEGORY removal-grounds   [§ 113(a)(1)(A)-(F)]
;;; The six grounds on which a State removes registrants determined to be ineligible.
;;; =========================================================================
;;   request-of-the-registrant            § 113(a)(1)(A)
;;       "the request of the registrant;"
;;   criminal-conviction-or-mental-incapacity § 113(a)(1)(B)
;;       "criminal conviction or mental incapacity pursuant to State law;"
;;   death-of-the-registrant              § 113(a)(1)(C)
;;       "the death of the registrant;"
;;   change-in-residence                  § 113(a)(1)(D)
;;       "a change in the residence of the registrant, in accordance with paragraph (2) and subsection (c);"
;;   status-as-a-noncitizen               § 113(a)(1)(E)
;;       "the registrant's status as a noncitizen, including on the basis of the immigration adjudication or status for naturalized citizenship of the registrant as provided by the Director of the United States Citizenship and Immigration Services or any other information with respect to citizenship status supplied by the Department of Homeland Security through the Systematic Alien Verification for Entitlements (``SAVE'') system that demonstrates a registrant is not a citizen of the United States; or"
;;   duplicate-registrations              § 113(a)(1)(F)
;;       "duplicate registrations of a registrant otherwise eligible to vote."
(defconst *removal-grounds*
  '(request-of-the-registrant
    criminal-conviction-or-mental-incapacity
    death-of-the-registrant
    change-in-residence
    status-as-a-noncitizen
    duplicate-registrations))

;;; =========================================================================
;;; RULE removal-ground-typep   [DEFINED_TERM]  § 113(a)(1)
;;; "to remove from the official list of eligible voters in elections for Federal office in the State registrants who are determined to be ineligible voters by reason of"
;;; =========================================================================
(defun removal-ground-typep (g)
  (member-equal g *removal-grounds*))
