(in-package "ACL2")

(include-book "federal_save_act_core")
(include-book "federal_save_act_document_rules")
(include-book "federal_save_act_process_table")
(include-book "lib/lsm")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_process.lisp  —  v6.0 (library-instantiated)
;; Registration state machine and document-bundle recognizers.
;;
;; v6.0 changes:
;;   • The state machine is a DATA TABLE (*reg-edges*, generated from the
;;     clause IR) interpreted by the generic lib/lsm book, not a 13-clause cond.  Every invariant in the
;;     invariant books is now an instance of a library theorem, discharged
;;     by evaluating the table.
;;   • Acceptance / denial / terminal state sets are COMPUTED from the
;;     table (lsm-sources-into, lsm-has-outgoing), not hand-listed.
;;   • Document recognition follows the statute's actual structure:
;;     § 3(b)(1)-(4) are standalone proof; § 3(b)(5)(A)-(F) count only when
;;     presented together with a government photo ID.  v5 wrongly treated a
;;     birth certificate or naturalization certificate alone as proof.
;;     The category tables and documentary-proof-bundlep are GENERATED from
;;     data/parsed/federal_save_act_document_rules.json by
;;     tools/clauses_to_acl2.py.
;;
;; This is a NEUTRAL book — no interpretive assumptions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. DOCUMENT TYPE CONSTANTS  (symbols are those of the generated tables)
;;; =========================================================================

