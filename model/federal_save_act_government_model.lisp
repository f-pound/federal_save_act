(in-package "ACL2")

(include-book "federal_save_act_scenario")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_government_model.lisp  —  v6.0 (hybrid architecture)
;; Interpretive model favoring government defense of the SAVE Act.
;;
;; v3 architecture (retained in v5.2):
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

;;
;; v6.1: narrowed to voter registration APPLICATIONS.  The six-factor
;; defense is about the documentary-proof requirement at registration; the
;; § 8(k) removal rule needs its own defense (below).
(defaxiom government-bridge-defense-validates
  (implies
   (and (government-defense-establishedp law)
        (voter-registration-applicationp x))
   (valid-regulationp law x)))

;;; =========================================================================
;;; Government interpretive axioms — each defense factor
;;;
;;; These constrain existing defstubs from core.lisp, so they use
;;; defaxiom. Each is a simple ground fact about 'federal-save-act.
;;; =========================================================================

;; DOCTRINAL_RULE: Election integrity interest
;; Source: Crawford, 553 U.S. at 194-196 ("there is no question about
;; the legitimacy or importance of the State's interest in counting
;; only the votes of eligible voters")
(defaxiom government-election-integrity-interest
  (election-integrity-interestp 'federal-save-act))

;; DOCTRINAL_RULE: The interest is important
;; Source: Crawford, 553 U.S. at 194-196
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

;; EMPIRICAL_ASSUMPTION: Burden is not severe
;; Source: Crawford, 553 U.S. at 198 ("the inconvenience... does not
;; qualify as a substantial burden on the right to vote")
(defaxiom government-burden-not-severe
  (burden-not-severep 'federal-save-act p))

;;; =========================================================================
;;; Scenario — the six conceded ground facts about citizen-a and
;;; registration-attempt-a live in federal_save_act_scenario.lisp (v6.0).
;;; The government concedes the factual scenario but reaches a different
;;; conclusion because the regulation is valid.  Only government-specific
;;; stipulations remain here.

;; INTERPRETATION_GOVERNMENT: Concede arguendo that citizen-a has a
;; protected right to vote. This strengthens the proof — no-conflict
;; results from valid-regulationp, not from failure to establish the right.
(defaxiom government-assume-right-to-vote-arguendo
  (protected-right-to-votep 'amend-v-equal-protection 'citizen-a))

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

;; Step 2: Regulation is valid for every registration application
(defthm government-lemma-regulation-valid
  (implies (voter-registration-applicationp x)
           (valid-regulationp 'federal-save-act x)))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; v6.1 — REMOVAL BRANCH (§ 8(k), citizen-b)
;;;
;;; Theory of the case: removal upon "documentation or verified
;;; information" of noncitizenship is a reasonable, evenhanded list-
;;; maintenance rule serving the State's interest in registering only
;;; eligible voters; the verification requirement itself is the process
;;; that is due, and provisional-ballot and re-registration avenues remain.
;;;
;;; Doctrinal basis: Husted v. A. Philip Randolph Institute, 584 U.S. 756
;;; (2018) (NVRA list-maintenance procedures upheld); Crawford (interest in
;;; counting only eligible votes).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(encapsulate
  ((government-removal-defense-establishedp (law p) t))

  (local (defun government-removal-defense-establishedp (law p)
    (declare (ignore law p)) t))

  ;; INTERPRETATION_GOVERNMENT: verified information + important interest +
  ;; evenhanded procedure establish the removal defense, regardless of
  ;; pre-removal notice.
  (defthm government-removal-defense-rule
    (implies
     (and (verified-noncitizen-informationp p)
          (important-government-interestp law)
          (removal-procedure-evenhandedp law))
     (government-removal-defense-establishedp law p))))

;; BRIDGE_RULE: the removal defense validates the rule as applied to p.
(defaxiom government-bridge-removal-validates
  (implies
   (government-removal-defense-establishedp law p)
   (valid-regulationp law p)))

;; INTERPRETATION_GOVERNMENT: the removal procedure is evenhanded
(defaxiom government-removal-procedure-evenhanded
  (removal-procedure-evenhandedp 'federal-save-act))

;; PROOF OBLIGATION 3: no removal conflict for anyone the State holds
;; verified information about — notice or no notice.
(defthm government-no-removal-conflict-general
  (implies
   (and (verified-noncitizen-informationp p)
        (important-government-interestp law)
        (removal-procedure-evenhandedp law))
   (not (constitutional-removal-conflict-conditionp law cs p)))
  :hints (("Goal" :in-theory (enable constitutional-removal-conflict-conditionp)))
  :rule-classes nil)

;; PROOF OBLIGATION 4: concrete citizen-b corollary
(defthm government-model-no-removal-conflict
  (not (constitutional-removal-conflict-conditionp
        'federal-save-act 'amend-v-equal-protection 'citizen-b))
  :rule-classes nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; v6.5 — VOTING BRANCH (SAVE America Act § 3 / HAVA § 303A, citizen-c)
;;;
;;; Theory of the case: Crawford upheld a photo-ID-to-vote requirement as a
;;; reasonable, evenhanded regulation justified by the State's interest in
;;; election integrity, where free ID and a provisional-ballot cure exist.
;;; § 303A is that law at the federal level.
;;;
;;; Doctrinal basis: Crawford, 553 U.S. at 189-204 (plurality and Scalia
;;; concurrence); Burdick.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(encapsulate
  ((government-voting-defense-establishedp (law) t))

  (local (defun government-voting-defense-establishedp (law)
    (declare (ignore law)) t))

  ;; INTERPRETATION_GOVERNMENT: important interest + evenhanded photo-ID
  ;; requirement + adequate provisional cure establish the defense.
  (defthm government-voting-defense-rule
    (implies
     (and (important-government-interestp law)
          (photo-id-requirement-evenhandedp law)
          (provisional-cure-adequatep law))
     (government-voting-defense-establishedp law))))

;; BRIDGE_RULE: the defense validates the rule for every ballot.
(defaxiom government-bridge-voting-validates
  (implies
   (and (government-voting-defense-establishedp law)
        (ballotp b))
   (valid-regulationp law b)))

;; INTERPRETATION_GOVERNMENT: the photo-ID requirement is evenhanded
(defaxiom government-photo-id-evenhanded
  (photo-id-requirement-evenhandedp 'federal-save-act))

;; INTERPRETATION_GOVERNMENT: the 3-day provisional cure is adequate
(defaxiom government-provisional-cure-adequate
  (provisional-cure-adequatep 'federal-save-act))

;; PROOF OBLIGATION 5: no voting conflict for any ballot
(defthm government-no-voting-conflict-general
  (implies
   (and (important-government-interestp law)
        (photo-id-requirement-evenhandedp law)
        (provisional-cure-adequatep law)
        (ballotp b))
   (not (constitutional-voting-conflict-conditionp law cs p b)))
  :hints (("Goal" :in-theory (enable constitutional-voting-conflict-conditionp)))
  :rule-classes nil)

;; PROOF OBLIGATION 6: concrete citizen-c corollary
(defthm government-model-no-voting-conflict
  (not (constitutional-voting-conflict-conditionp
        'federal-save-act 'amend-v-equal-protection 'citizen-c 'ballot-c))
  :rule-classes nil)

;;; v7.3 — POLL-TAX RESPONSE
;; INTERPRETATION_GOVERNMENT (Crawford): free identification is available, so
;; no fee is an electoral standard.  (Crawford: "the State offers free photo
;; identification to qualified voters able to establish their residence and
;; identity.")  Whether the SAVE Act's documents are free is contested; this
;; is the government's premise.
(defaxiom government-fee-waiver-available
  (fee-waiver-availablep 'federal-save-act))

;; With a waiver available, the challenger's poll-tax rule cannot fire; the
;; government's validity follows from the six-factor defense as before.
(defthm government-no-poll-tax-route
  (implies (fee-waiver-availablep 'federal-save-act)
           (not (and (document-acquisition-costp p)
                     (not (fee-waiver-availablep 'federal-save-act)))))
  :rule-classes nil)
