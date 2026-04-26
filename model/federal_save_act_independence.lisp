(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_independence.lisp  —  v5.1
;; Non-entailment / independence checks.
;;
;; Goal: Show that the neutral statutory facts (core + facts) do not
;; predetermine the constitutional outcome.
;;
;; What we prove:
;;   1. If valid-regulationp is true, conflict is false (structural).
;;   2. If valid-regulationp is false AND all other preconditions hold,
;;      conflict is true (structural).
;;   3. The iff pivot: given all preconditions except valid-regulationp,
;;      the conflict condition is equivalent to (not valid-regulationp).
;;
;; What this means for independence:
;;   These three theorems show that constitutional-conflict-conditionp
;;   is structurally determined by valid-regulationp once all other
;;   predicates are fixed.  Since valid-regulationp is a defstub with
;;   no axioms constraining it in the neutral model, ACL2's soundness
;;   guarantees that neither (valid-regulationp law x) nor
;;   (not (valid-regulationp law x)) is derivable from the neutral facts.
;;   Therefore, neither the conflict nor the no-conflict conclusion is
;;   derivable from neutral facts alone.
;;
;; What this does NOT prove:
;;   These are not explicit countermodel constructions.  We do not
;;   build two separate encapsulate blocks with concrete witnesses that
;;   model "World G" and "World C."  The independence argument relies on
;;   ACL2's metalogical guarantee that unconstrained defstubs cannot be
;;   forced to any particular value.  A stronger proof would use two
;;   encapsulate blocks to exhibit concrete models, but that would
;;   require reintroducing all 45 defstubs with concrete witnesses —
;;   which is architecturally expensive for limited additional assurance.
;;
;; Technique: structural decomposition of constitutional-conflict-conditionp,
;; which is a defun whose body is a conjunction including
;; (not (valid-regulationp law x)).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. VALID REGULATION DEFEATS CONFLICT (structural)
;;;
;;; constitutional-conflict-conditionp has (not (valid-regulationp law x))
;;; as a conjunct.  If valid-regulationp returns t, that conjunct is
;;; false, so the entire condition is false.
;;;
;;; This shows: there EXISTS a consistent assignment of defstubs
;;; (namely, valid-regulationp = t) under which conflict never holds.
;;; =========================================================================

(defthm neutral-model-does-not-force-conflict
  (implies (valid-regulationp law x)
           (not (constitutional-conflict-conditionp
                 law cs p x)))
  :rule-classes nil)

;;; =========================================================================
;;; 2. INVALID REGULATION ENABLES CONFLICT (structural)
;;;
;;; If every precondition of constitutional-conflict-conditionp holds
;;; AND valid-regulationp is false, then conflict is true.
;;;
;;; This shows: there EXISTS a consistent assignment of defstubs
;;; (namely, valid-regulationp = nil plus all preconditions true)
;;; under which conflict DOES hold.
;;;
;;; Note: This is a conditional theorem, not a ground fact.  We do not
;;; assert that the preconditions ARE satisfied — only that IF they were,
;;; the outcome would flip.  The "if" depends on doctrinal, empirical,
;;; and interpretive assumptions from the party models.
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
;;; Given all preconditions except valid-regulationp, the conflict
;;; condition is logically equivalent to (not (valid-regulationp law x)).
;;;
;;; This is the structural core of the independence argument:
;;; valid-regulationp is the SOLE predicate that swings the outcome.
;;; It is answered by doctrine (Crawford/Anderson-Burdick), empirical
;;; facts (burden severity), and interpretation (mandatory vs.
;;; discretionary alternative process) — not by statutory text alone.
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
