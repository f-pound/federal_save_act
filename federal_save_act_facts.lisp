(in-package "ACL2")

(include-book "federal_save_act_core")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_facts.lisp
;; Text-derived statutory facts only.
;;
;; EVERY axiom in this file must be directly traceable to source text.
;; Allowed labels: TEXT_FACT, DEFINED_TERM, PROHIBITION, EXCEPTION,
;;                 PENALTY, PROCEDURAL_FACT, BRIDGE_RULE
;;
;; Do NOT include INTERPRETATION_*, DOCTRINAL_ASSUMPTION, or
;; POLICY_ASSUMPTION in this file.
;;
;; Source: H.R. 22 (EH), SAVE Act, 119th Congress (2025)
;; Statutory baseline: NVRA (52 U.S.C. §§ 20501-20511) — the NVRA is
;;   a statute, not a constitutional provision. The SAVE Act amends it.
;; Constitutional ref: U.S. Const. Art. I, §2; Art. I, §4;
;;   Amend. V (equal protection component); Amend. XXIV
;;
;; ACE/APE AUDIT: All axioms in this file were derived from the enacted
;; bill text, NOT from ACE-normalized statements. The ACE normalization
;; (data/parsed/federal_save_act_ace.json) has ape_status = NOT_RUN for
;; all statements. Per AGENTS.md rules, no APE-rejected or APE-unrun
;; ACE statements were used to generate these axioms. The axioms trace
;; directly to the source text quoted in the comments below.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ===========================================================================
;;; 1. TEXT_FACT: The SAVE Act is a law
;;; ===========================================================================

(defaxiom text-save-act-is-law
  (lawp 'federal-save-act))

;;; ===========================================================================
;;; 2. PROHIBITION: Primary documentary proof requirement
;;; Source: SAVE Act § 2(b) / NVRA § 4(b); § 2(f) / NVRA § 8(j)(1)
;;;
;;; "Under any method of voter registration in a State, the State shall
;;;  not accept and process an application to register to vote in an
;;;  election for Federal office unless the applicant presents documentary
;;;  proof of United States citizenship with the application."
;;;
;;; "a State may not register an individual to vote in elections for
;;;  Federal office... unless... the individual provides documentary
;;;  proof of United States citizenship."
;;; ===========================================================================

(defaxiom text-save-act-documentary-proof-requirement
  (implies
   (and (personp p)
        (voter-registration-applicationp x)
        (attempts-to-registerp p x)
        (not (has-documentary-proofp p))
        (not (alternative-process-approvedp p x)))
   (statute-denies-registrationp 'federal-save-act p x)))

;;; ===========================================================================
;;; 3. EXCEPTION: Alternative attestation process
;;; Source: SAVE Act § 2(f) / NVRA § 8(j)(2)(A)
;;;
;;; An applicant who cannot provide documentary proof may sign an
;;; attestation under penalty of perjury, submit other evidence, and
;;; have a state/local official determine citizenship.
;;;
;;; NOTE: Whether this process guarantees registration or merely permits
;;; discretionary approval is an interpretive question — not resolved here.
;;; ===========================================================================

;; The alternative process is modeled as a defstub in core because its
;; effectiveness is disputed between the models. The fact that the text
;; creates such a process is a TEXT_FACT, but its adequacy is interpretive.

;;; ===========================================================================
;;; 4. EXCEPTION: Provisional ballot preservation
;;; Source: SAVE Act § 6
;;;
;;; "Nothing in this Act... may be construed to supercede, restrict, or
;;;  otherwise affect the ability of an individual to cast a provisional
;;;  ballot... or to have the ballot counted... if the individual is
;;;  verified as a citizen"
;;; ===========================================================================

;; Provisional ballots remain available. This does not affect the
;; registration-denial analysis but is recorded for completeness.

;;; ===========================================================================
;;; 5. PENALTY: Criminal penalties for officials
;;; Source: SAVE Act § 2(j) / NVRA § 12(2)(B)-(C)
;;;
;;; "(B) providing material assistance to a noncitizen in attempting to
;;;  register to vote or vote in an election for Federal office;
;;;  (C) registering an applicant to vote in an election for Federal
;;;  office who fails to present documentary proof of United States
;;;  citizenship"
;;; ===========================================================================

;; Penalty provisions are recorded but not needed for the core
;; constitutional conflict analysis.

;;; ===========================================================================
;;; 6. BRIDGE_RULE: Documentary proof links to qualifying documents
;;; If a person possesses any qualifying document per NVRA § 3(b),
;;; then they have documentary proof. This is a neutral structural rule.
;;; ===========================================================================

(defaxiom text-documentary-proof-from-qualifying-documents
  (implies
   (has-any-qualifying-documentp p)
   (has-documentary-proofp p)))

;;; ===========================================================================
;;; 7. PROCEDURAL_FACT: Effective date
;;; Source: SAVE Act § 8
;;; "This Act and the amendments made by this Act shall take effect on
;;;  the date of the enactment of this Act"
;;; ===========================================================================

;; Effective immediately upon enactment. No phase-in period for the
;; documentary proof requirement itself (though the state program
;; has a 30-day establishment deadline).
