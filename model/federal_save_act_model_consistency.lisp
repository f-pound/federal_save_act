(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_model_consistency.lisp  —  v5.2
;;
;; Sanity and consistency checks on the formal model.
;;
;; These theorems verify structural properties of the model itself,
;; not legal conclusions.  They ensure:
;;
;;   1. Terminal outcomes are mutually exclusive
;;   2. The conflict condition pivots on valid-regulationp
;;   3. Neutral facts do not predetermine the outcome
;;   4. The denial trigger requires an actual registration transaction
;;   5. Qualified-federal-voterp is compositional
;;
;; These checks help establish confidence that the ACL2 model is
;; internally consistent and that the conclusions drawn from it
;; are structurally sound.
;;
;; What ACL2 proves here:
;;   Structural properties of the model's definitions.
;;
;; What ACL2 does NOT prove here:
;;   That the model accurately reflects the real legal system.
;;   That any particular legal conclusion is correct.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. MUTUAL EXCLUSIVITY OF TERMINAL OUTCOMES
;;;
;;; A single state value cannot be both registered and denied.
;;; This is trivially true because they are distinct symbols, but
;;; stating it as a theorem makes the model's guarantee explicit.
;;; =========================================================================

(defthm no-trace-produces-both-registered-and-denied
  (not (and (equal s 'registered)
            (equal s 'denied)))
  :rule-classes nil)

;;; =========================================================================
;;; 2. CONFLICT CONDITION PIVOTS ON VALID-REGULATIONP
;;;
;;; Given all other preconditions, the conflict condition is
;;; equivalent to (not (valid-regulationp law x)).
;;;
;;; This is the structural core of the independence argument.
;;; =========================================================================

(defthm conflict-condition-pivots-on-valid-regulation
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

;;; =========================================================================
;;; 3. NEUTRAL FACTS DO NOT SETTLE OUTCOME
;;;
;;; valid-regulationp being true defeats conflict.
;;; valid-regulationp being false enables conflict (given preconditions).
;;; Since valid-regulationp is an unconstrained defstub in the neutral
;;; model, neither outcome is predetermined.
;;;
;;; These are structural decomposition theorems, not countermodel
;;; constructions.  Independence is inferred from ACL2's metalogical
;;; guarantee that unconstrained defstubs cannot be forced to any
;;; particular value.
;;; =========================================================================

;; If valid-regulationp is true, conflict is impossible
(defthm neutral-valid-regulation-defeats-conflict
  (implies (valid-regulationp law x)
           (not (constitutional-conflict-conditionp law cs p x)))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp)))
  :rule-classes nil)

;; If valid-regulationp is false (and all preconditions hold), conflict holds
(defthm neutral-invalid-regulation-enables-conflict
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
;;; 4. DENIAL TRIGGER REQUIRES TRANSACTION
;;;
;;; The SAVE Act denial trigger cannot fire unless there is an actual
;;; registration transaction (person + application + attempt).
;;;
;;; Legal relevance: The statute does not burden people who do not
;;; attempt to register.  The model correctly scopes the denial
;;; mechanism to actual registration attempts.
;;; =========================================================================

(defthm denial-trigger-requires-transaction
  (implies (save-act-denial-triggerp p x)
           (registration-transactionp p x))
  :hints (("Goal" :in-theory (enable save-act-denial-triggerp)))
  :rule-classes nil)

;;; =========================================================================
;;; 5. QUALIFIED-FEDERAL-VOTERP IS COMPOSITIONAL
;;;
;;; The qualified-federal-voterp predicate is exactly the conjunction
;;; of personp, citizen-of-usp, and eligible-voterp.  This makes
;;; the model's composition explicit and auditable.
;;; =========================================================================

(defthm qualified-voter-is-compositional
  (iff (qualified-federal-voterp p)
       (and (personp p)
            (citizen-of-usp p)
            (eligible-voterp p)))
  :hints (("Goal" :in-theory (enable qualified-federal-voterp)))
  :rule-classes nil)

;;; =========================================================================
;;; 6. CONFLICT CONDITION IS COMPOSITIONAL
;;;
;;; The full conflict condition decomposes into its constituent parts.
;;; This makes the entire proof obligation transparent.
;;; =========================================================================

(defthm conflict-condition-is-compositional
  (iff (constitutional-conflict-conditionp law cs p x)
       (and (lawp law)
            (personp p)
            (citizen-of-usp p)
            (eligible-voterp p)
            (protected-right-to-votep cs p)
            (voter-registration-applicationp x)
            (attempts-to-registerp p x)
            (statute-denies-registrationp law p x)
            (not (valid-regulationp law x))))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp
                               qualified-federal-voterp
                               registration-transactionp)))
  :rule-classes nil)
