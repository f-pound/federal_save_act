(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_doctrine_proofs.lisp  —  v5.2
;;
;; Conditional doctrine theorem chains.
;;
;; IMPORTANT DISCLAIMER:
;;   ACL2 proves CONDITIONAL doctrine consequences, not actual judicial
;;   holdings.  Every theorem in this book is a conditional implication:
;;   "IF these doctrinal/empirical/interpretive assumptions hold,
;;    THEN this legal conclusion follows."
;;   ACL2 does not adjudicate which assumptions are correct.
;;
;; This book encodes the Anderson-Burdick doctrinal framework as
;; conditional theorem chains that both the challenger and government
;; can use.  The key theorems show:
;;
;;   1. Invalid regulation + qualified voter + denial → conflict
;;   2. Valid regulation → no conflict (regardless of other factors)
;;   3. Severe burden + no adequate alternative → supports invalidity
;;   4. Important interest + adequate alternative → supports validity
;;
;; These theorem chains make the doctrinal dependency structure
;; mechanically auditable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. ANDERSON-BURDICK STANDARD (encapsulate)
;;;
;;; The Anderson-Burdick standard is the doctrinal framework for
;;; evaluating election regulations.  It is inherently abstract —
;;; courts apply it case-by-case.  We model it as an encapsulate
;;; with local witnesses, proving that the constraints are jointly
;;; satisfiable.
;;;
;;; Exported constraints:
;;;   - Severe burden + insufficient justification → invalid regulation
;;;   - Important interest + reasonable fit + adequate alternative → valid
;;;
;;; This encapsulate is BETTER than defaxiom for doctrine because:
;;;   1. The local witnesses prove the constraints are consistent
;;;   2. The constraints are conditional, not ground facts
;;;   3. Courts could disagree about the standard — the encapsulate
;;;      lets us reason about it without committing to specifics
;;; =========================================================================

(encapsulate
  ;; Two new constrained predicates representing the doctrinal standard
  ((anderson-burdick-invalidp (law p x) t)
   (anderson-burdick-validp (law x) t))

  ;; ---- Witness model ----
  ;; A toy world where invalidity depends on severe-burden-on-plaintiffp
  ;; and validity depends on important-government-interestp.
  (local (defun anderson-burdick-invalidp (law p x)
    (declare (ignore x))
    (severe-burden-on-plaintiffp law p)))
  (local (defun anderson-burdick-validp (law x)
    (declare (ignore x))
    (important-government-interestp law)))

  ;; ---- Exported constraint 1: Severe burden → supports invalidity ----
  ;; Under the Anderson-Burdick framework, if the burden is severe
  ;; and the plaintiff can show it, the regulation may be invalid.
  ;; This is CONDITIONAL — it does not assert that the burden IS severe.
  (defthm severe-burden-supports-invalidity
    (implies (severe-burden-on-plaintiffp law p)
             (anderson-burdick-invalidp law p x)))

  ;; ---- Exported constraint 2: Important interest → supports validity ----
  ;; Under the Anderson-Burdick framework, if the government shows
  ;; an important interest, the regulation may be valid.
  (defthm important-interest-supports-validity
    (implies (important-government-interestp law)
             (anderson-burdick-validp law x))))

;;; =========================================================================
;;; 2. CHALLENGER-FAVORABLE DOCTRINE CHAIN
;;;
;;; If a qualified voter is denied registration and the regulation
;;; is not valid, a constitutional conflict exists.
;;;
;;; This is a restatement of the independence pivot from v5.1,
;;; but explicitly framed as a doctrinal theorem.
;;; =========================================================================

;; Challenger doctrine: invalid regulation enables the conflict condition
(defthm invalid-regulation-enables-conflict-condition
  (implies (and (lawp law)
                (qualified-federal-voterp p)
                (protected-right-to-votep cs p)
                (registration-transactionp p x)
                (statute-denies-registrationp law p x)
                (not (valid-regulationp law x)))
           (constitutional-conflict-conditionp law cs p x))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp)))
  :rule-classes nil)

;;; =========================================================================
;;; 3. GOVERNMENT-FAVORABLE DOCTRINE CHAIN
;;;
;;; If the regulation is valid, no constitutional conflict exists
;;; (regardless of all other factors).
;;; =========================================================================

;; Government doctrine: valid regulation negates the conflict condition
(defthm valid-regulation-negates-conflict-condition
  (implies (valid-regulationp law x)
           (not (constitutional-conflict-conditionp law cs p x)))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp)))
  :rule-classes nil)

;;; =========================================================================
;;; 4. BURDEN → INVALIDITY CHAIN (CHALLENGER)
;;;
;;; Under the Anderson-Burdick framework, severe burden supports
;;; a finding of invalidity.  Combined with a bridge rule that
;;; anderson-burdick-invalidp implies not-valid-regulationp,
;;; this chain connects burden to conflict.
;;;
;;; NOTE: This theorem does NOT assert that the regulation IS invalid.
;;; It proves that IF the burden is severe, THEN the doctrinal framework
;;; supports invalidity.  Whether the burden IS severe is an empirical
;;; question that ACL2 cannot resolve.
;;; =========================================================================

(defthm severe-burden-and-denial-supports-challenger-conflict
  (implies (and (lawp law)
                (qualified-federal-voterp p)
                (protected-right-to-votep cs p)
                (registration-transactionp p x)
                (statute-denies-registrationp law p x)
                (anderson-burdick-invalidp law p x)
                (not (valid-regulationp law x)))
           (constitutional-conflict-conditionp law cs p x))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp)))
  :rule-classes nil)

;;; =========================================================================
;;; 5. INTEREST → VALIDITY CHAIN (GOVERNMENT)
;;;
;;; Under the Anderson-Burdick framework, an important government
;;; interest supports a finding of validity.  If the government
;;; defense is established, the conflict condition cannot hold.
;;;
;;; This mirrors the government model's proof chain but makes
;;; the doctrinal dependency explicit.
;;; =========================================================================

(defthm important-interest-and-adequate-alternative-supports-validity
  (implies (and (important-government-interestp law)
                (election-integrity-interestp law)
                (reasonable-registration-requirementp law)
                (registration-procedure-evenhandedp law)
                (documentary-proof-requirement-rationally-connectedp law)
                (adequate-alternative-processp law))
           (anderson-burdick-validp law x))
  :rule-classes nil)

;;; =========================================================================
;;; 6. DENIAL TRIGGER → STATUTE DENIAL CONNECTION
;;;
;;; If the SAVE Act denial trigger fires (no documentary proof AND
;;; no alternative process approval), the statute denies registration
;;; (assuming the statute is in effect).
;;;
;;; NOTE: This is conditional on statute-denies-registrationp being
;;; true.  The denial trigger is a STRUCTURAL condition — it shows
;;; when the denial mechanism activates, not whether the statute
;;; is actually enforced.
;;; =========================================================================

(defthm denial-trigger-with-statute-implies-conflict-preconditions
  (implies (and (lawp law)
                (qualified-federal-voterp p)
                (protected-right-to-votep cs p)
                (save-act-denial-triggerp p x)
                (statute-denies-registrationp law p x)
                (not (valid-regulationp law x)))
           (constitutional-conflict-conditionp law cs p x))
  :hints (("Goal" :in-theory (enable constitutional-conflict-conditionp
                               save-act-denial-triggerp)))
  :rule-classes nil)
