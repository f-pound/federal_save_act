(in-package "ACL2")

(include-book "federal_save_act_process_invariants")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_deep_process_invariants.lisp  —  v6.0
;;
;; Deeper invariants relevant to due-process analysis:
;;   - terminal states are absorbing under arbitrary future events
;;   - evaluation stages cannot be skipped
;;   - denial requires a denial-triggering path
;;   - registration cannot occur without prior submission
;;
;; All are instances of lib/lsm theorems (see process_invariants.lisp for
;; the pattern).  Legal relevance comments are retained from v5.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. TERMINAL STATE STABILITY UNDER ARBITRARY TRACES
;;; Legal relevance: once a registration decision is made, subsequent
;;; administrative events do not retroactively alter it (the model has no
;;; reopening mechanism).
;;; =========================================================================

(defthm terminal-state-remains-terminal-under-run-trace
  (implies (reg-terminal-statep s)
           (equal (reg-run-trace s events) s)))

;;; =========================================================================
;;; 2. NO DIRECT SUBMISSION TO REGISTRATION
;;; Legal relevance: documentary-proof or alternative-process evaluation
;;; cannot be skipped.  Instance of lsm-step-no-skip: submitted and
;;; unsubmitted are not in *reg-acceptance-states* (evaluated).
;;; =========================================================================

(defthm no-single-step-submission-to-registration
  (not (equal (reg-next-state *state-submitted* event) *state-registered*))
  :hints (("Goal" :use ((:instance lsm-step-no-skip
                                   (targets (list *state-registered*))
                                   (s *state-submitted*) (e event)
                                   (edges *reg-edges*))))))

(defthm no-single-step-unsubmitted-to-registration
  (not (equal (reg-next-state *state-unsubmitted* event) *state-registered*))
  :hints (("Goal" :use ((:instance lsm-step-no-skip
                                   (targets (list *state-registered*))
                                   (s *state-unsubmitted*) (e event)
                                   (edges *reg-edges*))))))

;; Generalisation v5 could not state cheaply: NO state outside the derived
;; acceptance set can reach registered in one step.
(defthm only-acceptance-states-register
  (implies (and (not (equal s *state-registered*))
                (not (member-equal s *reg-acceptance-states*)))
           (not (equal (reg-next-state s event) *state-registered*)))
  :hints (("Goal" :use ((:instance lsm-step-no-skip
                                   (targets (list *state-registered*))
                                   (e event) (edges *reg-edges*))))))

;;; =========================================================================
;;; 3. DENIED IMPLIES DENIAL PATH
;;; Legal relevance: denial cannot occur arbitrarily — documentary proof
;;; failed, the alternative process was denied, or the applicant was denied
;;; directly from submission.
;;; =========================================================================

(defthm denied-requires-denial-state
  (implies (and (not (equal s *state-denied*))
                (equal (reg-next-state s event) *state-denied*))
           (or (equal s *state-doc-rejected*)
               (equal s *state-alt-denied*)
               (equal s *state-submitted*)))
  :hints (("Goal" :use ((:instance lsm-step-entry-guard
                                   (targets (list *state-denied*))
                                   (e event) (edges *reg-edges*)))))
  :rule-classes nil)

(defun trace-passed-through-denial-statep (start events)
  (lsm-trace-visits *reg-denial-states* start events *reg-edges*))

(defthm denied-implies-prior-denial-path
  (implies (and (not (equal start *state-denied*))
                (equal (reg-run-trace start events) *state-denied*))
           (trace-passed-through-denial-statep start events))
  :hints (("Goal" :use ((:instance lsm-run-entry-guard
                                   (targets (list *state-denied*))
                                   (s start) (edges *reg-edges*)))))
  :rule-classes nil)

;;; =========================================================================
;;; 4. NO REGISTRATION WITHOUT SUBMISSION
;;; Legal relevance: you cannot be registered without first submitting an
;;; application.  Instance of the EXIT guards: leaving unsubmitted at all
;;; requires an event in (lsm-events-from 'unsubmitted) = (submit).
;;; =========================================================================

(defthm unsubmitted-requires-submit-to-leave
  (implies (and (equal s *state-unsubmitted*)
                (not (equal (reg-next-state s event) *state-unsubmitted*)))
           (equal event *evt-submit*))
  :hints (("Goal" :use ((:instance lsm-step-exit-guard
                                   (s *state-unsubmitted*) (e event)
                                   (edges *reg-edges*)))))
  :rule-classes :forward-chaining)

(defthm no-registration-without-submission
  (implies (equal (reg-run-trace *state-unsubmitted* events)
                  *state-registered*)
           (trace-contains-eventp *evt-submit* events))
  :hints (("Goal" :use ((:instance lsm-run-exit-guard
                                   (s *state-unsubmitted*)
                                   (edges *reg-edges*)))))
  :rule-classes nil)

;; Stronger, and free: reaching ANY other state from unsubmitted needs submit.
(defthm leaving-unsubmitted-requires-submission
  (implies (not (equal (reg-run-trace *state-unsubmitted* events)
                       *state-unsubmitted*))
           (trace-contains-eventp *evt-submit* events))
  :hints (("Goal" :use ((:instance lsm-run-exit-guard
                                   (s *state-unsubmitted*)
                                   (edges *reg-edges*))))))

;;; =========================================================================
;;; 5./6. NAMED DENIAL PATHS WITH TRAILING EVENTS
;;; =========================================================================

(defthm alt-denied-path-always-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit* *evt-initiate-alt*
                                      *evt-deny-alt* *evt-deny*)
                                trailing-events))
         *state-denied*))

(defthm doc-rejected-direct-denial-path
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit* *evt-present-docs*
                                      *evt-reject-docs* *evt-deny*)
                                trailing-events))
         *state-denied*))
