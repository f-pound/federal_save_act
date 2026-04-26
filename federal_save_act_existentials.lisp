(in-package "ACL2")

(include-book "federal_save_act_facts")

;;; =========================================================================
;; federal_save_act_existentials.lisp  —  v5.2
;; Existential burden modeling with defun-sk.
;;
;; Legal burden analysis depends on EXISTENCE claims:
;;   "There exists an eligible citizen who..."
;; not just named examples like 'citizen-a.
;;
;; This book uses defun-sk to introduce Skolemized existential
;; propositions and proves bridge theorems connecting the witnesses
;; to the challenger-side burden predicates.
;;
;; v5.2 additions:
;;   - exists-citizen-facing-discretionary-denialp
;;   - burden-class-nonempty bridge theorems
;;   - nontrivial burden derivation
;;
;; defun-sk with (exists p body):
;;   - defines (foo) = (let ((p (foo-witness))) body)
;;   - generates (defthm foo-suff (implies body (foo)))
;;   - the witness (foo-witness) satisfies body when (foo) is true
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. EXISTENTIAL PROPOSITIONS
;;; =========================================================================

;; There exists an eligible citizen who lacks qualifying documentary proof.
(defun-sk exists-citizen-lacking-proofp ()
  (exists p (and (personp p)
                 (citizen-of-usp p)
                 (eligible-voterp p)
                 (not (has-documentary-proofp p)))))

;; There exists an eligible citizen who cannot reasonably obtain
;; qualifying documents without material burden.
(defun-sk exists-citizen-with-unreasonable-burdenp ()
  (exists p (and (personp p)
                 (citizen-of-usp p)
                 (eligible-voterp p)
                 (not (has-documentary-proofp p))
                 (cannot-obtain-qualifying-documents-without-material-burdenp p))))

;; There exists an eligible citizen who lacks documents through no fault.
(defun-sk exists-citizen-lacking-docs-no-faultp ()
  (exists p (and (personp p)
                 (citizen-of-usp p)
                 (eligible-voterp p)
                 (not (has-documentary-proofp p))
                 (lacks-qualifying-documents-through-no-faultp p))))

;; v5.2: There exists an eligible citizen who faces a discretionary
;; alternative process (the official has discretion to deny).
(defun-sk exists-citizen-facing-discretionary-denialp ()
  (exists (p x) (and (personp p)
                      (citizen-of-usp p)
                      (eligible-voterp p)
                      (not (has-documentary-proofp p))
                      (voter-registration-applicationp x)
                      (attempts-to-registerp p x)
                      (alternative-process-discretionary-forp p x))))

;;; =========================================================================
;;; 2. BRIDGE THEOREMS
;;;
;;; These connect the existential witnesses to the structural burden
;;; predicates, showing that the existence of one burdened citizen
;;; implies the existence of the broader class.
;;;
;;; Strategy: Open the definition of the stronger existential to get
;;; the witness's properties, then use -suff for the weaker existential.
;;; =========================================================================

;; If a citizen with unreasonable burden exists, then a citizen lacking
;; proof also exists (the stronger condition implies the weaker one).
(defthm exists-burdened-citizen-implies-lacking-proof
  (implies (exists-citizen-with-unreasonable-burdenp)
           (exists-citizen-lacking-proofp))
  :hints (("Goal"
           :use ((:instance exists-citizen-lacking-proofp-suff
                            (p (exists-citizen-with-unreasonable-burdenp-witness))))
           :in-theory (enable exists-citizen-with-unreasonable-burdenp)))
  :rule-classes nil)

;; If a citizen lacking docs through no fault exists, then a citizen
;; lacking proof exists.
(defthm exists-no-fault-citizen-implies-lacking-proof
  (implies (exists-citizen-lacking-docs-no-faultp)
           (exists-citizen-lacking-proofp))
  :hints (("Goal"
           :use ((:instance exists-citizen-lacking-proofp-suff
                            (p (exists-citizen-lacking-docs-no-faultp-witness))))
           :in-theory (enable exists-citizen-lacking-docs-no-faultp)))
  :rule-classes nil)

;;; =========================================================================
;;; 3. WITNESS CONNECTION
;;;
;;; If the existential is satisfied, the Skolem witness has the
;;; properties needed for the challenger's scenario.
;;; =========================================================================

;; The witness from exists-citizen-with-unreasonable-burdenp is a
;; qualified federal voter.
(defthm unreasonable-burden-witness-is-qualified
  (implies (exists-citizen-with-unreasonable-burdenp)
           (qualified-federal-voterp
            (exists-citizen-with-unreasonable-burdenp-witness)))
  :hints (("Goal"
           :in-theory (enable exists-citizen-with-unreasonable-burdenp
                              qualified-federal-voterp)))
  :rule-classes nil)

;;; =========================================================================
;;; 4. v5.2 BURDEN-CLASS BRIDGE THEOREMS
;;;
;;; These theorems connect the existential witness to the broader
;;; legal claim that the burdened CLASS is nonempty.
;;; =========================================================================

;; If a documentless eligible voter exists, the burdened class is nonempty.
;; This is a bridge from the existential to the class-burden claim.
(defthm exists-documentless-eligible-voter-implies-burden-class-nonempty
  (implies (exists-citizen-lacking-proofp)
           (and (personp (exists-citizen-lacking-proofp-witness))
                (citizen-of-usp (exists-citizen-lacking-proofp-witness))
                (eligible-voterp (exists-citizen-lacking-proofp-witness))
                (not (has-documentary-proofp
                      (exists-citizen-lacking-proofp-witness)))))
  :hints (("Goal"
           :in-theory (enable exists-citizen-lacking-proofp)))
  :rule-classes nil)

;; If a burdened voter exists, the law imposes a nontrivial burden.
;; (The burden is nontrivial because at least one qualified citizen
;; cannot obtain documents without material burden.)
(defthm exists-burdened-voter-implies-law-has-nontrivial-burden
  (implies (exists-citizen-with-unreasonable-burdenp)
           (and (personp (exists-citizen-with-unreasonable-burdenp-witness))
                (eligible-voterp (exists-citizen-with-unreasonable-burdenp-witness))
                (cannot-obtain-qualifying-documents-without-material-burdenp
                 (exists-citizen-with-unreasonable-burdenp-witness))))
  :hints (("Goal"
           :in-theory (enable exists-citizen-with-unreasonable-burdenp)))
  :rule-classes nil)

;; v5.2: If a citizen facing discretionary denial exists, the risk of
;; erroneous denial is nontrivial (because the official has discretion).
(defthm discretionary-denial-witness-implies-erroneous-denial-risk
  (implies (exists-citizen-facing-discretionary-denialp)
           (and (personp (mv-nth 0 (exists-citizen-facing-discretionary-denialp-witness)))
                (eligible-voterp (mv-nth 0 (exists-citizen-facing-discretionary-denialp-witness)))
                (alternative-process-discretionary-forp
                 (mv-nth 0 (exists-citizen-facing-discretionary-denialp-witness))
                 (mv-nth 1 (exists-citizen-facing-discretionary-denialp-witness)))))
  :hints (("Goal"
           :in-theory (enable exists-citizen-facing-discretionary-denialp)))
  :rule-classes nil)

