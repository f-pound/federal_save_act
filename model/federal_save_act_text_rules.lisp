(in-package "ACL2")

(include-book "federal_save_act_core")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_text_rules.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_text_rules.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : e2d3effbe0741a35b0f7bac40ab44a0e6e429d61aa68b380c7f77fed7f196cce
;; SAVE Act text-derived constraints on the neutral vocabulary (defaxiom)
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; AXIOM text-save-act-documentary-proof-requirement   [PROHIBITION]  § 2(b) / NVRA § 4(b); § 2(d) / NVRA § 6(e)(1); § 2(f) / NVRA § 8(j)(1)
;;; "the State shall not accept and process an application to register to vote in an election for Federal office unless the applicant presents documentary proof of United States citizenship with the application [§ 4(b)]; a State may not register an individual ... unless, at the time the individual applies to register to vote, the individual provides documentary proof of United States citizenship [§ 8(j)(1)]"
;;; =========================================================================
(defaxiom text-save-act-documentary-proof-requirement
  (implies
   (and (personp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (not (presents-documentary-proofp p x))
        (not (alternative-process-approvedp p x)))
   (statute-denies-registrationp 'federal-save-act p x)))

;;; =========================================================================
;;; AXIOM text-save-act-removal-upon-verified-information   [PROHIBITION]  § 2(f) / NVRA § 8(k); NVRA § 8(a)(3)(D)
;;; "A State shall remove an individual who is not a citizen of the United States from the official list of eligible voters for elections for Federal office held in the State at any time upon receipt of documentation or verified information that a registrant is not a United States citizen."
;;; =========================================================================
(defaxiom text-save-act-removal-upon-verified-information
  (implies
   (and (personp p)
        (registered-voterp p)
        (verified-noncitizen-informationp p))
   (statute-removes-registrantp 'federal-save-act p)))
