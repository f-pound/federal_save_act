(in-package "ACL2")

(include-book "federal_save_act_core")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_voting_text_rules.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_voting_text_rules.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : c6476d4ce505af7a35d63a8caa1a93539572555b08dc88b916cb827d7b81aa89
;; SAVE America Act § 3 / HAVA § 303A — text-derived constraints (defaxiom)
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; AXIOM text-photo-id-required-for-regular-ballot   [PROHIBITION]  § 3 / HAVA § 303A(a)(1)(A)
;;; "the appropriate State or local election official may not provide a ballot for an election for Federal office to an individual who desires to vote in person unless the individual presents to the official a valid physical photo identification"
;;; =========================================================================
(defaxiom text-photo-id-required-for-regular-ballot
  (implies
   (and (personp p)
        (registered-voterp p)
        (ballotp b)
        (votes-in-personp p b)
        (not (presents-valid-photo-idp p b)))
   (statute-denies-regular-ballotp 'federal-save-act p b)))
