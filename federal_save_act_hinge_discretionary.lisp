(in-package "ACL2")

(include-book "federal_save_act_hinge_common")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_hinge_discretionary.lisp  —  v5
;; Semantic B: Discretionary determination with possible denial.
;;
;; Under this reading of SAVE Act § 2(f) / NVRA § 8(j)(2)(A):
;;   "shall make a determination" = duty to DECIDE, but the
;;   determination may go either way.  The statute says "whether"
;;   the applicant has "sufficiently established" citizenship — the
;;   standard for "sufficiently" is undefined, giving the official
;;   discretion to deny.
;;
;; Constitutional consequence: If the official can deny despite
;; attestation + evidence, then qualified citizens who lack documentary
;; proof face a risk of erroneous denial, the denial trigger fires,
;; and constitutional conflict is possible.
;;
;; This is the CHALLENGER-FAVORABLE interpretation.
;;
;; IMPORTANT: This book CANNOT be loaded in the same session as
;; federal_save_act_hinge_mandatory.lisp. The defaxiom below
;; constrains alternative-process-approvedp in a direction opposite
;; to the mandatory book.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; SEMANTIC B BRIDGE RULE
;;;
;;; INTERPRETIVE_ASSUMPTION: If the official exercises discretionary
;;; denial, then the alternative process is NOT approved.
;;; =========================================================================

(defaxiom semantic-b-discretionary-denial
  (implies
   (official-discretionary-denialp p x)
   (not (alternative-process-approvedp p x))))

;;; =========================================================================
;;; HINGE THEOREM 1: Discretionary semantics → denial trigger fires
;;;
;;; Under Semantic B, if the official exercises discretionary denial
;;; AND the applicant lacks documentary proof, the denial trigger fires.
;;; =========================================================================

(defthm hinge-discretionary-denial-trigger-fires
  (implies
   (and (official-discretionary-denialp p x)
        (personp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (not (presents-documentary-proofp p x)))
   (save-act-denial-triggerp p x))
  :hints (("Goal" :in-theory (enable save-act-denial-triggerp
                               registration-transactionp)))
  :rule-classes nil)

;;; =========================================================================
;;; HINGE THEOREM 2: Discretionary semantics → statute denies registration
;;;
;;; Extending Theorem 1: under Semantic B, the statute ALSO denies
;;; registration (via text-save-act-documentary-proof-requirement from
;;; the facts book).
;;; =========================================================================

(defthm hinge-discretionary-statute-denies
  (implies
   (and (official-discretionary-denialp p x)
        (personp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (not (presents-documentary-proofp p x)))
   (statute-denies-registrationp 'federal-save-act p x))
  :rule-classes nil)

;;; =========================================================================
;;; HINGE THEOREM 3: Risk of erroneous denial under discretionary semantics
;;;
;;; Under Semantic B, if the official can deny AND the statutory standard
;;; for "sufficiently established" is undefined, then there exists a
;;; risk of erroneous denial for qualified voters.
;;;
;;; We model this by showing that a qualified voter who signs attestation
;;; and submits evidence can STILL be denied under this reading.
;;; =========================================================================

(defthm hinge-discretionary-qualified-voter-can-be-denied
  (implies
   (and (official-discretionary-denialp p x)
        (personp p)
        (citizen-of-usp p)
        (eligible-voterp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (signs-attestation-under-perjuryp p)
        (submits-other-evidencep p)
        (not (presents-documentary-proofp p x)))
   (and (qualified-federal-voterp p)
        (save-act-denial-triggerp p x)))
  :hints (("Goal" :in-theory (enable save-act-denial-triggerp
                               registration-transactionp
                               qualified-federal-voterp)))
  :rule-classes nil)
