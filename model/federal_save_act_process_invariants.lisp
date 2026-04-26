(in-package "ACL2")

(include-book "federal_save_act_process")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_process_invariants.lisp  —  v5.2
;; General state-machine invariants over ARBITRARY event traces.
;;
;; These theorems prove properties that hold for ALL possible traces,
;; not just the specific named examples in process.lisp.  This is the
;; key upgrade from v4: general inductive proofs over recursive structures.
;;
;; Proof technique: induction over the events list in reg-run-trace.
;; ACL2 automatically selects the induction scheme from the recursive
;; structure of reg-run-trace.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. TRACE HELPER FUNCTIONS
;;; =========================================================================

;; Does the event list contain a specific event?
(defun trace-contains-eventp (event events)
  (if (endp events)
      nil
    (or (equal (car events) event)
        (trace-contains-eventp event (cdr events)))))

;; Count occurrences of an event in a trace
(defun trace-count-event (event events)
  (if (endp events)
      0
    (+ (if (equal (car events) event) 1 0)
       (trace-count-event event (cdr events)))))

;;; =========================================================================
;;; 2. FUNDAMENTAL STATE EXCLUSION
;;;
;;; The registered and denied states are distinct symbols.
;;; No trace can reach both simultaneously.
;;; =========================================================================

;; Registered and denied are distinct states
(defthm terminal-state-registered-not-denied
  (not (equal 'registered 'denied))
  :rule-classes nil)

;; Symmetric
(defthm terminal-state-denied-not-registered
  (not (equal 'denied 'registered))
  :rule-classes nil)

;; A terminal state is either registered or denied, not both
(defthm terminal-state-exclusive
  (implies (reg-terminal-statep s)
           (or (and (equal s *state-registered*)
                    (not (equal s *state-denied*)))
               (and (equal s *state-denied*)
                    (not (equal s *state-registered*))))))

;;; =========================================================================
;;; 3. REGISTERED IMPLIES ACCEPTANCE EVENT IN TRACE
;;;
;;; If reg-run-trace reaches *state-registered*, then the trace must
;;; contain the *evt-register* event.
;;;
;;; Strategy: First prove a helper lemma about reg-next-state by
;;; exhaustive case analysis, then use induction on reg-run-trace.
;;; =========================================================================

;; Helper: reg-next-state only produces 'registered when event is 'register
;; Proved by exhaustive case analysis on the cond in reg-next-state
(defthm register-requires-register-event
  (implies (and (not (equal s *state-registered*))
                (equal (reg-next-state s event) *state-registered*))
           (equal event *evt-register*))
  :hints (("Goal" :in-theory (enable reg-next-state)))
  :rule-classes :forward-chaining)

;; If a trace from a non-registered state reaches registered,
;; it must contain the register event.
(defthm registered-implies-path-contains-register-event
  (implies (and (not (equal start *state-registered*))
                (equal (reg-run-trace start events) *state-registered*))
           (trace-contains-eventp *evt-register* events))
  :hints (("Goal" :induct (reg-run-trace start events))))

;;; =========================================================================
;;; 4. DENIED IMPLIES DENIAL EVENT IN TRACE
;;; =========================================================================

;; Helper: reg-next-state only produces 'denied when event is 'deny-registration
(defthm denied-requires-deny-event
  (implies (and (not (equal s *state-denied*))
                (equal (reg-next-state s event) *state-denied*))
           (equal event *evt-deny*))
  :hints (("Goal" :in-theory (enable reg-next-state)))
  :rule-classes :forward-chaining)

;; If a trace from a non-denied state reaches denied,
;; it must contain the deny event.
(defthm denied-implies-path-contains-deny-event
  (implies (and (not (equal start *state-denied*))
                (equal (reg-run-trace start events) *state-denied*))
           (trace-contains-eventp *evt-deny* events))
  :hints (("Goal" :induct (reg-run-trace start events))))

;;; =========================================================================
;;; 5. TERMINAL STATE STABILITY
;;;
;;; Once a trace reaches a terminal state, no further events change it.
;;; =========================================================================

;; No valid transition out of registered
(defthm registered-is-absorbing
  (equal (reg-next-state *state-registered* event)
         *state-registered*))

;; No valid transition out of denied
(defthm denied-is-absorbing
  (equal (reg-next-state *state-denied* event)
         *state-denied*))

;; Once registered, all subsequent events leave state as registered
(defthm registered-stays-registered
  (equal (reg-run-trace *state-registered* events)
         *state-registered*))

;; Once denied, all subsequent events leave state as denied
(defthm denied-stays-denied
  (equal (reg-run-trace *state-denied* events)
         *state-denied*))

;;; =========================================================================
;;; 6. VALID PATHS WITH ARBITRARY TRAILING EVENTS
;;;
;;; Specific valid paths always terminate as expected,
;;; even when arbitrary trailing events are appended.
;;; This proves that once a terminal state is reached,
;;; the outcome is locked in regardless of further events.
;;; =========================================================================

;; Alternative approval path always registers, regardless of trailing events
(defthm approval-path-always-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit*
                                      *evt-initiate-alt*
                                      *evt-approve-alt*
                                      *evt-register*)
                                trailing-events))
         *state-registered*))

;; Doc acceptance path always registers, regardless of trailing events
(defthm doc-acceptance-path-always-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit*
                                      *evt-present-docs*
                                      *evt-accept-docs*
                                      *evt-register*)
                                trailing-events))
         *state-registered*))

;;; =========================================================================
;;; 7. REGISTERED IMPLIES PRIOR ACCEPTANCE PATH
;;;
;;; The richer invariant: if a trace from a non-terminal state reaches
;;; *state-registered*, the trace must have passed through either
;;; *state-doc-accepted* or *state-alt-approved*.
;;;
;;; This is stronger than "registered implies register event in trace"
;;; because it proves the PRECONDITION for registration was met —
;;; either documents were accepted or the alternative was approved.
;;;
;;; Proof strategy:
;;;   1. Helper: reg-next-state producing registered requires the
;;;      prior state to be doc-accepted or alt-approved (case analysis).
;;;   2. Define trace-passed-through-acceptance-statep to check whether
;;;      the trace passes through either acceptance state.
;;;   3. Main theorem by induction on events.
;;; =========================================================================

;; Helper: The only states from which *evt-register* produces registered
;; are doc-accepted and alt-approved.
(defthm register-requires-acceptance-state
  (implies (and (not (equal s *state-registered*))
                (equal (reg-next-state s event) *state-registered*))
           (or (equal s *state-doc-accepted*)
               (equal s *state-alt-approved*)))
  :hints (("Goal" :in-theory (enable reg-next-state)))
  :rule-classes nil)

;; Did the trace pass through an acceptance state?
;; We check whether, at any point during execution, the intermediate
;; state was doc-accepted or alt-approved.
(defun trace-passed-through-acceptance-statep (start events)
  (declare (xargs :measure (acl2-count events)))
  (if (endp events)
      (or (equal start *state-doc-accepted*)
          (equal start *state-alt-approved*))
    (or (equal start *state-doc-accepted*)
        (equal start *state-alt-approved*)
        (trace-passed-through-acceptance-statep
         (reg-next-state start (car events))
         (cdr events)))))

;; Main theorem: if a trace from a non-registered start reaches
;; registered, it passed through doc-accepted or alt-approved.
(defthm registered-implies-prior-acceptance-path
  (implies (and (not (equal start *state-registered*))
                (equal (reg-run-trace start events) *state-registered*))
           (trace-passed-through-acceptance-statep start events))
  :hints (("Goal" :induct (reg-run-trace start events)))
  :rule-classes nil)
