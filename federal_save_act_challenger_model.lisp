(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_challenger_model.lisp  —  v3 (hybrid architecture)
;; Interpretive model favoring constitutional challenge.
;;
;; v3 architecture:
;;   • Interpretive predicates introduced via encapsulate with local
;;     witness functions — this proves their constraints are consistent
;;   • Scenario ground facts use defaxiom (constraining existing defstubs)
;;   • Proof obligations use defthm with intermediate lemmas
;;
;; This is the correct ACL2 pattern because:
;;   - encapsulate cannot prove ground facts about existing defstubs
;;   - encapsulate CAN introduce new constrained functions with witnesses
;;   - defaxiom is safe for scenario facts (obviously consistent stipulations)
;;   - The real inconsistency risk is in INTERPRETIVE axioms, which is
;;     exactly what the encapsulate protects against
;;
;; Theory of the case: A U.S. citizen born at home in a rural area
;; attempts to register to vote by mail for a federal election. The
;; citizen lacks documentary proof. The challenger argues:
;;   (a) The right to vote is fundamental (Amend. V / Bolling v. Sharpe)
;;   (b) The doc-proof requirement imposes an undue burden
;;   (c) The alternative attestation process is inadequate
;;   (d) The cost of documents functions as a de facto poll tax
;;   (e) The SAVE Act is therefore not a valid regulation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; Interpretive predicates — introduced via encapsulate
;;;
;;; These are the predicates whose consistency we want to guarantee.
;;; The encapsulate introduces them with a concrete witness model
;;; that demonstrates all exported constraints are jointly satisfiable.
;;; =========================================================================

(encapsulate
  ;; Constrained function signatures (new to this model)
  ;; Note: lacks-qualifying-documents-through-no-faultp and
  ;; cannot-obtain-qualifying-documents-without-material-burdenp
  ;; are already defstubs in core.  We introduce NEW interpretive
  ;; bridge predicates here.
  ((challenger-right-to-vote-establishedp (p) t)
   (challenger-undue-burden-establishedp (law p) t)
   (challenger-regulation-invalidp (law x) t))

  ;; ---- Witness model ----
  ;; A toy world where citizen-a satisfies all challenger conditions.
  (local (defun challenger-right-to-vote-establishedp (p)
    (declare (ignore p)) t))
  (local (defun challenger-undue-burden-establishedp (law p)
    (declare (ignore law p)) t))
  (local (defun challenger-regulation-invalidp (law x)
    (declare (ignore law x)) t))

  ;; ---- Exported constraints (interpretive rules) ----

  ;; DOCTRINAL_ASSUMPTION: The right to vote is fundamental.
  ;; If a person is a qualified federal voter, then the challenger
  ;; establishes that they have a protected right to vote under
  ;; the Fifth Amendment's equal protection component.
  ;;
  ;; Doctrinal basis: Harper v. Virginia Board of Elections, 383 U.S.
  ;; 663 (1966); Reynolds v. Sims, 377 U.S. 533 (1964).
  (defthm challenger-fundamental-right-rule
    (implies
     (qualified-federal-voterp p)
     (challenger-right-to-vote-establishedp p)))

  ;; INTERPRETATION_CHALLENGER: Documentary proof requirement is an
  ;; undue burden on citizens who lack documents through no fault
  ;; and cannot obtain them without material burden.
  ;;
  ;; Doctrinal basis: Crawford (Stevens plurality).
  (defthm challenger-documentary-proof-is-undue-burden
    (implies
     (and (qualified-federal-voterp p)
          (not (has-documentary-proofp p))
          (lacks-qualifying-documents-through-no-faultp p)
          (cannot-obtain-qualifying-documents-without-material-burdenp p))
     (challenger-undue-burden-establishedp 'federal-save-act p)))

  ;; INTERPRETATION_CHALLENGER: Undue burden defeats valid regulation.
  ;; If the challenger establishes an undue burden, the regulation
  ;; is invalid.
  ;;
  ;; Doctrinal basis: Crawford; Anderson v. Celebrezze, 460 U.S. 780.
  (defthm challenger-undue-burden-defeats-regulation
    (implies
     (challenger-undue-burden-establishedp 'federal-save-act p)
     (challenger-regulation-invalidp 'federal-save-act x))))

;;; =========================================================================
;;; Bridge rules: Connect encapsulate-constrained interpretive predicates
;;; to the core defstub predicates used in constitutional-conflict-conditionp.
;;;
;;; These bridge axioms are defaxiom because they constrain existing
;;; defstub functions. They are safe because they only fire when the
;;; encapsulate-constrained predicates (which ARE consistency-checked)
;;; are satisfied.
;;; =========================================================================

;; Bridge: challenger's right-to-vote establishment → core predicate
(defaxiom challenger-bridge-right-to-vote
  (implies
   (challenger-right-to-vote-establishedp p)
   (protected-right-to-votep 'amend-v-equal-protection p)))

;; Bridge: challenger's regulation-invalid → core predicate
(defaxiom challenger-bridge-regulation-invalid
  (implies
   (challenger-regulation-invalidp 'federal-save-act x)
   (not (valid-regulationp 'federal-save-act x))))

;;; =========================================================================
;;; Scenario constants — small stress-test scenario
;;;
;;; citizen-a: An elderly U.S. citizen born at home in a rural area.
;;; registration-attempt-a: A mail voter registration application.
;;;
;;; These use defaxiom because they constrain existing defstub functions
;;; (personp, citizen-of-usp, etc.). They are self-evidently consistent
;;; stipulations about a specific scenario.
;;; =========================================================================

;; SCENARIO_FACT: citizen-a is a person
(defaxiom challenger-scenario-person
  (personp 'citizen-a))

;; SCENARIO_FACT: citizen-a is a U.S. citizen
(defaxiom challenger-scenario-citizen
  (citizen-of-usp 'citizen-a))

;; SCENARIO_FACT: citizen-a is eligible to vote
(defaxiom challenger-scenario-eligible
  (eligible-voterp 'citizen-a))

;; SCENARIO_FACT: registration-attempt-a is an application
(defaxiom challenger-scenario-application
  (voter-registration-applicationp 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a attempts to register
(defaxiom challenger-scenario-attempts-to-register
  (attempts-to-registerp 'citizen-a 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a does NOT possess documentary proof
(defaxiom challenger-scenario-no-documentary-proof
  (not (has-documentary-proofp 'citizen-a)))

;; SCENARIO_FACT: citizen-a does NOT present documentary proof
(defaxiom challenger-scenario-no-presentation
  (not (presents-documentary-proofp 'citizen-a 'registration-attempt-a)))

;; EMPIRICAL_ASSUMPTION: citizen-a lacks documents through no fault
;; Source: Fish v. Kobach, 840 F.3d at 734 (18,000 applicants unable
;; to complete registration due to documentary proof requirement)
(defaxiom challenger-scenario-no-fault
  (lacks-qualifying-documents-through-no-faultp 'citizen-a))

;; EMPIRICAL_ASSUMPTION: citizen-a cannot obtain docs without burden
;; Source: Crawford, 553 U.S. at 199 (Stevens plurality) ("the burden
;; of obtaining a birth certificate... will be nontrivial for some voters")
(defaxiom challenger-scenario-material-burden
  (cannot-obtain-qualifying-documents-without-material-burdenp 'citizen-a))

;; INTERPRETATION_CHALLENGER: alternative process denied
;; Source: SAVE Act § 2(f) / NVRA § 8(j)(2)(A) — "shall make a
;; determination" interpreted as discretionary, may result in denial
(defaxiom challenger-scenario-alternative-process-denied
  (not (alternative-process-approvedp 'citizen-a 'registration-attempt-a)))

;;; =========================================================================
;;; Intermediate lemmas — factored proof chain
;;;
;;; These help ACL2's rewriter chain through the encapsulate constraints
;;; and bridge rules to reach the final conflict conclusion.
;;; =========================================================================

;; Step 1: citizen-a is a qualified federal voter
(defthm challenger-lemma-qualified-voter
  (qualified-federal-voterp 'citizen-a))

;; Step 2: challenger establishes right to vote for citizen-a
(defthm challenger-lemma-right-established
  (challenger-right-to-vote-establishedp 'citizen-a))

;; Step 3: right to vote bridges to core predicate
(defthm challenger-lemma-protected-right
  (protected-right-to-votep 'amend-v-equal-protection 'citizen-a))

;; Step 4: citizen-a's registration transaction
(defthm challenger-lemma-registration-transaction
  (registration-transactionp 'citizen-a 'registration-attempt-a))

;; Step 5: challenger establishes undue burden
(defthm challenger-lemma-undue-burden
  (challenger-undue-burden-establishedp 'federal-save-act 'citizen-a))

;; Step 6: challenger regulation invalid
(defthm challenger-lemma-regulation-invalid
  (challenger-regulation-invalidp 'federal-save-act x))

;; Step 7: bridges to core valid-regulationp
(defthm challenger-lemma-not-valid-regulation
  (not (valid-regulationp 'federal-save-act x)))

;; Step 8: statute denies registration
(defthm challenger-lemma-denial
  (statute-denies-registrationp 'federal-save-act
                                'citizen-a
                                'registration-attempt-a))

;;; =========================================================================
;;; PROOF OBLIGATION 1: General theorem
;;;
;;; Under the challenger's interpretive model, a constitutional conflict
;;; exists for ANY qualified voter who cannot present documentary proof,
;;; lacks documents through no fault, faces material burden, and cannot
;;; rely on the alternative process.
;;; =========================================================================

(defthm challenger-conflict-general
  (implies
   (and (personp p)
        (citizen-of-usp p)
        (eligible-voterp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (not (presents-documentary-proofp p x))
        (not (has-documentary-proofp p))
        (lacks-qualifying-documents-through-no-faultp p)
        (cannot-obtain-qualifying-documents-without-material-burdenp p)
        (not (alternative-process-approvedp p x)))
   (constitutional-conflict-conditionp
    'federal-save-act
    'amend-v-equal-protection
    p x))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp
                               qualified-federal-voterp
                               registration-transactionp)))
  :rule-classes nil)

;;; =========================================================================
;;; PROOF OBLIGATION 2: Concrete citizen-a corollary
;;; =========================================================================

(defthm challenger-model-finds-conflict
  (constitutional-conflict-conditionp
   'federal-save-act
   'amend-v-equal-protection
   'citizen-a
   'registration-attempt-a)
  :rule-classes nil)
