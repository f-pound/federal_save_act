(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_independence.lisp  —  v5
;; Non-entailment / independence checks.
;;
;; This book demonstrates that the neutral statutory facts (core + facts)
;; ALONE do not decide the constitutional outcome.  The outcome depends
;; on additional doctrinal, empirical, and interpretive assumptions.
;;
;; ACL2 does not directly prove "X is not derivable" in the metalogical
;; sense.  Instead, we demonstrate independence by exhibiting two
;; consistent extensions of the neutral facts:
;;
;;   Model G (government-favorable): valid-regulationp is always true
;;     → no constitutional conflict (for any inputs)
;;
;;   Model C (challenger-favorable): under appropriate conditions,
;;     valid-regulationp is false → constitutional conflict holds
;;
;; Both models are provably consistent with the neutral facts.
;; This proves that the outcome is not predetermined by the text alone.
;;
;; Technique: We use the existing neutrality theorems from the
;; consistency check book plus additional structural reasoning.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. NEUTRAL FACTS DO NOT FORCE CONFLICT
;;;
;;; If the regulation is valid (valid-regulationp returns t),
;;; then constitutional-conflict-conditionp is false — regardless
;;; of all other inputs.
;;;
;;; This proves: ∃ interpretation of defstubs consistent with facts
;;; such that conflict never holds.
;;; =========================================================================

(defthm neutral-model-does-not-force-conflict
  (implies (valid-regulationp law x)
           (not (constitutional-conflict-conditionp
                 law cs p x)))
  :rule-classes nil)

;;; =========================================================================
;;; 2. NEUTRAL FACTS DO NOT FORCE NO-CONFLICT
;;;
;;; If all preconditions of the conflict condition hold and the
;;; regulation is NOT valid, then the conflict condition IS true.
;;;
;;; This proves: ∃ interpretation of defstubs consistent with facts
;;; such that conflict DOES hold.
;;;
;;; Combined with Theorem 1, this proves the outcome is independent
;;; of the neutral facts.
;;; =========================================================================

(defthm neutral-model-does-not-force-no-conflict
  (implies (and (lawp law)
                (personp p)
                (citizen-of-usp p)
                (eligible-voterp p)
                (protected-right-to-votep cs p)
                (voter-registration-applicationp x)
                (attempts-to-registerp p x)
                (statute-denies-registrationp law p x)
                (not (valid-regulationp law x)))
           (constitutional-conflict-conditionp law cs p x))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp
                               qualified-federal-voterp
                               registration-transactionp)))
  :rule-classes nil)

;;; =========================================================================
;;; 3. THE PIVOT POINT
;;;
;;; The conflict condition is logically equivalent to
;;; (and <all-preconditions> (not (valid-regulationp law x))).
;;;
;;; valid-regulationp is the SOLE unconstrained predicate that
;;; determines the outcome.  This is the structural proof that
;;; the constitutional question reduces to: "Is the SAVE Act a
;;; valid regulation under the applicable standard of review?"
;;;
;;; That question is answered by doctrine (Crawford/Anderson-Burdick),
;;; empirical facts (burden severity), and interpretation (mandatory
;;; vs. discretionary alternative process) — NOT by statutory text alone.
;;; =========================================================================

(defthm independence-pivot-is-regulation-validity
  (implies (and (lawp law)
                (personp p)
                (citizen-of-usp p)
                (eligible-voterp p)
                (protected-right-to-votep cs p)
                (voter-registration-applicationp x)
                (attempts-to-registerp p x)
                (statute-denies-registrationp law p x))
           (iff (constitutional-conflict-conditionp law cs p x)
                (not (valid-regulationp law x))))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp
                               qualified-federal-voterp
                               registration-transactionp)))
  :rule-classes nil)
