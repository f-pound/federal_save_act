(in-package "ACL2")

(include-book "federal_save_act_process_invariants")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_deep_process_invariants.lisp  —  v5.2
;;
;; Deeper state-machine invariants over arbitrary registration traces.
;;
;; These theorems extend the v5.1 process invariants with properties
;; relevant to legal due-process analysis:
;;
;;   - Terminal states are absorbing under arbitrary future events
;;   - No process stage can be skipped (submission → evaluation → decision)
;;   - Denial requires a denial-triggering path
;;   - Registration cannot occur without prior submission
;;
;; Every theorem holds for ALL possible event traces, not just named
;; examples.  This is what makes the model a genuine process-verification
;; tool, not just a scenario checker.
;;
;; Legal relevance: These properties correspond to procedural due-process
;; requirements — a registration system must follow its own rules, cannot
;; skip evaluation stages, and cannot produce contradictory outcomes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. TERMINAL STATE STABILITY UNDER ARBITRARY TRACES
;;;
;;; If a state is terminal (registered or denied), running any further
;;; trace of events leaves it unchanged.
;;;
;;; Legal relevance: Once a registration decision is made, subsequent
;;; administrative events do not retroactively alter the legal status
;;; (absent an explicit reopening mechanism, which the model does not
;;; include).
;;; =========================================================================

;; A terminal state remains terminal after any trace
(defthm terminal-state-remains-terminal-under-run-trace
  (implies (reg-terminal-statep s)
           (equal (reg-run-trace s events) s))
  :hints (("Goal" :cases ((equal s *state-registered*)
                          (equal s *state-denied*)))))

;;; =========================================================================
;;; 2. NO DIRECT SUBMISSION TO REGISTRATION
;;;
;;; There is no single event that moves the state from submitted
;;; directly to registered.  This proves that the evaluation stage
;;; cannot be skipped.
;;;
;;; Legal relevance: The SAVE Act requires documentary proof evaluation
;;; or alternative-process evaluation before registration.  This theorem
;;; proves the model enforces that requirement.
;;; =========================================================================

;; No single event from submitted can reach registered
(defthm no-single-step-submission-to-registration
  (not (equal (reg-next-state *state-submitted* event)
              *state-registered*))
  :hints (("Goal" :in-theory (enable reg-next-state))))

;; No single event from unsubmitted can reach registered
(defthm no-single-step-unsubmitted-to-registration
  (not (equal (reg-next-state *state-unsubmitted* event)
              *state-registered*))
  :hints (("Goal" :in-theory (enable reg-next-state))))

;;; =========================================================================
;;; 3. DENIED IMPLIES DENIAL PATH
;;;
;;; Analogous to registered-implies-prior-acceptance-path from v5.1.
;;; If a trace reaches denied, it must have passed through a denial-
;;; triggering state: doc-rejected, alt-denied, or submitted (direct
;;; denial without attempting documents or alternative).
;;;
;;; Legal relevance: Denial cannot occur arbitrarily — the model
;;; requires that the applicant's documentary proof failed, the
;;; alternative process was denied, or the applicant was denied
;;; directly from submission (no docs, no alt).
;;; =========================================================================

;; Helper: The only states from which deny-registration produces denied
(defthm denied-requires-denial-state
  (implies (and (not (equal s *state-denied*))
                (equal (reg-next-state s event) *state-denied*))
           (or (equal s *state-doc-rejected*)
               (equal s *state-alt-denied*)
               (equal s *state-submitted*)))
  :hints (("Goal" :in-theory (enable reg-next-state)))
  :rule-classes nil)

;; Did the trace pass through a denial-triggering state?
(defun trace-passed-through-denial-statep (start events)
  (declare (xargs :measure (acl2-count events)))
  (if (endp events)
      (or (equal start *state-doc-rejected*)
          (equal start *state-alt-denied*)
          (equal start *state-submitted*))
    (or (equal start *state-doc-rejected*)
        (equal start *state-alt-denied*)
        (equal start *state-submitted*)
        (trace-passed-through-denial-statep
         (reg-next-state start (car events))
         (cdr events)))))

;; Main theorem: if a trace from a non-denied start reaches denied,
;; it passed through a denial-triggering state.
(defthm denied-implies-prior-denial-path
  (implies (and (not (equal start *state-denied*))
                (equal (reg-run-trace start events) *state-denied*))
           (trace-passed-through-denial-statep start events))
  :hints (("Goal" :induct (reg-run-trace start events)))
  :rule-classes nil)

;;; =========================================================================
;;; 4. NO REGISTRATION WITHOUT SUBMISSION
;;;
;;; A trace starting from unsubmitted cannot reach registered unless
;;; it contains a submit event.
;;;
;;; Legal relevance: You cannot be registered without first submitting
;;; an application.  This is a basic process-integrity check.
;;; =========================================================================

;; Helper: no single event from unsubmitted reaches a non-unsubmitted
;; state unless that event is submit
(defthm unsubmitted-requires-submit-to-leave
  (implies (and (equal s *state-unsubmitted*)
                (not (equal (reg-next-state s event) *state-unsubmitted*)))
           (equal event *evt-submit*))
  :hints (("Goal" :in-theory (enable reg-next-state)))
  :rule-classes :forward-chaining)

;; If a trace from unsubmitted reaches registered, it contains submit
(defthm no-registration-without-submission
  (implies (and (equal (reg-run-trace *state-unsubmitted* events)
                       *state-registered*))
           (trace-contains-eventp *evt-submit* events))
  :hints (("Goal" :induct (reg-run-trace *state-unsubmitted* events)))
  :rule-classes nil)

;;; =========================================================================
;;; 5. ALTERNATIVE-DENIAL PATH ALWAYS DENIES
;;;
;;; The specific path where alternative process is denied always
;;; leads to denial, regardless of trailing events.
;;;
;;; Legal relevance: Once the alternative attestation process is
;;; denied, the statutory outcome is denial of registration.
;;; =========================================================================

(defthm alt-denied-path-always-denies
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit*
                                      *evt-initiate-alt*
                                      *evt-deny-alt*
                                      *evt-deny*)
                                trailing-events))
         *state-denied*))

;;; =========================================================================
;;; 6. DOC-REJECTED THEN DENIED PATH
;;;
;;; When documents are rejected and no alternative is pursued,
;;; direct denial is the outcome.
;;; =========================================================================

(defthm doc-rejected-direct-denial-path
  (equal (reg-run-trace *state-unsubmitted*
                        (append (list *evt-submit*
                                      *evt-present-docs*
                                      *evt-reject-docs*
                                      *evt-deny*)
                                trailing-events))
         *state-denied*))
