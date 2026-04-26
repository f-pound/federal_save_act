(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_hinge_common.lisp  —  v5.2
;; Shared definitions for the alternative-attestation semantic hinge.
;;
;; This book introduces the NEW predicates used by both the mandatory
;; and discretionary interpretations, without committing to either.
;;
;; Source: SAVE Act § 2(f) / NVRA § 8(j)(2)(A)
;;
;; IMPORTANT: This book is included by BOTH hinge_mandatory.lisp and
;; hinge_discretionary.lisp. However, those two books CANNOT be loaded
;; in the same ACL2 session because they constrain alternative-process-approvedp
;; in opposite directions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; Shared vocabulary: new predicates for attestation semantics
;;; =========================================================================

(encapsulate
  ((attestation-evidence-satisfies-standardsp (p x) t)
   (official-discretionary-denialp (p x) t))

  ;; Witness model: both predicates return t.
  ;; This is consistent because we export no constraints linking them
  ;; to each other or to core predicates — the bridge rules are in
  ;; the separate mandatory/discretionary books.
  (local (defun attestation-evidence-satisfies-standardsp (p x)
    (declare (ignore p x)) t))
  (local (defun official-discretionary-denialp (p x)
    (declare (ignore p x)) t))

  ;; Type prescriptions only — no substantive constraints
  (defthm hinge-evidence-type
    (booleanp (attestation-evidence-satisfies-standardsp p x))
    :rule-classes :type-prescription)
  (defthm hinge-denial-type
    (booleanp (official-discretionary-denialp p x))
    :rule-classes :type-prescription))

;;; =========================================================================
;;; Shared structural theorems
;;; =========================================================================

;; The denial trigger requires both no-presentation AND no-alternative.
;; This is a re-export from the core for convenience of the hinge books.
(defthm hinge-common-presentation-defeats-denial
  (implies (presents-documentary-proofp p x)
           (not (save-act-denial-triggerp p x))))

(defthm hinge-common-alternative-defeats-denial
  (implies (alternative-process-approvedp p x)
           (not (save-act-denial-triggerp p x))))
