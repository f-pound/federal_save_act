(in-package "ACL2")

(include-book "federal_save_act_hinge_common")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_hinge_mandatory.lisp  —  v5
;; Semantic A: Mandatory approval when evidence satisfies standards.
;;
;; Under this reading of SAVE Act § 2(f) / NVRA § 8(j)(2)(A):
;;   "shall make a determination" = mandatory duty to approve
;;   when the attestation + evidence satisfies the standards.
;;
;; Constitutional consequence: If the alternative process guarantees
;; registration for eligible citizens who lack documentary proof,
;; then the denial trigger CANNOT fire, and no constitutional
;; conflict arises through this path.
;;
;; This is the GOVERNMENT-FAVORABLE interpretation.
;;
;; IMPORTANT: This book CANNOT be loaded in the same session as
;; federal_save_act_hinge_discretionary.lisp. The defaxiom below
;; constrains alternative-process-approvedp in a direction opposite
;; to the discretionary book.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; SEMANTIC A BRIDGE RULE
;;;
;;; INTERPRETIVE_ASSUMPTION: If the applicant signs attestation under
;;; perjury, submits other evidence, and the evidence satisfies the
;;; EAC-defined standards, then the official MUST approve.
;;; =========================================================================

(defaxiom semantic-a-mandatory-approval
  (implies
   (and (signs-attestation-under-perjuryp p)
        (submits-other-evidencep p)
        (attestation-evidence-satisfies-standardsp p x))
   (alternative-process-approvedp p x)))

;;; =========================================================================
;;; HINGE THEOREM: Mandatory semantics → no denial trigger
;;;
;;; Under Semantic A, if a person satisfies the attestation requirements,
;;; the alternative process approves them, so the denial trigger cannot fire.
;;; =========================================================================

(defthm hinge-mandatory-no-denial-trigger
  (implies
   (and (signs-attestation-under-perjuryp p)
        (submits-other-evidencep p)
        (attestation-evidence-satisfies-standardsp p x)
        (personp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x))
   (not (save-act-denial-triggerp p x)))
  :hints (("Goal" :in-theory (enable save-act-denial-triggerp
                               registration-transactionp)))
  :rule-classes nil)

;;; =========================================================================
;;; COROLLARY: Under mandatory semantics, if evidence satisfies standards,
;;; the alternative process IS approved.
;;;
;;; Note: We cannot prove (not (statute-denies-registrationp ...)) because
;;; statute-denies-registrationp is a defstub — the facts axiom only
;;; provides sufficient conditions for it to be TRUE, not necessary
;;; conditions. But we CAN prove the alternative process approves,
;;; which is the mechanism by which the denial trigger is defeated.
;;; =========================================================================

(defthm hinge-mandatory-alternative-approved
  (implies
   (and (signs-attestation-under-perjuryp p)
        (submits-other-evidencep p)
        (attestation-evidence-satisfies-standardsp p x))
   (alternative-process-approvedp p x))
  :rule-classes nil)

