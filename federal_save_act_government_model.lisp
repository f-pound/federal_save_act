(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_government_model.lisp
;; Interpretive model favoring government defense of the SAVE Act.
;;
;; THESE ARE NOT TEXT-DERIVED FACTS. Every axiom here is labeled as
;; INTERPRETATION_GOVERNMENT, DOCTRINAL_ASSUMPTION, POLICY_ASSUMPTION,
;; SCENARIO_FACT, or APPLICATION_OF_DEFINED_TERM.
;;
;; Theory of the case: The government argues that the SAVE Act is a
;; valid exercise of Congress's power under the Elections Clause to
;; protect federal election integrity. The government's position:
;;
;;   (a) Congress has broad authority under the Elections Clause
;;       (Art. I, § 4) to regulate the manner of federal elections,
;;       including voter registration procedures.
;;   (b) The documentary proof requirement serves a compelling
;;       governmental interest in preventing noncitizen voting.
;;   (c) The requirement is not unduly burdensome because qualifying
;;       documents are widely available and the statute provides an
;;       alternative attestation process (§ 8(j)(2)(A)).
;;   (d) The alternative process provides a constitutionally adequate
;;       safety valve for citizens who lack standard documents.
;;   (e) The SAVE Act is therefore a valid regulation of voter
;;       registration.
;;
;; Under these assumptions, constitutional-conflict-conditionp should
;; NOT be satisfiable (because valid-regulationp defeats the conflict).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ---- Additional interpretive predicates ----

(defstub compelling-government-interestp (law) t)
(defstub election-integrity-interestp (law) t)
(defstub reasonable-registration-requirementp (law) t)
(defstub adequate-alternative-processp (law) t)

;;; ===========================================================================
;;; INTERPRETATION_GOVERNMENT: Valid regulation rule
;;; If the SAVE Act serves a compelling government interest in election
;;; integrity, imposes a reasonable registration requirement, and provides
;;; an adequate alternative process, then it is a valid regulation.
;;;
;;; Doctrinal basis: Crawford v. Marion County Election Bd., 553 U.S. 181
;;; (2008) — states (and by extension Congress) have a legitimate and
;;; important interest in preventing voter fraud and ensuring election
;;; integrity; Purcell v. Gonzalez, 549 U.S. 1 (2006) — voter confidence.
;;; ===========================================================================

(defaxiom government-valid-regulation-rule
  (implies
   (and (election-integrity-interestp law)
        (reasonable-registration-requirementp law)
        (adequate-alternative-processp law))
   (valid-regulationp law x)))

;;; ===========================================================================
;;; INTERPRETATION_GOVERNMENT: The SAVE Act serves election integrity
;;; The documentary proof requirement directly serves the government's
;;; interest in ensuring only eligible citizens participate in federal
;;; elections.
;;;
;;; Policy basis: Constitutional text limits franchise to citizens;
;;; documentary verification is the most reliable method; self-attestation
;;; alone is insufficient to detect ineligible registrants.
;;; ===========================================================================

(defaxiom government-election-integrity-interest
  (election-integrity-interestp 'federal-save-act))

;;; ===========================================================================
;;; INTERPRETATION_GOVERNMENT: The requirement is reasonable
;;; The documentary proof requirement is reasonable because:
;;;   - It accepts a wide range of qualifying documents (6 categories)
;;;   - REAL ID-compliant licenses are increasingly universal
;;;   - Passports are available to all citizens
;;;   - The alternative attestation process covers edge cases
;;;   - The requirement applies equally to all applicants
;;;
;;; Doctrinal basis: Crawford — Indiana's photo ID requirement was
;;; upheld as reasonable despite some burden on voters who lack ID.
;;; ===========================================================================

(defaxiom government-reasonable-requirement
  (reasonable-registration-requirementp 'federal-save-act))

;;; ===========================================================================
;;; INTERPRETATION_GOVERNMENT: The alternative process is adequate
;;; The attestation process under § 8(j)(2)(A) provides a
;;; constitutionally adequate safety valve:
;;;   - Available to anyone who cannot provide standard documentary proof
;;;   - Attestation under penalty of perjury establishes good faith
;;;   - Submission of other evidence allows flexible proof
;;;   - Official determination provides a path to registration
;;;   - EAC develops uniform standards and affidavit
;;;
;;; Doctrinal basis: Crawford — the availability of provisional ballots
;;; and free ID cards was relevant to upholding Indiana's voter ID law.
;;; ===========================================================================

(defaxiom government-adequate-alternative
  (adequate-alternative-processp 'federal-save-act))

;;; ===========================================================================
;;; Scenario constants — same scenario as challenger model
;;;
;;; citizen-a: Same person — an elderly U.S. citizen born at home.
;;; registration-attempt-a: Same mail voter registration application.
;;;
;;; The government concedes the factual scenario but reaches a different
;;; conclusion because the regulation is valid.
;;; ===========================================================================

;; SCENARIO_FACT: citizen-a is a person (same as challenger)
(defaxiom scenario-person
  (personp 'citizen-a))

;; SCENARIO_FACT: citizen-a is a U.S. citizen (same as challenger)
(defaxiom scenario-citizen
  (citizen-of-usp 'citizen-a))

;; SCENARIO_FACT: citizen-a is otherwise eligible to vote (same)
(defaxiom scenario-eligible
  (eligible-voterp 'citizen-a))

;; SCENARIO_FACT: registration-attempt-a is an application (same)
(defaxiom scenario-application
  (voter-registration-applicationp 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a attempts to register (same)
(defaxiom scenario-attempts-to-register
  (attempts-to-registerp 'citizen-a 'registration-attempt-a))

;; INTERPRETATION_GOVERNMENT: Concede arguendo that citizen-a has a
;; protected right to vote. This strengthens the proof — no-conflict
;; results from valid-regulationp, not from failure to establish the
;; right to vote.
(defaxiom government-assume-right-to-vote-arguendo
  (protected-right-to-votep 'amend-v-equal-protection 'citizen-a))

;; SCENARIO_FACT: citizen-a lacks documentary proof (same as challenger)
;; The government does not dispute this factual stipulation.
(defaxiom scenario-no-documentary-proof
  (not (has-documentary-proofp 'citizen-a)))

;; INTERPRETATION_GOVERNMENT: the alternative process IS available and
;; adequate for citizen-a. Under the government's theory, citizen-a
;; CAN be registered through the alternative attestation process,
;; defeating the denial of registration.
;;
;; Note: This is the KEY divergence from the challenger model.
;; The challenger says the alternative process is discretionary and
;; unreliable. The government says it provides a guaranteed path.
(defaxiom scenario-alternative-process-approved
  (alternative-process-approvedp 'citizen-a 'registration-attempt-a))

;;; ===========================================================================
;;; PROOF OBLIGATION: Under the government's interpretive model,
;;; NO constitutional conflict exists.
;;;
;;; The proof chain:
;;; 1. government-valid-regulation-rule establishes
;;;    (valid-regulationp 'federal-save-act 'registration-attempt-a)
;;;    from the three government interpretive axioms.
;;; 2. This negates the last conjunct of
;;;    constitutional-conflict-conditionp: (not (valid-regulationp ...))
;;;    becomes NIL.
;;; 3. Additionally, alternative-process-approvedp defeats the
;;;    statute-denies-registrationp antecedent in the facts.
;;; 4. Either path — valid regulation OR no denial — defeats the
;;;    conflict condition.
;;; ===========================================================================

(defthm government-model-no-conflict
  (not
   (constitutional-conflict-conditionp
    'federal-save-act
    'amend-v-equal-protection
    'citizen-a
    'registration-attempt-a))
  :rule-classes nil)
