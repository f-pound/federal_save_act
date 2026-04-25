(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_challenger_model.lisp
;; Interpretive model favoring constitutional challenge.
;;
;; THESE ARE NOT TEXT-DERIVED FACTS. Every axiom here is labeled as
;; INTERPRETATION_CHALLENGER, DOCTRINAL_ASSUMPTION, POLICY_ASSUMPTION,
;; SCENARIO_FACT, or APPLICATION_OF_DEFINED_TERM.
;;
;; Theory of the case: A U.S. citizen born at home in a rural area
;; attempts to register to vote by mail for a federal election. The
;; citizen lacks a REAL ID, passport, birth certificate, and any other
;; qualifying document under NVRA § 3(b). The challenger argues:
;;
;;   (a) The right to vote is fundamental under the Fifth Amendment's
;;       equal protection component (reverse-incorporated from the
;;   (b) The documentary proof requirement imposes an undue burden on
;;       eligible citizens who lack qualifying documents through no
;;       fault of their own.
;;   (c) The alternative attestation process (§ 8(j)(2)(A)) is
;;       inadequate because it depends on discretionary official
;;       judgment and provides no guaranteed right to register.
;;   (d) The cost of obtaining qualifying documents (birth certificate,
;;       passport) functions as a de facto poll tax prohibited by the
;;       Twenty-Fourth Amendment.
;;   (e) The SAVE Act is therefore not a valid regulation of voter
;;       registration.
;;
;; Under these assumptions, constitutional-conflict-conditionp should
;; be provable for the scenario constants.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ---- Additional interpretive predicates ----

(defstub fundamental-right-to-votep (p) t)
(defstub lacks-qualifying-documents-through-no-faultp (p) t)
(defstub discretionary-official-determinationp (p x) t)

;;; ===========================================================================
;;; DOCTRINAL_ASSUMPTION: The right to vote is fundamental
;;; If a person is a U.S. citizen and is otherwise eligible to vote,
;;; then that person has a constitutionally protected right to vote
;;; under the equal protection component of the Fifth Amendment's Due
;;; Process Clause (reverse incorporation from the Fourteenth Amendment
;;; per Bolling v. Sharpe, 347 U.S. 497 (1954)).
;;;
;;; Doctrinal basis: Harper v. Virginia Board of Elections, 383 U.S. 663
;;; (1966) — "the right to vote is too precious, too fundamental to be so
;;; burdened"; Reynolds v. Sims, 377 U.S. 533 (1964) — right to vote is
;;; "the essence of a democratic society."
;;; ===========================================================================

(defaxiom challenger-fundamental-right-rule
  (implies
   (and (personp p)
        (citizen-of-usp p)
        (eligible-voterp p))
   (protected-right-to-votep 'amend-v-equal-protection p)))

;;; ===========================================================================
;;; INTERPRETATION_CHALLENGER: Undue burden defeats valid regulation
;;; If a law imposes an undue burden on the fundamental right to vote
;;; of an eligible citizen who lacks qualifying documents through no
;;; fault of their own, then the law is not a valid regulation.
;;;
;;; Doctrinal basis: Crawford v. Marion County Election Bd., 553 U.S. 181
;;; (2008) — even where a state has a valid interest, the regulation must
;;; not impose a severe burden on a substantial number of voters;
;;; Anderson v. Celebrezze, 460 U.S. 780 (1983) — balancing test.
;;; ===========================================================================

(defaxiom challenger-undue-burden-defeats-regulation
  (implies
   (and (personp p)
        (citizen-of-usp p)
        (eligible-voterp p)
        (lacks-qualifying-documents-through-no-faultp p)
        (undue-burden-on-right-to-votep 'federal-save-act p))
   (not (valid-regulationp 'federal-save-act 'registration-attempt-a))))

;;; ===========================================================================
;;; INTERPRETATION_CHALLENGER: Documentary proof requirement IS an undue burden
;;; The requirement to produce documentary proof of citizenship imposes
;;; an undue burden on eligible citizens who lack qualifying documents,
;;; because:
;;;   - Millions of citizens were born without hospital birth records
;;;   - Birth certificates cost money and require travel to obtain
;;;   - Passports cost $130+ and require existing documentation
;;;   - REAL ID-compliant licenses are not universally available
;;;   - The burden falls disproportionately on elderly, low-income,
;;;     minority, rural, and Native American citizens
;;;
;;; Doctrinal basis: Crawford (Stevens plurality) — burden analysis must
;;; account for voters who face the greatest obstacles.
;;; ===========================================================================

(defaxiom challenger-documentary-proof-is-undue-burden
  (implies
   (and (personp p)
        (citizen-of-usp p)
        (eligible-voterp p)
        (not (has-documentary-proofp p))
        (lacks-qualifying-documents-through-no-faultp p))
   (undue-burden-on-right-to-votep 'federal-save-act p)))

;;; ===========================================================================
;;; INTERPRETATION_CHALLENGER: Alternative process is inadequate
;;; The alternative attestation process (§ 8(j)(2)(A)) does not cure
;;; the constitutional defect because it depends on the discretionary
;;; judgment of a state or local official — there is no guaranteed
;;; right to be registered even after attestation.
;;;
;;; This means alternative-process-approvedp does NOT hold for
;;; citizen-a because the process is unreliable.
;;; ===========================================================================

;; Modeled by denying alternative-process-approvedp in the scenario
;; axioms below — the challenger's position is that the process is
;; not a reliable path to registration.

;;; ===========================================================================
;;; Scenario constants — small stress-test scenario
;;;
;;; citizen-a: An elderly U.S. citizen born at home in a rural area.
;;;   - Born in the U.S. (citizen by birth under Fourteenth Amendment)
;;;   - Never obtained a passport
;;;   - Born before universal hospital birth registration
;;;   - Does not have a REAL ID-compliant driver's license
;;;   - Cannot easily obtain a certified birth certificate
;;;   - Age 18+, not a felon, meets all other voter qualifications
;;;
;;; registration-attempt-a: A mail voter registration application
;;;   for a federal election, submitted using the national form.
;;; ===========================================================================

;; SCENARIO_FACT: citizen-a is a person
(defaxiom scenario-person
  (personp 'citizen-a))

;; SCENARIO_FACT: citizen-a is a U.S. citizen (born in the United States)
(defaxiom scenario-citizen
  (citizen-of-usp 'citizen-a))

;; SCENARIO_FACT: citizen-a is otherwise eligible to vote
;; (18+, not convicted of disqualifying felony, meets residency requirements)
(defaxiom scenario-eligible
  (eligible-voterp 'citizen-a))

;; SCENARIO_FACT: registration-attempt-a is a voter registration application
(defaxiom scenario-application
  (voter-registration-applicationp 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a attempts to register via the application
(defaxiom scenario-attempts-to-register
  (attempts-to-registerp 'citizen-a 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a does NOT have documentary proof of citizenship
;; (no REAL ID, no passport, no birth certificate, no military ID)
(defaxiom scenario-no-documentary-proof
  (not (has-documentary-proofp 'citizen-a)))

;; INTERPRETATION_CHALLENGER: citizen-a lacks documents through no fault
;; (born at home, elderly, rural, never needed a passport)
(defaxiom scenario-no-fault
  (lacks-qualifying-documents-through-no-faultp 'citizen-a))

;; INTERPRETATION_CHALLENGER: the alternative process does NOT guarantee
;; registration for citizen-a (discretionary official judgment)
(defaxiom scenario-alternative-process-denied
  (not (alternative-process-approvedp 'citizen-a 'registration-attempt-a)))

;;; ===========================================================================
;;; PROOF OBLIGATION: Under the challenger's interpretive model,
;;; a constitutional conflict exists.
;;;
;;; The proof chain:
;;; 1. citizen-a is a person, citizen, eligible voter (scenario facts)
;;; 2. challenger-fundamental-right-rule establishes
;;;    (protected-right-to-votep 'amend-v-equal-protection 'citizen-a)
;;; 3. citizen-a attempts to register (scenario fact)
;;; 4. citizen-a lacks documentary proof and alternative process denied,
;;;    so text-save-act-documentary-proof-requirement establishes
;;;    (statute-denies-registrationp 'federal-save-act 'citizen-a
;;;     'registration-attempt-a)
;;; 5. challenger-documentary-proof-is-undue-burden establishes
;;;    (undue-burden-on-right-to-votep 'federal-save-act 'citizen-a)
;;; 6. challenger-undue-burden-defeats-regulation establishes
;;;    (not (valid-regulationp 'federal-save-act 'registration-attempt-a))
;;; 7. All conjuncts of constitutional-conflict-conditionp are satisfied.
;;; ===========================================================================

(defthm challenger-model-finds-conflict
  (constitutional-conflict-conditionp
   'federal-save-act
   'amend-v-equal-protection
   'citizen-a
   'registration-attempt-a)
  :rule-classes nil)
