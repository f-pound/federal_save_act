(in-package "ACL2")

(include-book "federal_save_act_process")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_process_invariants.lisp  —  v6.0
;; General state-machine invariants over ARBITRARY event traces.
;;
;; v5 proved each of these by induction over reg-run-trace plus a
;; case-split helper over the 13-clause cond.  v6 proves each one as an
;; INSTANCE of a lib/lsm theorem: the only statute-specific work ACL2
;; does is evaluate *reg-edges* queries (sources-into, events-into,
;; has-outgoing).  No induction, no case analysis, in this book.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. TRACE HELPER FUNCTIONS  (wrappers over library predicates)
;;; =========================================================================

(defun trace-contains-eventp (event events)
  (some-in-catsp events (list event)))

(defun trace-count-event (event events)
  (if (endp events)
      0
    (+ (if (equal (car events) event) 1 0)
       (trace-count-event event (cdr events)))))

;; Did the run pass through an acceptance state?
(defun trace-passed-through-acceptance-statep (start events)
  (lsm-trace-visits *reg-acceptance-states* start events *reg-edges*))

;;; =========================================================================
;;; 2. FUNDAMENTAL STATE EXCLUSION
;;; =========================================================================

(defthm terminal-state-registered-not-denied
  (not (equal 'registered 'denied))
  :rule-classes nil)

(defthm terminal-state-denied-not-registered
  (not (equal 'denied 'registered))
  :rule-classes nil)

(defthm terminal-state-exclusive
  (implies (reg-terminal-statep s)
           (or (and (equal s *state-registered*)
                    (not (equal s *state-denied*)))
               (and (equal s *state-denied*)
                    (not (equal s *state-registered*))))))

;;; =========================================================================
;;; 3. REGISTERED IMPLIES ACCEPTANCE EVENT IN TRACE
;;;    Instance of lsm-step-event-guard / lsm-run-event-guard with
;;;    targets = (registered);  lsm-events-into evaluates to (register register).
;;; =========================================================================

(defthm register-requires-register-event
  (implies (and (not (equal s *state-registered*))
                (equal (reg-next-state s event) *state-registered*))
           (equal event *evt-register*))
  :hints (("Goal" :use ((:instance lsm-step-event-guard
                                   (targets (list *state-registered*))
                                   (e event) (edges *reg-edges*)))))
  :rule-classes :forward-chaining)

(defthm registered-implies-path-contains-register-event
  (implies (and (not (equal start *state-registered*))
                (equal (reg-run-trace start events) *state-registered*))
           (trace-contains-eventp *evt-register* events))
  :hints (("Goal" :use ((:instance lsm-run-event-guard
                                   (targets (list *state-registered*))
                                   (s start) (edges *reg-edges*))))))

;;; =========================================================================
;;; 4. DENIED IMPLIES DENIAL EVENT IN TRACE
;;; =========================================================================

(defthm denied-requires-deny-event
  (implies (and (not (equal s *state-denied*))
                (equal (reg-next-state s event) *state-denied*))
           (equal event *evt-deny*))
  :hints (("Goal" :use ((:instance lsm-step-event-guard
                                   (targets (list *state-denied*))
                                   (e event) (edges *reg-edges*)))))
  :rule-classes :forward-chaining)

(defthm denied-implies-path-contains-deny-event
  (implies (and (not (equal start *state-denied*))
                (equal (reg-run-trace start events) *state-denied*))
           (trace-contains-eventp *evt-deny* events))
  :hints (("Goal" :use ((:instance lsm-run-event-guard
                                   (targets (list *state-denied*))
                                   (s start) (edges *reg-edges*))))))

;;; =========================================================================
;;; 5. TERMINAL STATE STABILITY
;;;    Instances of lsm-step-absorbing / lsm-run-absorbing; the side
;;;    condition (not (lsm-has-outgoing ...)) is decided by evaluation.
;;; =========================================================================

(defthm registered-is-absorbing
  (equal (reg-next-state *state-registered* event) *state-registered*))

(defthm denied-is-absorbing
  (equal (reg-next-state *state-denied* event) *state-denied*))

(defthm registered-stays-registered
  (equal (reg-run-trace *state-registered* events) *state-registered*))

(defthm denied-stays-denied
  (equal (reg-run-trace *state-denied* events) *state-denied*))

;;; =========================================================================
;;; 6. VALID PATHS WITH ARBITRARY TRAILING EVENTS
;;;    Instance of lsm-run-append: the prefix evaluates to a terminal
;;;    state, then lsm-run-absorbing finishes.
;;; =========================================================================

(defthm approval-path-always-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit* *evt-initiate-alt*
                                      *evt-approve-alt* *evt-register*)
                                trailing-events))
         *state-registered*))

(defthm doc-acceptance-path-always-registers
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit* *evt-present-docs*
                                      *evt-accept-docs* *evt-register*)
                                trailing-events))
         *state-registered*))

;;; =========================================================================
;;; 7. REGISTERED IMPLIES PRIOR ACCEPTANCE PATH
;;;    Instance of lsm-run-entry-guard with targets = (registered).
;;;    *reg-acceptance-states* IS (lsm-sources-into '(registered) *reg-edges*)
;;;    by definition, so the conclusion matches syntactically.
;;; =========================================================================

(defthm register-requires-acceptance-state
  (implies (and (not (equal s *state-registered*))
                (equal (reg-next-state s event) *state-registered*))
           (or (equal s *state-doc-accepted*)
               (equal s *state-alt-approved*)))
  :hints (("Goal" :use ((:instance lsm-step-entry-guard
                                   (targets (list *state-registered*))
                                   (e event) (edges *reg-edges*)))))
  :rule-classes nil)

(defthm registered-implies-prior-acceptance-path
  (implies (and (not (equal start *state-registered*))
                (equal (reg-run-trace start events) *state-registered*))
           (trace-passed-through-acceptance-statep start events))
  :hints (("Goal" :use ((:instance lsm-run-entry-guard
                                   (targets (list *state-registered*))
                                   (s start) (edges *reg-edges*)))))
  :rule-classes nil)

;;; =========================================================================
;;; 8. THE PROCESS NEVER LEAVES ITS STATE SPACE
;;;    Instance of lsm-run-closed; closure follows from table
;;;    well-formedness (lsm-wf-tablep-implies-closedp) by evaluation.
;;; =========================================================================

(defthm reg-run-trace-stays-in-state-space
  (implies (reg-statep s)
           (reg-statep (reg-run-trace s events)))
  :hints (("Goal" :use ((:instance lsm-run-closed
                                   (set *reg-states*) (edges *reg-edges*))))))
