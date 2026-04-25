(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_hinge.lisp  —  v4
;; Alternative attestation process — two competing semantics.
;;
;; The SAVE Act § 2(f) / NVRA § 8(j)(2)(A) says:
;;   "such official shall make a determination as to whether the
;;    applicant has sufficiently established United States citizenship
;;    for purposes of registering to vote"
;;
;; Two readings:
;;   Semantic A (mandatory): If the applicant signs an attestation under
;;     perjury, submits other evidence, and the evidence satisfies the
;;     standards, then the official MUST approve the registration.
;;
;;   Semantic B (discretionary): The official "shall make a determination"
;;     but the determination may go either way. Denial is possible.
;;
;; The constitutional outcome turns on which reading applies:
;;   - Under Semantic A: no denial → no conflict (government wins)
;;   - Under Semantic B: denial possible → conflict possible (challenger wins)
;;
;; Architecture: Both semantics introduce NEW predicates via encapsulate
;; (consistency-checked), then connect them to core defstubs via defaxiom
;; bridge rules (the same hybrid pattern used in the model files).
;;
;; IMPORTANT: Semantic A and Semantic B are MUTUALLY EXCLUSIVE.
;; They CANNOT both be loaded in the same ACL2 session — they constrain
;; alternative-process-approvedp in opposite directions.
;; The hinge analysis shows WHICH reading drives WHICH outcome.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; NEW PREDICATES (both semantics share this vocabulary)
;;; =========================================================================

(encapsulate
  ((attestation-evidence-satisfies-standardsp (p x) t)
   (official-discretionary-denialp (p x) t))

  ;; Witness model: evidence always satisfies, official always denies
  ;; (contradictory, but the exported constraints are individually
  ;; consistent — they just can't both be bridge-ruled simultaneously)
  (local (defun attestation-evidence-satisfies-standardsp (p x)
    (declare (ignore p x)) t))
  (local (defun official-discretionary-denialp (p x)
    (declare (ignore p x)) t))

  ;; No exported constraints on these new predicates — they are
  ;; unconstrained functions.  The bridge rules below constrain
  ;; how they connect to core predicates.
  (defthm hinge-evidence-type
    (booleanp (attestation-evidence-satisfies-standardsp p x))
    :rule-classes :type-prescription)
  (defthm hinge-denial-type
    (booleanp (official-discretionary-denialp p x))
    :rule-classes :type-prescription))

;;; =========================================================================
;;; SEMANTIC A: Mandatory approval when evidence satisfies standards
;;;
;;; TEXT_FACT source: SAVE Act § 2(f) / NVRA § 8(j)(2)(A)(i)
;;; INTERPRETATION: "shall make a determination" = mandatory duty, and
;;;                 if standards are met, approval is required.
;;; =========================================================================

(defaxiom semantic-a-mandatory-approval
  (implies
   (and (signs-attestation-under-perjuryp p)
        (submits-other-evidencep p)
        (attestation-evidence-satisfies-standardsp p x))
   (alternative-process-approvedp p x)))

;;; =========================================================================
;;; HINGE THEOREM 1 (Semantic A → No Denial Trigger)
;;;
;;; Under Semantic A, if a person signs attestation, submits evidence
;;; that satisfies standards, then alternative-process-approvedp is true,
;;; so save-act-denial-triggerp is false.
;;; =========================================================================

(defthm hinge-semantic-a-no-denial-trigger
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
;;; SEMANTIC B: Discretionary determination with possible denial
;;;
;;; TEXT_FACT source: SAVE Act § 2(f) / NVRA § 8(j)(2)(A)(i)
;;; INTERPRETATION: "shall make a determination" = duty to decide,
;;;                 but determination may be denial.
;;; =========================================================================

(defaxiom semantic-b-discretionary-denial
  (implies
   (official-discretionary-denialp p x)
   (not (alternative-process-approvedp p x))))

;;; =========================================================================
;;; HINGE THEOREM 2 (Semantic B → Denial Trigger Fires)
;;;
;;; Under Semantic B, if the official exercises discretionary denial
;;; AND the applicant lacks documentary proof, the denial trigger fires.
;;; =========================================================================

(defthm hinge-semantic-b-denial-trigger-fires
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
;;; HINGE THEOREM 3 (Semantic B → Statute Denies Registration)
;;;
;;; Extending Hinge 2: under Semantic B, the statute ALSO denies
;;; registration (via text-save-act-documentary-proof-requirement).
;;; =========================================================================

(defthm hinge-semantic-b-statute-denies
  (implies
   (and (official-discretionary-denialp p x)
        (personp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (not (presents-documentary-proofp p x)))
   (statute-denies-registrationp 'federal-save-act p x))
  :rule-classes nil)
