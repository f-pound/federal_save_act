(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_existentials.lisp  —  v5
;; Existential burden modeling with defun-sk.
;;
;; Legal burden analysis depends on EXISTENCE claims:
;;   "There exists an eligible citizen who..."
;; not just named examples like 'citizen-a.
;;
;; This book uses defun-sk to introduce Skolemized existential
;; propositions and proves bridge theorems connecting the witnesses
;; to the challenger-side burden predicates.
;;
;; defun-sk with (exists p body):
;;   - defines (foo) = (let ((p (foo-witness))) body)
;;   - generates (defthm foo-suff (implies body (foo)))
;;   - the witness (foo-witness) satisfies body when (foo) is true
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. EXISTENTIAL PROPOSITIONS
;;; =========================================================================

;; There exists an eligible citizen who lacks qualifying documentary proof.
(defun-sk exists-citizen-lacking-proofp ()
  (exists p (and (personp p)
                 (citizen-of-usp p)
                 (eligible-voterp p)
                 (not (has-documentary-proofp p)))))

;; There exists an eligible citizen who cannot reasonably obtain
;; qualifying documents without material burden.
(defun-sk exists-citizen-with-unreasonable-burdenp ()
  (exists p (and (personp p)
                 (citizen-of-usp p)
                 (eligible-voterp p)
                 (not (has-documentary-proofp p))
                 (cannot-obtain-qualifying-documents-without-material-burdenp p))))

;; There exists an eligible citizen who lacks documents through no fault.
(defun-sk exists-citizen-lacking-docs-no-faultp ()
  (exists p (and (personp p)
                 (citizen-of-usp p)
                 (eligible-voterp p)
                 (not (has-documentary-proofp p))
                 (lacks-qualifying-documents-through-no-faultp p))))

;;; =========================================================================
;;; 2. BRIDGE THEOREMS
;;;
;;; These connect the existential witnesses to the structural burden
;;; predicates, showing that the existence of one burdened citizen
;;; implies the existence of the broader class.
;;;
;;; Strategy: Open the definition of the stronger existential to get
;;; the witness's properties, then use -suff for the weaker existential.
;;; =========================================================================

;; If a citizen with unreasonable burden exists, then a citizen lacking
;; proof also exists (the stronger condition implies the weaker one).
(defthm exists-burdened-citizen-implies-lacking-proof
  (implies (exists-citizen-with-unreasonable-burdenp)
           (exists-citizen-lacking-proofp))
  :hints (("Goal"
           :use ((:instance exists-citizen-lacking-proofp-suff
                            (p (exists-citizen-with-unreasonable-burdenp-witness))))
           :in-theory (enable exists-citizen-with-unreasonable-burdenp)))
  :rule-classes nil)

;; If a citizen lacking docs through no fault exists, then a citizen
;; lacking proof exists.
(defthm exists-no-fault-citizen-implies-lacking-proof
  (implies (exists-citizen-lacking-docs-no-faultp)
           (exists-citizen-lacking-proofp))
  :hints (("Goal"
           :use ((:instance exists-citizen-lacking-proofp-suff
                            (p (exists-citizen-lacking-docs-no-faultp-witness))))
           :in-theory (enable exists-citizen-lacking-docs-no-faultp)))
  :rule-classes nil)

;;; =========================================================================
;;; 3. WITNESS CONNECTION
;;;
;;; If the existential is satisfied, the Skolem witness has the
;;; properties needed for the challenger's scenario.
;;; =========================================================================

;; The witness from exists-citizen-with-unreasonable-burdenp is a
;; qualified federal voter.
(defthm unreasonable-burden-witness-is-qualified
  (implies (exists-citizen-with-unreasonable-burdenp)
           (qualified-federal-voterp
            (exists-citizen-with-unreasonable-burdenp-witness)))
  :hints (("Goal"
           :in-theory (enable exists-citizen-with-unreasonable-burdenp
                              qualified-federal-voterp)))
  :rule-classes nil)
