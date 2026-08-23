(in-package "ACL2")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_voting_table.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_voting_table.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : d306002ed79a9a33b0a4f0959ec8375474224e96a24be5ae40a0eaf408dcee33
;; SAVE America Act § 3 / HAVA § 303A(a)(1) — in-person ballot lifecycle
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; PROCESS vote   [SAVE America Act § 3 / HAVA § 303A(a)(1); HAVA § 302(a)]
;;; Lifecycle of one in-person ballot under new HAVA § 303A. TEXT_FACT edges are named in the statute; MODEL_STRUCTURE edges are the ordinary casting/counting bookkeeping of HAVA § 302(a).
;;; =========================================================================
(defconst *vote-at-polls* 'at-polls)  ; registered voter arrives to vote in person
(defconst *vote-id-presented* 'id-presented)  ; valid photo identification presented (§ 303A(a)(1)(A))
(defconst *vote-regular-cast* 'regular-cast)  ; regular ballot provided and cast
(defconst *vote-provisional-cast* 'provisional-cast)  ; provisional ballot cast for lack of identification (§ 303A(a)(1)(B)(i))
(defconst *vote-cured* 'cured)  ; identification or religious-objection affidavit presented within 3 days
(defconst *vote-counted* 'counted)  ; terminal: ballot counted
(defconst *vote-rejected* 'rejected)  ; terminal: provisional ballot not counted (no cure within 3 days)

(defconst *vote-evt-present-id* 'present-valid-photo-id)  ; voter presents a valid physical photo identification
(defconst *vote-evt-no-id* 'no-identification)  ; voter does not present the required identification
(defconst *vote-evt-cast* 'cast-regular-ballot)  ; official provides, voter casts, a regular ballot
(defconst *vote-evt-cure* 'cure-within-3-days)  ; voter presents ID or religious-objection affidavit within 3 days
(defconst *vote-evt-lapse* 'cure-deadline-lapses)  ; 3 days pass without cure
(defconst *vote-evt-count* 'count-ballot)  ; official counts the ballot
(defconst *vote-evt-reject* 'reject-ballot)  ; official rejects the provisional ballot

(defconst *vote-states*
  (list *vote-at-polls* *vote-id-presented* *vote-regular-cast* *vote-provisional-cast* *vote-cured* *vote-counted* *vote-rejected*))
(defconst *vote-events*
  (list *vote-evt-present-id* *vote-evt-no-id* *vote-evt-cast* *vote-evt-cure* *vote-evt-lapse* *vote-evt-count* *vote-evt-reject*))

;; Edge table: (from-state event to-state).  Unlisted pairs are no-ops.
(defconst *vote-edges*
  (list
   (list *vote-at-polls* *vote-evt-present-id* *vote-id-presented*)  ; TEXT_FACT § 303A(a)(1)(A)
   (list *vote-id-presented* *vote-evt-cast* *vote-regular-cast*)  ; TEXT_FACT § 303A(a)(1)(A) ('may not provide a ballot ... unless')
   (list *vote-at-polls* *vote-evt-no-id* *vote-provisional-cast*)  ; TEXT_FACT § 303A(a)(1)(B)(i) ('shall be permitted to cast a provisional ballot')
   (list *vote-provisional-cast* *vote-evt-cure* *vote-cured*)  ; TEXT_FACT § 303A(a)(1)(B)(i)(I)-(II)
   (list *vote-provisional-cast* *vote-evt-lapse* *vote-rejected*)  ; TEXT_FACT § 303A(a)(1)(B)(i) ('may not make a determination ... that the individual is eligible ... unless, not later than 3 days')
   (list *vote-regular-cast* *vote-evt-count* *vote-counted*)  ; MODEL_STRUCTURE HAVA § 302(a)
   (list *vote-cured* *vote-evt-count* *vote-counted*)  ; TEXT_FACT § 303A(a)(1)(B)(i); HAVA § 302(a)(4)
   (list *vote-provisional-cast* *vote-evt-reject* *vote-rejected*)  ; MODEL_STRUCTURE HAVA § 302(a)(4) (no eligibility determination)
   ))
