(in-package "ACL2")

(include-book "lib/enum_list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_voting_id_rules.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_voting_id_rules.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : 155e43ce6633d5f4925260ff9e30661d39c68e1f6077a3caa4468ee71e1f5d06
;; SAVE America Act § 3 / HAVA § 303A(c) — valid photo identification to vote
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; CATEGORY valid-photo-id-types   [§ 3 / HAVA § 303A(c)(1)-(5)]
;;; Documents that are 'valid photo identification' for casting a ballot. Note (1), (2) and (5) require a photo AND an expiration date; (3) and (4) do not mention expiration.
;;; =========================================================================
;;   state-drivers-license-with-expiration § 303A(c)(1)
;;       "A valid State-issued motor vehicle driver's license that includes a photo of the individual and an expiration date."
;;   state-id-card-with-expiration        § 303A(c)(2)
;;       "A valid State-issued identification card that includes a photo of the individual and an expiration date issued by a State motor vehicle authority."
;;   valid-us-passport                    § 303A(c)(3)
;;       "A valid United States passport for the individual."
;;   valid-military-identification        § 303A(c)(4)
;;       "A valid military identification for the individual."
;;   tribal-id-with-expiration            § 303A(c)(5)
;;       "A valid identification document issued by a Tribal government that includes a photo of the individual and an expiration date."
(defconst *valid-photo-id-types*
  '(state-drivers-license-with-expiration
    state-id-card-with-expiration
    valid-us-passport
    valid-military-identification
    tribal-id-with-expiration))

;;; =========================================================================
;;; CATEGORY religious-objection-affidavit-types   [§ 3 / HAVA § 303A(a)(1)(B)(i)(II)]
;;; The only non-identification cure for an in-person provisional ballot.
;;; =========================================================================
;;   religious-objection-affidavit        § 303A(a)(1)(B)(i)(II)
;;       "an affidavit developed and made available to the individual by the State attesting that the individual does not possess the identification required under subparagraph (A) because the individual has a religious objection to being photographed."
(defconst *religious-objection-affidavit-types*
  '(religious-objection-affidavit))

;;; =========================================================================
;;; RULE valid-photo-identification-bundlep   [DEFINED_TERM]  § 3 / HAVA § 303A(c)
;;; "a `valid photo identification' means, with respect to an individual who seeks to vote in a State, any of the following"
;;; =========================================================================
(defun valid-photo-identification-bundlep (docs)
  (some-in-catsp docs *valid-photo-id-types*))

;;; =========================================================================
;;; RULE provisional-cure-bundlep   [EXCEPTION]  § 3 / HAVA § 303A(a)(1)(B)(i)
;;; "not later than 3 days after casting the provisional ballot, the individual presents to the official ... the identification required under subparagraph (A) ... an affidavit developed and made available to the individual by the State"
;;; =========================================================================
(defun provisional-cure-bundlep (docs)
  (or (some-in-catsp docs *valid-photo-id-types*)
      (some-in-catsp docs *religious-objection-affidavit-types*)))
