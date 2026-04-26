(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_burden_proofs.lisp  —  v5.2
;;
;; Burden derivation chain: from lower-level predicates to burden conclusions.
;;
;; The v5.1 model relied on one-off burden assumptions (axiom statements
;; like "citizen-a faces material burden").  v5.2 introduces DERIVED burden
;; predicates as defun, so that burden conclusions are PROVED from lower-level
;; constituent facts, not assumed.
;;
;; The empirical inputs remain as source-traced assumptions:
;;   - cannot-obtain-qualifying-documents-without-material-burdenp  (defstub)
;;   - lacks-qualifying-documents-through-no-faultp                 (defstub)
;;
;; But the intermediate burden conclusions are now executable definitions:
;;   - lacks-all-qualifying-documentsp
;;   - material-burdenp
;;   - no-adequate-alternative-forp
;;   - denial-riskp
;;   - severe-burdenp-derived
;;
;; ACL2 proves the derivation chain, making the burden argument auditable.
;;
;; Legal relevance: Under Anderson-Burdick, burden severity determines the
;; standard of review.  This book makes the burden-severity derivation
;; mechanically checkable — a court or scholar can verify exactly which
;; empirical facts feed into the "severe burden" conclusion.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. DERIVED BURDEN PREDICATES
;;;
;;; These are executable definitions, not defstubs.  Their truth values
;;; are structurally determined by the lower-level predicates.
;;; =========================================================================

;; A person lacks all qualifying documents
;; Derived from: (not (has-any-qualifying-documentp p))
(defun lacks-all-qualifying-documentsp (p)
  (not (has-any-qualifying-documentp p)))

;; Material burden: person lacks all documents AND cannot obtain them
;; without material burden (empirical input).
;; This is the first derived step — it combines a structural fact
;; (document status) with an empirical assumption (obtainability).
(defun material-burdenp (p)
  (and (lacks-all-qualifying-documentsp p)
       (cannot-obtain-qualifying-documents-without-material-burdenp p)))

;; No adequate alternative: the alternative process is not approved
;; for this person's application.
(defun no-adequate-alternative-forp (p x)
  (not (alternative-process-approvedp p x)))

;; Denial risk: material burden AND no adequate alternative.
;; A citizen who faces material burden and lacks alternative process
;; approval faces a nontrivial risk of denial.
(defun denial-riskp (p x)
  (and (material-burdenp p)
       (no-adequate-alternative-forp p x)))

;; Severe burden (derived): the complete burden chain.
;; Under the challenger's theory, a citizen who:
;;   (a) lacks all qualifying documents,
;;   (b) cannot reasonably obtain them,
;;   (c) lacks an approved alternative process path
;; faces a severe burden on the right to vote.
;;
;; NOTE: This is called severe-burdenp-derived to distinguish it from
;; the existing defstub severe-burden-on-plaintiffp, which remains
;; available for the party models.
(defun severe-burdenp-derived (p x)
  (and (material-burdenp p)
       (denial-riskp p x)))

;;; =========================================================================
;;; 2. DERIVATION CHAIN THEOREMS
;;;
;;; These prove the burden derivation chain:
;;;   lacks documents + cannot obtain → material burden
;;;   material burden + no alternative → denial risk
;;;   material burden + denial risk → severe burden
;;;
;;; Each theorem is trivially derivable from the definitions, but making
;;; them explicit theorems serves the audit purpose: a legal reader can
;;; see exactly what ACL2 has verified at each step.
;;; =========================================================================

;; Step 1: The definitional derivation of material burden
(defthm lacks-documents-and-cannot-obtain-implies-material-burden
  (implies (and (lacks-all-qualifying-documentsp p)
                (cannot-obtain-qualifying-documents-without-material-burdenp p))
           (material-burdenp p))
  :hints (("Goal" :in-theory (enable material-burdenp))))

;; Step 2: Material burden + no alternative → denial risk
(defthm material-burden-plus-no-alternative-implies-denial-risk
  (implies (and (material-burdenp p)
                (no-adequate-alternative-forp p x))
           (denial-riskp p x))
  :hints (("Goal" :in-theory (enable denial-riskp))))

;; Step 3: Material burden + denial risk → severe burden
(defthm material-burden-plus-denial-risk-implies-severe-burden
  (implies (and (material-burdenp p)
                (denial-riskp p x))
           (severe-burdenp-derived p x))
  :hints (("Goal" :in-theory (enable severe-burdenp-derived))))

;; Corollary: The full one-step derivation
(defthm full-burden-chain
  (implies (and (lacks-all-qualifying-documentsp p)
                (cannot-obtain-qualifying-documents-without-material-burdenp p)
                (no-adequate-alternative-forp p x))
           (severe-burdenp-derived p x))
  :hints (("Goal" :in-theory (enable material-burdenp
                               denial-riskp
                               severe-burdenp-derived))))

;;; =========================================================================
;;; 3. STRUCTURAL BURDEN PROPERTIES
;;;
;;; Additional theorems showing structural relationships between
;;; burden predicates — these hold for ALL persons, not just citizen-a.
;;; =========================================================================

;; If someone faces severe burden, they also face material burden
(defthm severe-burden-implies-material-burden
  (implies (severe-burdenp-derived p x)
           (material-burdenp p))
  :hints (("Goal" :in-theory (enable severe-burdenp-derived))))

;; If someone faces severe burden, they face denial risk
(defthm severe-burden-implies-denial-risk
  (implies (severe-burdenp-derived p x)
           (denial-riskp p x))
  :hints (("Goal" :in-theory (enable severe-burdenp-derived))))

;; Contrapositive: if the alternative is adequate, no severe burden
;; (because denial risk requires no-adequate-alternative)
(defthm adequate-alternative-negates-severe-burden
  (implies (alternative-process-approvedp p x)
           (not (severe-burdenp-derived p x)))
  :hints (("Goal" :in-theory (enable severe-burdenp-derived
                               denial-riskp
                               no-adequate-alternative-forp))))

;; Contrapositive: if person has qualifying documents, no material burden
(defthm qualifying-documents-negate-material-burden
  (implies (has-any-qualifying-documentp p)
           (not (material-burdenp p)))
  :hints (("Goal" :in-theory (enable material-burdenp
                               lacks-all-qualifying-documentsp))))
