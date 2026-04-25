(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_government_model.lisp  —  v3 (hybrid architecture)
;; Interpretive model favoring government defense of the SAVE Act.
;;
;; v3 architecture:
;;   • Interpretive predicates introduced via encapsulate with local
;;     witness functions — this proves their constraints are consistent
;;   • Scenario ground facts use defaxiom (constraining existing defstubs)
;;   • Proof obligations use defthm with intermediate lemmas
;;
;; Theory of the case: The government argues that the SAVE Act is a
;; valid exercise of Congress's power under the Elections Clause to
;; protect federal election integrity.
;;   (a) Congress has broad authority under Art. I, § 4
;;   (b) The doc-proof requirement serves an important interest
;;   (c) The requirement is reasonable, evenhanded, and rationally connected
;;   (d) The alternative process is constitutionally adequate
;;   (e) The SAVE Act is therefore a valid regulation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; Interpretive predicates — introduced via encapsulate
;;;
;;; The government introduces defense predicates that, when all satisfied,
;;; establish that the SAVE Act is a valid regulation. The encapsulate
;;; guarantees these constraints are jointly consistent.
;;; =========================================================================

(encapsulate
  ;; Constrained function signatures (new to this model)
  ((government-defense-establishedp (law) t))

  ;; ---- Witness model ----
  ;; The witness returns t unconditionally.  This is safe because the
  ;; exported constraint is an implication — the hypothesis conditions
  ;; (important-government-interestp etc.) guard when it fires.
  (local (defun government-defense-establishedp (law)
    (declare (ignore law)) t))

  ;; ---- Exported constraints ----

  ;; INTERPRETATION_GOVERNMENT: Valid regulation rule (5-factor test)
  ;; If the SAVE Act serves an important government interest, has an
  ;; election integrity interest, imposes a reasonable requirement,
  ;; the procedure is evenhanded, the requirement is rationally connected,
  ;; and an adequate alternative process exists, then the government
  ;; defense is established.
  ;;
  ;; Doctrinal basis: Crawford v. Marion County Election Bd., 553 U.S.
  ;; 181 (2008); Anderson v. Celebrezze, 460 U.S. 780 (1983).
  (defthm government-valid-regulation-rule
    (implies
     (and (important-government-interestp law)
          (election-integrity-interestp law)
          (reasonable-registration-requirementp law)
          (registration-procedure-evenhandedp law)
          (documentary-proof-requirement-rationally-connectedp law)
          (adequate-alternative-processp law))
     (government-defense-establishedp law))))

;;; =========================================================================
;;; Bridge rule: Government defense → core valid-regulationp
;;;
;;; When the government defense is established, the regulation IS valid
;;; under the core vocabulary, defeating the constitutional conflict.
;;; =========================================================================

(defaxiom government-bridge-defense-validates
  (implies
   (government-defense-establishedp law)
   (valid-regulationp law x)))

;;; =========================================================================
;;; Government interpretive axioms — each defense factor
;;;
;;; These constrain existing defstubs from core.lisp, so they use
;;; defaxiom. Each is a simple ground fact about 'federal-save-act.
;;; =========================================================================

;; POLICY_ASSUMPTION: Election integrity interest
(defaxiom government-election-integrity-interest
  (election-integrity-interestp 'federal-save-act))

;; POLICY_ASSUMPTION: The interest is important
(defaxiom government-important-interest
  (important-government-interestp 'federal-save-act))

;; INTERPRETATION_GOVERNMENT: The requirement is reasonable
;; Doctrinal basis: Crawford — Indiana's photo ID upheld as reasonable.
(defaxiom government-reasonable-requirement
  (reasonable-registration-requirementp 'federal-save-act))

;; INTERPRETATION_GOVERNMENT: The procedure is evenhanded
(defaxiom government-procedure-evenhanded
  (registration-procedure-evenhandedp 'federal-save-act))

;; INTERPRETATION_GOVERNMENT: Rational connection
(defaxiom government-rationally-connected
  (documentary-proof-requirement-rationally-connectedp 'federal-save-act))

;; INTERPRETATION_GOVERNMENT: Alternative process is adequate
;; Doctrinal basis: Crawford — availability of provisional ballots
;; and free ID cards was relevant to upholding Indiana's voter ID law.
(defaxiom government-adequate-alternative
  (adequate-alternative-processp 'federal-save-act))

;; INTERPRETATION_GOVERNMENT: Burden is not severe
(defaxiom government-burden-not-severe
  (burden-not-severep 'federal-save-act p))

;;; =========================================================================
;;; Scenario constants — same scenario as challenger model
;;;
;;; The government concedes the factual scenario but reaches a different
;;; conclusion because the regulation is valid.
;;; =========================================================================

;; SCENARIO_FACT: citizen-a is a person
(defaxiom government-scenario-person
  (personp 'citizen-a))

;; SCENARIO_FACT: citizen-a is a U.S. citizen
(defaxiom government-scenario-citizen
  (citizen-of-usp 'citizen-a))

;; SCENARIO_FACT: citizen-a is eligible to vote
(defaxiom government-scenario-eligible
  (eligible-voterp 'citizen-a))

;; SCENARIO_FACT: registration-attempt-a is an application
(defaxiom government-scenario-application
  (voter-registration-applicationp 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a attempts to register
(defaxiom government-scenario-attempts-to-register
  (attempts-to-registerp 'citizen-a 'registration-attempt-a))

;; INTERPRETATION_GOVERNMENT: Concede arguendo that citizen-a has a
;; protected right to vote. This strengthens the proof — no-conflict
;; results from valid-regulationp, not from failure to establish the right.
(defaxiom government-assume-right-to-vote-arguendo
  (protected-right-to-votep 'amend-v-equal-protection 'citizen-a))

;; SCENARIO_FACT: citizen-a lacks documentary proof (conceded)
(defaxiom government-scenario-no-documentary-proof
  (not (has-documentary-proofp 'citizen-a)))

;; INTERPRETATION_GOVERNMENT: the alternative process IS available and
;; adequate for citizen-a. Under the government's theory, citizen-a
;; CAN be registered through the alternative attestation process.
;;
;; This is the KEY divergence from the challenger model.
(defaxiom government-scenario-alternative-process-approved
  (alternative-process-approvedp 'citizen-a 'registration-attempt-a))

;;; =========================================================================
;;; Intermediate lemmas — factored proof chain
;;; =========================================================================

;; Step 1: Government defense is established (6-factor test satisfied)
(defthm government-lemma-defense-established
  (government-defense-establishedp 'federal-save-act))

;; Step 2: Regulation is valid (via bridge rule)
(defthm government-lemma-regulation-valid
  (valid-regulationp 'federal-save-act x))

;;; =========================================================================
;;; PROOF OBLIGATION 1: General theorem
;;;
;;; Under the government's interpretive model, NO constitutional
;;; conflict exists for ANY person, because the SAVE Act is a valid
;;; regulation. The (not (valid-regulationp ...)) conjunct in
;;; constitutional-conflict-conditionp is false.
;;; =========================================================================

(defthm government-no-conflict-general
  (implies
   (and (important-government-interestp law)
        (election-integrity-interestp law)
        (reasonable-registration-requirementp law)
        (registration-procedure-evenhandedp law)
        (documentary-proof-requirement-rationally-connectedp law)
        (adequate-alternative-processp law))
   (not (constitutional-conflict-conditionp
         law constitution-section p x)))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp
                               qualified-federal-voterp
                               registration-transactionp)))
  :rule-classes nil)

;;; =========================================================================
;;; PROOF OBLIGATION 2: Concrete citizen-a corollary
;;;
;;; The government defeats the conflict through TWO independent paths:
;;; 1. The regulation is valid (valid-regulationp is true)
;;; 2. Registration is not denied (alternative process approved)
;;; =========================================================================

(defthm government-model-no-conflict
  (not
   (constitutional-conflict-conditionp
    'federal-save-act
    'amend-v-equal-protection
    'citizen-a
    'registration-attempt-a))
  :rule-classes nil)
