(in-package "ACL2")

(include-book "federal_save_act_core")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_functional_instantiation.lisp  —  v6.5
;;
;; The party models introduce their legal theories as ENCAPSULATEd
;; predicates (e.g. government-defense-establishedp) constrained by an
;; implication, with a trivial local witness (constantly t) that proves
;; the constraint consistent.  A reviewer may reasonably ask: is anything
;; other than the trivial witness a model of that constraint?  And does the
;; reasoning done about the constrained predicate transfer to a concrete
;; one?
;;
;; This book answers both with ACL2's :functional-instance mechanism, in a
;; self-contained way that does not load either party book (so it is
;; NEUTRAL — no defaxiom):
;;
;;   1. A local encapsulate re-states the government constraint on an
;;      abstract predicate gov-defense-p and proves a generic theorem:
;;      if the six factors hold then the conflict condition fails,
;;      PROVIDED gov-defense-p validates the regulation.
;;   2. A concrete predicate gov-defense-concrete is DEFINED as the
;;      conjunction of the six factors.
;;   3. The generic theorem is instantiated, via :functional-instance, at
;;      the concrete predicate.  ACL2 discharges the constraint as a proof
;;      obligation — i.e. proves the concrete predicate really satisfies
;;      the encapsulate's exported constraint.
;;
;; This is the "functional instantiation" item left open in v5.3.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(encapsulate
  ((gov-defense-p (law) t))
  (local (defun gov-defense-p (law) (declare (ignore law)) t))
  (defthm gov-defense-p-constraint
    (implies (and (important-government-interestp law)
                  (election-integrity-interestp law)
                  (reasonable-registration-requirementp law)
                  (registration-procedure-evenhandedp law)
                  (documentary-proof-requirement-rationally-connectedp law)
                  (adequate-alternative-processp law))
             (gov-defense-p law))))

;; Generic result about the abstract predicate.  Note the explicit bridge
;; hypothesis: validity is NOT assumed, it is a premise of the theorem.
(defthm generic-defense-defeats-conflict
  (implies (and (important-government-interestp law)
                (election-integrity-interestp law)
                (reasonable-registration-requirementp law)
                (registration-procedure-evenhandedp law)
                (documentary-proof-requirement-rationally-connectedp law)
                (adequate-alternative-processp law)
                (implies (gov-defense-p law) (valid-regulationp law x)))
           (not (constitutional-conflict-conditionp law cs p x)))
  :rule-classes nil)

;; A concrete, non-trivial model of the constraint.
(defun gov-defense-concrete (law)
  (and (important-government-interestp law)
       (election-integrity-interestp law)
       (reasonable-registration-requirementp law)
       (registration-procedure-evenhandedp law)
       (documentary-proof-requirement-rationally-connectedp law)
       (adequate-alternative-processp law)))

;; Transfer by functional instantiation.  ACL2 generates and proves the
;; obligation that gov-defense-concrete satisfies gov-defense-p-constraint.
(defthm concrete-defense-defeats-conflict
  (implies (and (important-government-interestp law)
                (election-integrity-interestp law)
                (reasonable-registration-requirementp law)
                (registration-procedure-evenhandedp law)
                (documentary-proof-requirement-rationally-connectedp law)
                (adequate-alternative-processp law)
                (implies (gov-defense-concrete law) (valid-regulationp law x)))
           (not (constitutional-conflict-conditionp law cs p x)))
  :hints (("Goal" :use ((:functional-instance generic-defense-defeats-conflict
                                               (gov-defense-p gov-defense-concrete)))))
  :rule-classes nil)

;; The same for the challenger side: an abstract "undue burden established"
;; predicate and a concrete conjunction of the challenger's factual
;; premises, with the bridge stated as a hypothesis.
(encapsulate
  ((chal-burden-p (p) t))
  (local (defun chal-burden-p (p) (declare (ignore p)) t))
  (defthm chal-burden-p-constraint
    (implies (and (qualified-federal-voterp p)
                  (not (has-documentary-proofp p))
                  (lacks-qualifying-documents-through-no-faultp p)
                  (cannot-obtain-qualifying-documents-without-material-burdenp p))
             (chal-burden-p p))))

(defthm generic-burden-enables-conflict
  (implies (and (lawp law)
                (qualified-federal-voterp p)
                (protected-right-to-votep cs p)
                (registration-transactionp p x)
                (statute-denies-registrationp law p x)
                (not (has-documentary-proofp p))
                (lacks-qualifying-documents-through-no-faultp p)
                (cannot-obtain-qualifying-documents-without-material-burdenp p)
                (implies (chal-burden-p p) (not (valid-regulationp law x))))
           (constitutional-conflict-conditionp law cs p x))
  :rule-classes nil)

(defun chal-burden-concrete (p)
  (and (qualified-federal-voterp p)
       (not (has-documentary-proofp p))
       (lacks-qualifying-documents-through-no-faultp p)
       (cannot-obtain-qualifying-documents-without-material-burdenp p)))

(defthm concrete-burden-enables-conflict
  (implies (and (lawp law)
                (qualified-federal-voterp p)
                (protected-right-to-votep cs p)
                (registration-transactionp p x)
                (statute-denies-registrationp law p x)
                (not (has-documentary-proofp p))
                (lacks-qualifying-documents-through-no-faultp p)
                (cannot-obtain-qualifying-documents-without-material-burdenp p)
                (implies (chal-burden-concrete p) (not (valid-regulationp law x))))
           (constitutional-conflict-conditionp law cs p x))
  :hints (("Goal" :use ((:functional-instance generic-burden-enables-conflict
                                               (chal-burden-p chal-burden-concrete)))))
  :rule-classes nil)