(defconst *doc-real-id*     'real-id-indicating-citizenship)
(defconst *doc-passport*    'valid-us-passport)
(defconst *doc-military*    'military-id-with-us-birth)
(defconst *doc-govt-birth*  'govt-photo-id-showing-us-birth)
(defconst *doc-govt-photo*  'govt-photo-id)                 ; § 3(b)(5) anchor
(defconst *doc-birth-cert*  'certified-birth-certificate)   ; supporting only
(defconst *doc-nat-cert*    'naturalization-certificate)    ; supporting only

;; The constants really are members of the generated categories.
(defthm doc-constants-are-recognized
  (and (member-equal *doc-real-id*    *standalone-proof-types*)
       (member-equal *doc-passport*   *standalone-proof-types*)
       (member-equal *doc-military*   *standalone-proof-types*)
       (member-equal *doc-govt-birth* *standalone-proof-types*)
       (member-equal *doc-govt-photo* *anchor-photo-id-types*)
       (member-equal *doc-birth-cert* *supporting-document-types*)
       (member-equal *doc-nat-cert*   *supporting-document-types*))
  :rule-classes nil)

;;; =========================================================================
;;; 2. DOCUMENT RECOGNIZERS  (thin wrappers over the generated rules)
;;; =========================================================================

;; Is d a document type the statute recognizes anywhere in § 3(b)?
(defun qualifying-document-typep (d)
  (recognized-document-typep d))

;; Is every item in docs a recognized document type?
(defun qualifying-document-listp (docs)
  (all-in-catsp docs (append *standalone-proof-types*
                             *anchor-photo-id-types*
                             *supporting-document-types*)))

;; Does the bundle docs constitute documentary proof under § 3(b)?
(defun has-qualifying-docs-from-listp (docs)
  (documentary-proof-bundlep docs))

;;; =========================================================================
;;; Document recognizer theorems (concrete bundles — by evaluation)
;;; =========================================================================

(defthm no-docs-implies-no-proof
  (not (has-qualifying-docs-from-listp nil)))

(defthm passport-is-qualifying
  (has-qualifying-docs-from-listp (list *doc-passport*)))

;; § 3(b)(5): a birth certificate or naturalization certificate is proof
;; only TOGETHER WITH a government photo ID.
(defthm birth-cert-alone-is-not-qualifying
  (not (has-qualifying-docs-from-listp (list *doc-birth-cert*))))

(defthm nat-cert-alone-is-not-qualifying
  (not (has-qualifying-docs-from-listp (list *doc-nat-cert*))))

(defthm photo-id-alone-is-not-qualifying
  (not (has-qualifying-docs-from-listp (list *doc-govt-photo*))))

(defthm birth-cert-with-photo-id-is-qualifying
  (has-qualifying-docs-from-listp (list *doc-govt-photo* *doc-birth-cert*)))

(defthm nat-cert-with-photo-id-is-qualifying
  (has-qualifying-docs-from-listp (list *doc-nat-cert* *doc-govt-photo*)))

;;; =========================================================================
;;; General document-bundle theorems (instances of lib/enum_list)
;;; =========================================================================

;; Monotonicity: presenting MORE documents never destroys proof.
(defthm append-preserves-qualifying-document-left
  (implies (has-qualifying-docs-from-listp a)
           (has-qualifying-docs-from-listp (append a b))))

(defthm append-preserves-qualifying-document-right
  (implies (has-qualifying-docs-from-listp b)
           (has-qualifying-docs-from-listp (append a b))))

;; A recognized bundle stays recognized under append and removal.
(defthm qualifying-document-listp-append
  (implies (and (qualifying-document-listp a)
                (qualifying-document-listp b))
           (qualifying-document-listp (append a b))))

(defthm qualifying-document-listp-remove
  (implies (qualifying-document-listp docs)
           (qualifying-document-listp (remove-equal d docs))))

;; One standalone document anywhere in the bundle suffices.
(defthm member-standalone-document-implies-proof
  (implies (and (member-equal d docs)
                (member-equal d *standalone-proof-types*))
           (has-qualifying-docs-from-listp docs)))

;; An anchor photo ID plus any supporting document suffices.
(defthm anchor-plus-supporting-implies-proof
  (implies (and (member-equal a docs)
                (member-equal a *anchor-photo-id-types*)
                (member-equal d docs)
                (member-equal d *supporting-document-types*))
           (has-qualifying-docs-from-listp docs)))

;; Recognized is necessary but NOT sufficient (contrast v5's
;; nonempty-qualifying-list-has-docs, which was false under § 3(b)(5)):
;; a nonempty bundle of recognized documents that contains no standalone
;; document and no anchor photo ID is not proof.
(defthm recognized-without-standalone-or-anchor-is-not-proof
  (implies (and (none-in-catsp docs *standalone-proof-types*)
                (none-in-catsp docs *anchor-photo-id-types*))
           (not (has-qualifying-docs-from-listp docs))))

;;; =========================================================================
;;; 3. REGISTRATION STATE MACHINE  (edge table)
;;; Source: SAVE Act § 2(b)-(f), NVRA §§ 4-8
;;; =========================================================================

;; States, events and the edge table *reg-edges* are GENERATED into
;; federal_save_act_process_table.lisp from
;; data/parsed/federal_save_act_process_table.json (one § citation per edge;
;; the compiler rejects undeclared states/events and duplicate (state, event)
;; pairs, which would make lsm-step nondeterministic).

(defun reg-statep (s) (member-equal s *reg-states*))
(defun reg-eventp (e) (member-equal e *reg-events*))

(defun reg-next-state (current-state event)
  (lsm-step current-state event *reg-edges*))

(defun reg-run-trace (start-state events)
  (lsm-run start-state events *reg-edges*))

(defun reg-terminal-statep (s)
  (or (equal s *state-registered*)
      (equal s *state-denied*)))

;;; ---- Sets DERIVED from the table (not hand-listed) ----

;; States from which registration can be entered.
(defconst *reg-acceptance-states*
  (lsm-sources-into (list *state-registered*) *reg-edges*))

;; States from which denial can be entered.
(defconst *reg-denial-states*
  (lsm-sources-into (list *state-denied*) *reg-edges*))

;; Documentation theorems: what the derived sets actually are.
(defthm reg-acceptance-states-are-doc-accepted-and-alt-approved
  (equal *reg-acceptance-states*
         (list *state-doc-accepted* *state-alt-approved*))
  :rule-classes nil)

(defthm reg-denial-states-are-rejected-alt-denied-submitted
  (equal *reg-denial-states*
         (list *state-doc-rejected* *state-alt-denied* *state-submitted*))
  :rule-classes nil)

;;; =========================================================================
;;; 4. TABLE WELL-FORMEDNESS  (by evaluation)
;;; =========================================================================

(defthm reg-edges-well-formed
  (lsm-wf-tablep *reg-states* *reg-events* *reg-edges*)
  :rule-classes nil)

(defthm reg-terminal-states-have-no-exit
  (and (not (lsm-has-outgoing *state-registered* *reg-edges*))
       (not (lsm-has-outgoing *state-denied* *reg-edges*)))
  :rule-classes nil)

;;; =========================================================================
;;; 5. PROCESS INVARIANT THEOREMS (named paths — by evaluation)
;;; =========================================================================

(defthm process-inv-doc-path-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit* *evt-present-docs*
                              *evt-accept-docs* *evt-register*))
         *state-registered*))

(defthm process-inv-alt-path-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit* *evt-initiate-alt*
                              *evt-approve-alt* *evt-register*))
         *state-registered*))

(defthm process-inv-rejection-no-alt-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit* *evt-present-docs*
                              *evt-reject-docs* *evt-deny*))
         *state-denied*))

(defthm process-inv-alt-denied-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit* *evt-initiate-alt*
                              *evt-deny-alt* *evt-deny*))
         *state-denied*))

(defthm process-inv-no-docs-denies
  (equal (reg-run-trace *state-unsubmitted* (list *evt-submit* *evt-deny*))
         *state-denied*))

(defthm process-inv-no-skip-to-registered
  (not (equal (reg-next-state *state-unsubmitted* *evt-register*)
              *state-registered*)))

(defthm process-inv-no-skip-from-submitted
  (not (equal (reg-next-state *state-submitted* *evt-register*)
              *state-registered*)))

;; Connection of the state machine to the core denial trigger.
(defthm process-inv-denial-trigger-requires-no-presentation
  (implies (presents-documentary-proofp p x)
           (not (save-act-denial-triggerp p x))))

(defthm process-inv-denial-trigger-requires-no-alternative
  (implies (alternative-process-approvedp p x)
           (not (save-act-denial-triggerp p x))))
