(in-package "ACL2")

(include-book "mega_act_s113_core")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mega_act_s113_text_rules.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/mega_act_s113_text_rules.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : 03169632e8d77bd210cac953b53f8cf3c6c18814f314d3bad3cc48da0befc056
;; H.R. 7300 § 113 — text-derived constraints (defaxiom)
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; AXIOM text-s113-noncitizen-determination-removes   [PROHIBITION]  § 113(a)(1), (a)(1)(E)
;;; "to remove from the official list of eligible voters in elections for Federal office in the State registrants who are determined to be ineligible voters by reason of ... the registrant's status as a noncitizen"
;;; =========================================================================
(defaxiom text-s113-noncitizen-determination-removes
  (implies
   (and (personp p)
        (registered-voterp p)
        (determined-ineligible-noncitizenp p))
   (statute-removes-registrantp 'mega-act p)))

;;; =========================================================================
;;; AXIOM text-s113-noncitizen-removal-at-any-time   [TEXT_FACT]  § 113(b)(1)
;;; "the removal of names from official lists of voters at any time on a basis described in paragraph (1)(A), (1)(B), or (1)(E) of subsection (a)"
;;; =========================================================================
(defaxiom text-s113-noncitizen-removal-at-any-time
  (implies
   (and (personp p)
        (determined-ineligible-noncitizenp p))
   (removable-at-any-timep p)))

;;; =========================================================================
;;; AXIOM text-s113-residence-removal-requires-return-card   [PROCEDURAL_FACT]  § 113(c)(2)-(3)
;;; "If the pre-addressed return card described in paragraph (2) is not returned, or if the notice described in such paragraph is returned as undeliverable-- (A) the registrant shall be removed from the official list of eligible voters"
;;; =========================================================================
(defaxiom text-s113-residence-removal-requires-return-card
  (implies
   (and (personp p)
        (registered-voterp p)
        (removed-for-residence-changep p))
   (notice-card-sentp p)))
