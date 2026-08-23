(in-package "ACL2")

(include-book "enum_list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; lib/lsm.lisp  —  Labeled State Machine library  (v6.0)
;;
;; A legal process (registration, removal, appeal, licensing ...) is a
;; deterministic labeled transition system: a finite table of edges
;;
;;        (from-state  event  to-state)
;;
;; with the convention that an event with no matching edge is a no-op.
;; v5 wrote the SAVE Act registration machine as a 13-clause `cond` and
;; proved every invariant by case-splitting that `cond`.  Those proofs
;; were brittle (one extra clause breaks hint structure) and not reusable.
;;
;; This book instead proves the invariants ONCE over an arbitrary edge
;; table `edges`.  A statute-specific book then supplies its table as a
;; defconst and obtains each invariant by instantiation, where ACL2
;; discharges the side conditions by EVALUATING the table:
;;
;;   lsm-sources-into   — which states can enter a target set?
;;   lsm-events-into    — which events can enter a target set?
;;   lsm-has-outgoing   — does a state have any exit?  (no ⇒ absorbing)
;;   lsm-closedp        — is a state set closed under the edge table?
;;
;; Generic theorems (all hint-free):
;;   lsm-step-entry-guard / lsm-run-entry-guard
;;       reaching a target set from outside it requires passing through a
;;       state in lsm-sources-into   ("no registration without acceptance")
;;   lsm-step-event-guard / lsm-run-event-guard
;;       reaching a target set requires an event in lsm-events-into
;;   lsm-step-no-skip
;;       a state outside the source set cannot enter the targets in one step
;;   lsm-run-closed
;;       a closed set is an inductive invariant of lsm-run
;;   lsm-step-absorbing / lsm-run-absorbing
;;       a state with no outgoing edge is fixed by every trace
;;   lsm-run-append
;;       traces compose  (prefix reaches terminal ⇒ suffix is irrelevant)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. Edge table, step, run
;;; =========================================================================

(defun lsm-edge-from (edge) (car edge))
(defun lsm-edge-event (edge) (cadr edge))
(defun lsm-edge-to (edge) (caddr edge))

;; First edge matching (s, e), or nil.
(defun lsm-lookup (s e edges)
  (cond ((endp edges) nil)
        ((and (equal (lsm-edge-from (car edges)) s)
              (equal (lsm-edge-event (car edges)) e))
         (car edges))
        (t (lsm-lookup s e (cdr edges)))))

;; One step.  No matching edge ⇒ stay.
(defun lsm-step (s e edges)
  (let ((edge (lsm-lookup s e edges)))
    (if edge (lsm-edge-to edge) s)))

;; Run a trace of events.
(defun lsm-run (s events edges)
  (if (endp events)
      s
    (lsm-run (lsm-step s (car events) edges) (cdr events) edges)))

;;; =========================================================================
;;; 2. Table queries (executable — ACL2 evaluates them on concrete tables)
;;; =========================================================================

;; Does s have at least one outgoing edge?
(defun lsm-has-outgoing (s edges)
  (cond ((endp edges) nil)
        ((equal (lsm-edge-from (car edges)) s) t)
        (t (lsm-has-outgoing s (cdr edges)))))

;; From-states of edges that land in `targets`.
(defun lsm-sources-into (targets edges)
  (cond ((endp edges) nil)
        ((member-equal (lsm-edge-to (car edges)) targets)
         (cons (lsm-edge-from (car edges))
               (lsm-sources-into targets (cdr edges))))
        (t (lsm-sources-into targets (cdr edges)))))

;; Events of edges that land in `targets`.
(defun lsm-events-into (targets edges)
  (cond ((endp edges) nil)
        ((member-equal (lsm-edge-to (car edges)) targets)
         (cons (lsm-edge-event (car edges))
               (lsm-events-into targets (cdr edges))))
        (t (lsm-events-into targets (cdr edges)))))

;; Events of edges that leave `s`.
(defun lsm-events-from (s edges)
  (cond ((endp edges) nil)
        ((equal (lsm-edge-from (car edges)) s)
         (cons (lsm-edge-event (car edges))
               (lsm-events-from s (cdr edges))))
        (t (lsm-events-from s (cdr edges)))))

;; Well-formed table: every edge stays inside the declared state and
;; event alphabets.
(defun lsm-wf-tablep (states events edges)
  (cond ((endp edges) t)
        (t (and (member-equal (lsm-edge-from (car edges)) states)
                (member-equal (lsm-edge-event (car edges)) events)
                (member-equal (lsm-edge-to (car edges)) states)
                (lsm-wf-tablep states events (cdr edges))))))

;; Is `set` closed under the table EXCEPT via edges whose event is in `evs`?
;; (every edge leaving `set` either stays in `set` or carries an event in evs)
(defun lsm-closedp-except (set evs edges)
  (cond ((endp edges) t)
        ((and (member-equal (lsm-edge-from (car edges)) set)
              (not (member-equal (lsm-edge-to (car edges)) set))
              (not (member-equal (lsm-edge-event (car edges)) evs)))
         nil)
        (t (lsm-closedp-except set evs (cdr edges)))))

;; Is `set` closed under the table?  (every edge leaving `set` stays in it)
(defun lsm-closedp (set edges)
  (cond ((endp edges) t)
        ((and (member-equal (lsm-edge-from (car edges)) set)
              (not (member-equal (lsm-edge-to (car edges)) set)))
         nil)
        (t (lsm-closedp set (cdr edges)))))

;;; =========================================================================
;;; 3. Trace predicates
;;; =========================================================================

;; Does the run from s over events visit a state in `states`?
;; (start state and every intermediate/final state are checked)
(defun lsm-trace-visits (states s events edges)
  (declare (xargs :measure (acl2-count events)))
  (if (endp events)
      (if (member-equal s states) t nil)
    (or (if (member-equal s states) t nil)
        (lsm-trace-visits states (lsm-step s (car events) edges)
                          (cdr events) edges))))

;;; =========================================================================
;;; 4. Lookup facts
;;; =========================================================================

(defthm lsm-lookup-from
  (implies (lsm-lookup s e edges)
           (equal (lsm-edge-from (lsm-lookup s e edges)) s)))

(defthm lsm-lookup-event
  (implies (lsm-lookup s e edges)
           (equal (lsm-edge-event (lsm-lookup s e edges)) e)))

(defthm lsm-lookup-member
  (implies (lsm-lookup s e edges)
           (member-equal (lsm-lookup s e edges) edges)))

(defthm lsm-lookup-when-no-outgoing
  (implies (not (lsm-has-outgoing s edges))
           (not (lsm-lookup s e edges))))

(defthm lsm-lookup-closed
  (implies (and (lsm-closedp set edges)
                (member-equal s set)
                (lsm-lookup s e edges))
           (member-equal (lsm-edge-to (lsm-lookup s e edges)) set)))

(defthm lsm-lookup-entry-guard
  (implies (and (lsm-lookup s e edges)
                (member-equal (lsm-edge-to (lsm-lookup s e edges)) targets))
           (member-equal s (lsm-sources-into targets edges))))

(defthm lsm-lookup-event-guard
  (implies (and (lsm-lookup s e edges)
                (member-equal (lsm-edge-to (lsm-lookup s e edges)) targets))
           (member-equal e (lsm-events-into targets edges))))

(defthm lsm-lookup-closed-except
  (implies (and (lsm-closedp-except set evs edges)
                (member-equal s set)
                (not (member-equal e evs))
                (lsm-lookup s e edges))
           (member-equal (lsm-edge-to (lsm-lookup s e edges)) set)))

(defthm lsm-lookup-exit-guard
  (implies (lsm-lookup s e edges)
           (member-equal e (lsm-events-from s edges))))

;; A well-formed table keeps the whole state space closed.
(defthm lsm-wf-tablep-implies-closedp
  (implies (lsm-wf-tablep states events edges)
           (lsm-closedp states edges)))

;; LAYER BOUNDARY.  From here on, edges are abstract: the step-level
;; theorems below are proved from the lookup facts alone, and the
;; run-level theorems from the step-level ones.  (Executable counterparts
;; stay enabled, so concrete tables still evaluate in client books.)
(in-theory (disable lsm-edge-from lsm-edge-event lsm-edge-to lsm-lookup))

;;; =========================================================================
;;; 5. Step-level theorems
;;; =========================================================================

(defthm lsm-step-absorbing
  (implies (not (lsm-has-outgoing s edges))
           (equal (lsm-step s e edges) s)))

(defthm lsm-step-closed
  (implies (and (lsm-closedp set edges)
                (member-equal s set))
           (member-equal (lsm-step s e edges) set)))

(defthm lsm-step-entry-guard
  (implies (and (not (member-equal s targets))
                (member-equal (lsm-step s e edges) targets))
           (member-equal s (lsm-sources-into targets edges))))

(defthm lsm-step-no-skip
  (implies (and (not (member-equal s targets))
                (not (member-equal s (lsm-sources-into targets edges))))
           (not (member-equal (lsm-step s e edges) targets))))

(defthm lsm-step-event-guard
  (implies (and (not (member-equal s targets))
                (member-equal (lsm-step s e edges) targets))
           (member-equal e (lsm-events-into targets edges))))

;; A closed-except set is left only by an event in evs.
(defthm lsm-step-closed-except
  (implies (and (lsm-closedp-except set evs edges)
                (member-equal s set)
                (not (member-equal e evs)))
           (member-equal (lsm-step s e edges) set)))

;; Leaving a state requires one of its outgoing events.
(defthm lsm-step-exit-guard
  (implies (not (equal (lsm-step s e edges) s))
           (member-equal e (lsm-events-from s edges))))

;; Contrapositive oriented as a rewrite: an event that is not an outgoing
;; event of s leaves s fixed.
(defthm lsm-step-noop-when-not-outgoing-event
  (implies (not (member-equal e (lsm-events-from s edges)))
           (equal (lsm-step s e edges) s)))

;; LAYER BOUNDARY: run-level theorems use only the step-level theorems.
(in-theory (disable lsm-step))

;;; =========================================================================
;;; 6. Absorbing states
;;; =========================================================================

(defthm lsm-run-absorbing
  (implies (not (lsm-has-outgoing s edges))
           (equal (lsm-run s events edges) s)))

;;; =========================================================================
;;; 7. Trace composition
;;; =========================================================================

(defthm lsm-run-append
  (equal (lsm-run s (append a b) edges)
         (lsm-run (lsm-run s a edges) b edges)))

;;; =========================================================================
;;; 8. Closed sets are inductive invariants
;;; =========================================================================

(defthm lsm-run-closed
  (implies (and (lsm-closedp set edges)
                (member-equal s set))
           (member-equal (lsm-run s events edges) set)))

;;; =========================================================================
;;; 9. Entry guards:  entering `targets` requires a source state
;;; =========================================================================

;; Single step: if s is outside targets and the step lands in targets,
;; then s is one of the table's sources into targets.
;; Contrapositive, stated for direct use: a state that is neither in the
;; targets nor a source into them cannot enter them in one step.
;; Whole trace: reaching targets from outside visits a source state.
(defthm lsm-run-entry-guard
  (implies (and (not (member-equal s targets))
                (member-equal (lsm-run s events edges) targets))
           (lsm-trace-visits (lsm-sources-into targets edges) s events edges)))

;;; =========================================================================
;;; 10. Event guards:  entering `targets` requires an entering event
;;; =========================================================================

;; Whole trace: reaching targets from outside requires that some event in
;; the trace is an entering event (reuses some-in-catsp from enum_list).
(defthm lsm-run-event-guard
  (implies (and (not (member-equal s targets))
                (member-equal (lsm-run s events edges) targets))
           (some-in-catsp events (lsm-events-into targets edges))))

;;; =========================================================================
;;; 11. Exit guards:  leaving a state requires one of its outgoing events
;;; =========================================================================

(defthm lsm-run-exit-guard
  (implies (not (equal (lsm-run s events edges) s))
           (some-in-catsp events (lsm-events-from s edges))))

;;; =========================================================================
;;; 12. Gated exit:  leaving a closed-except set requires a gate event
;;; ("a provisional ballot is counted only if a cure event occurred")
;;; =========================================================================

(defthm lsm-run-closed-except
  (implies (and (lsm-closedp-except set evs edges)
                (member-equal s set)
                (not (member-equal (lsm-run s events edges) set)))
           (some-in-catsp events evs)))
