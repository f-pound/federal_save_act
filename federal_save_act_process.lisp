(in-package "ACL2")

(include-book "federal_save_act_core")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_process.lisp  —  v5.2
;; Registration state machine and document-list recognizers.
;;
;; This book provides executable structure to the neutral vocabulary:
;;   1. Document type constants and recognizers
;;   2. Registration state machine with event traces
;;   3. Process invariant theorems
;;
;; This is a NEUTRAL book — no interpretive assumptions.
;; It depends only on core.lisp.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. DOCUMENT TYPE CONSTANTS
;;; Source: SAVE Act § 2(a) / NVRA § 3(b)(1)-(7)
;;; =========================================================================

(defconst *doc-real-id*     'real-id-indicating-citizenship)
(defconst *doc-passport*    'valid-us-passport)
(defconst *doc-military*    'military-id-with-us-birth)
(defconst *doc-govt-birth*  'govt-photo-id-showing-us-birth)
(defconst *doc-govt-supp*   'govt-photo-id-with-supporting-doc)
(defconst *doc-birth-cert*  'certified-birth-certificate)
(defconst *doc-nat-cert*    'naturalization-certificate)

;;; =========================================================================
;;; 2. DOCUMENT RECOGNIZERS
;;; =========================================================================

;; Is d a qualifying document type?
(defun qualifying-document-typep (d)
  (member-equal d (list *doc-real-id* *doc-passport* *doc-military*
                        *doc-govt-birth* *doc-govt-supp*
                        *doc-birth-cert* *doc-nat-cert*)))

;; Is docs a valid list of qualifying documents?
(defun qualifying-document-listp (docs)
  (if (endp docs)
      t
    (and (qualifying-document-typep (car docs))
         (qualifying-document-listp (cdr docs)))))

;; A person has documentary proof iff their document list is non-empty
;; and all items are qualifying documents.
(defun has-qualifying-docs-from-listp (docs)
  (and (consp docs)
       (qualifying-document-listp docs)))

;;; =========================================================================
;;; Document recognizer theorems
;;; =========================================================================

;; Empty document list means no proof
(defthm no-docs-implies-no-proof
  (not (has-qualifying-docs-from-listp nil)))

;; A list with a passport is qualifying
(defthm passport-is-qualifying
  (has-qualifying-docs-from-listp (list *doc-passport*)))

;; A list with a birth certificate is qualifying
(defthm birth-cert-is-qualifying
  (has-qualifying-docs-from-listp (list *doc-birth-cert*)))

;; A list with a naturalization certificate is qualifying
(defthm nat-cert-is-qualifying
  (has-qualifying-docs-from-listp (list *doc-nat-cert*)))

;;; =========================================================================
;;; v5: General recursive document-list theorems
;;;
;;; These prove properties over ARBITRARY document lists, not just
;;; specific named examples.  They use induction over the list structure.
;;; =========================================================================

;; If a qualifying document is a member of a list of qualifying docs,
;; then the list has qualifying documents.
;; (Induction on docs)
(defthm member-qualifying-document-implies-has-qualifying-document
  (implies (and (qualifying-document-listp docs)
                (consp docs)
                (member-equal d docs)
                (qualifying-document-typep d))
           (has-qualifying-docs-from-listp docs)))

;; Appending two qualifying lists: if a has qualifying docs and b is
;; a qualifying list, the result has qualifying docs.
;; (Induction on a)
(defthm append-preserves-qualifying-document-left
  (implies (and (has-qualifying-docs-from-listp a)
                (qualifying-document-listp b))
           (has-qualifying-docs-from-listp (append a b))))

;; Appending: if b has qualifying docs and a is a qualifying list,
;; the result has qualifying docs.
(defthm append-preserves-qualifying-document-right
  (implies (and (qualifying-document-listp a)
                (has-qualifying-docs-from-listp b))
           (has-qualifying-docs-from-listp (append a b))))

;; Qualifying-document-listp is preserved by append
(defthm qualifying-document-listp-append
  (implies (and (qualifying-document-listp a)
                (qualifying-document-listp b))
           (qualifying-document-listp (append a b))))

;; Removing ANY element from a qualifying-document-listp
;; preserves qualifying-document-listp.
(defthm qualifying-document-listp-remove
  (implies (qualifying-document-listp docs)
           (qualifying-document-listp (remove-equal d docs))))

;; A qualifying-document-listp with at least one element has qualifying docs
(defthm nonempty-qualifying-list-has-docs
  (implies (and (qualifying-document-listp docs)
                (consp docs))
           (has-qualifying-docs-from-listp docs)))

;;; =========================================================================
;;; 3. REGISTRATION STATE MACHINE
;;; Source: SAVE Act § 2(b)-(f), NVRA §§ 4-8
;;;
;;; States represent the lifecycle of a voter registration application.
;;; The state machine is neutral — it encodes the statutory process without
;;; any interpretive assumptions about outcomes.
;;; =========================================================================

;; Registration states
(defconst *state-unsubmitted*    'unsubmitted)
(defconst *state-submitted*      'submitted)
(defconst *state-doc-presented*  'doc-presented)
(defconst *state-doc-accepted*   'doc-accepted)
(defconst *state-doc-rejected*   'doc-rejected)
(defconst *state-alt-initiated*  'alt-initiated)
(defconst *state-alt-approved*   'alt-approved)
(defconst *state-alt-denied*     'alt-denied)
(defconst *state-registered*     'registered)
(defconst *state-denied*         'denied)

;; State recognizer
(defun reg-statep (s)
  (member-equal s (list *state-unsubmitted* *state-submitted*
                        *state-doc-presented* *state-doc-accepted*
                        *state-doc-rejected* *state-alt-initiated*
                        *state-alt-approved* *state-alt-denied*
                        *state-registered* *state-denied*)))

;; Registration events (transitions)
(defconst *evt-submit*          'submit-application)
(defconst *evt-present-docs*    'present-documents)
(defconst *evt-accept-docs*     'accept-documents)
(defconst *evt-reject-docs*     'reject-documents)
(defconst *evt-initiate-alt*    'initiate-alternative-process)
(defconst *evt-approve-alt*     'approve-alternative)
(defconst *evt-deny-alt*        'deny-alternative)
(defconst *evt-register*        'register)
(defconst *evt-deny*            'deny-registration)

;; Event recognizer
(defun reg-eventp (e)
  (member-equal e (list *evt-submit* *evt-present-docs*
                        *evt-accept-docs* *evt-reject-docs*
                        *evt-initiate-alt* *evt-approve-alt*
                        *evt-deny-alt* *evt-register* *evt-deny*)))

;; State transition function
;; Returns the next state given a current state and event.
;; Invalid transitions return the current state (no-op).
(defun reg-next-state (current-state event)
  (cond
   ;; Path 1: Normal application flow
   ((and (equal current-state *state-unsubmitted*)
         (equal event *evt-submit*))
    *state-submitted*)

   ((and (equal current-state *state-submitted*)
         (equal event *evt-present-docs*))
    *state-doc-presented*)

   ((and (equal current-state *state-doc-presented*)
         (equal event *evt-accept-docs*))
    *state-doc-accepted*)

   ((and (equal current-state *state-doc-presented*)
         (equal event *evt-reject-docs*))
    *state-doc-rejected*)

   ;; Path 2: Alternative process after doc rejection
   ((and (equal current-state *state-doc-rejected*)
         (equal event *evt-initiate-alt*))
    *state-alt-initiated*)

   ;; Path 2a: No docs presented at all → go straight to alternative
   ((and (equal current-state *state-submitted*)
         (equal event *evt-initiate-alt*))
    *state-alt-initiated*)

   ((and (equal current-state *state-alt-initiated*)
         (equal event *evt-approve-alt*))
    *state-alt-approved*)

   ((and (equal current-state *state-alt-initiated*)
         (equal event *evt-deny-alt*))
    *state-alt-denied*)

   ;; Terminal: doc-accepted or alt-approved → registered
   ((and (equal current-state *state-doc-accepted*)
         (equal event *evt-register*))
    *state-registered*)

   ((and (equal current-state *state-alt-approved*)
         (equal event *evt-register*))
    *state-registered*)

   ;; Terminal: doc-rejected (no alt) or alt-denied → denied
   ((and (equal current-state *state-doc-rejected*)
         (equal event *evt-deny*))
    *state-denied*)

   ((and (equal current-state *state-alt-denied*)
         (equal event *evt-deny*))
    *state-denied*)

   ;; Terminal: submitted but no docs and no alt → denied
   ((and (equal current-state *state-submitted*)
         (equal event *evt-deny*))
    *state-denied*)

   ;; Invalid transition → stay in current state
   (t current-state)))

;; Run a trace of events from a starting state
(defun reg-run-trace (start-state events)
  (if (endp events)
      start-state
    (reg-run-trace (reg-next-state start-state (car events))
                   (cdr events))))

;; Is a state terminal?
(defun reg-terminal-statep (s)
  (or (equal s *state-registered*)
      (equal s *state-denied*)))

;;; =========================================================================
;;; 4. PROCESS INVARIANT THEOREMS
;;; =========================================================================

;; Invariant: The normal doc-acceptance path leads to registration
(defthm process-inv-doc-path-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit*
                              *evt-present-docs*
                              *evt-accept-docs*
                              *evt-register*))
         *state-registered*))

;; Invariant: The alternative-approval path leads to registration
(defthm process-inv-alt-path-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit*
                              *evt-initiate-alt*
                              *evt-approve-alt*
                              *evt-register*))
         *state-registered*))

;; Invariant: Doc rejection + no alternative → denial
(defthm process-inv-rejection-no-alt-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit*
                              *evt-present-docs*
                              *evt-reject-docs*
                              *evt-deny*))
         *state-denied*))

;; Invariant: Alternative denial → denial
(defthm process-inv-alt-denied-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit*
                              *evt-initiate-alt*
                              *evt-deny-alt*
                              *evt-deny*))
         *state-denied*))

;; Invariant: No docs submitted + immediate denial → denied
(defthm process-inv-no-docs-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (list *evt-submit*
                              *evt-deny*))
         *state-denied*))

;; Invariant: Cannot jump from unsubmitted to registered
(defthm process-inv-no-skip-to-registered
  (not (equal (reg-next-state *state-unsubmitted* *evt-register*)
              *state-registered*)))

;; Invariant: Cannot jump from submitted to registered
(defthm process-inv-no-skip-from-submitted
  (not (equal (reg-next-state *state-submitted* *evt-register*)
              *state-registered*)))

;; Invariant: Denial trigger decomposes correctly
;; (This connects the state machine to the core predicates)
(defthm process-inv-denial-trigger-requires-no-presentation
  (implies (presents-documentary-proofp p x)
           (not (save-act-denial-triggerp p x))))

(defthm process-inv-denial-trigger-requires-no-alternative
  (implies (alternative-process-approvedp p x)
           (not (save-act-denial-triggerp p x))))
