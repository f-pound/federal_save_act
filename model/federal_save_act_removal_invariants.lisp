(in-package "ACL2")

(include-book "federal_save_act_removal_table")
(include-book "lib/lsm")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_removal_invariants.lisp  —  v6.0
;; NVRA § 8(k) removal process as a second client of lib/lsm.
;;
;; § 8(k): "A State shall remove an individual who is not a citizen of the
;; United States from the official list of eligible voters ... at any time
;; upon receipt of documentation or verified information that a registrant
;; is not a United States citizen."
;;
;; The table *rem-edges* (generated from the clause IR) contains the two
;; TEXT_FACT edges the statute names and five DUE_PROCESS_OVERLAY edges
;; (notice, contest, confirmation) that the statute does NOT name.  The
;; theorems below are all instances of lib/lsm lemmas discharged by
;; evaluating the table.  Together they state mechanically what the v5
;; reports could only say in prose: removal is reachable on the statutory
;; text alone without any notice or hearing event.
;;
;; This book is NEUTRAL: it does not assert that the absence of notice is
;; unconstitutional.  It proves what the statutory process does and does
;; not require, so that a due-process argument has a precise target.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun rem-next-state (s e) (lsm-step s e *rem-edges*))
(defun rem-run-trace (s events) (lsm-run s events *rem-edges*))
(defun rem-statep (s) (member-equal s *rem-states*))

;; The statutory (non-overlay) edges only.
(defconst *rem-text-edges*
  (list (list *rem-on-rolls*      *rem-evt-receive* *rem-info-received*)
        (list *rem-info-received* *rem-evt-remove*  *rem-removed*)))

(defthm rem-edges-well-formed
  (lsm-wf-tablep *rem-states* *rem-events* *rem-edges*)
  :rule-classes nil)

;;; =========================================================================
;;; 1. REMOVAL REQUIRES RECEIPT OF NONCITIZEN INFORMATION  (entry guard)
;;; Every state that can enter `removed` lies beyond `info-received`, and
;;; leaving `on-rolls` at all requires the receive event.
;;; =========================================================================

(defconst *rem-removal-sources*
  (lsm-sources-into (list *rem-removed*) *rem-edges*))

(defthm rem-removal-sources-are-info-noticed-contested
  (equal *rem-removal-sources*
         (list *rem-info-received* *rem-noticed* *rem-contested*))
  :rule-classes nil)

(defthm removal-implies-prior-information-receipt
  (implies (equal (rem-run-trace *rem-on-rolls* events) *rem-removed*)
           (some-in-catsp events (list *rem-evt-receive*)))
  :hints (("Goal" :use ((:instance lsm-run-exit-guard
                                   (s *rem-on-rolls*) (edges *rem-edges*))))))

;;; =========================================================================
;;; 2. THE STATUTORY PATH TO REMOVAL CONTAINS NO NOTICE AND NO HEARING
;;; (by evaluation of the concrete two-event trace)
;;; =========================================================================

(defconst *rem-statutory-path*
  (list *rem-evt-receive* *rem-evt-remove*))

(defthm statutory-path-removes
  (equal (rem-run-trace *rem-on-rolls* *rem-statutory-path*) *rem-removed*))

(defthm statutory-path-has-no-notice-or-hearing
  (none-in-catsp *rem-statutory-path*
                 (list *rem-evt-notify* *rem-evt-contest* *rem-evt-confirm*)))

;; Stronger: the statutory edges ALONE already reach removal — the overlay
;; is not needed for removal, only for reinstatement.
(defthm text-edges-alone-reach-removal
  (equal (lsm-run *rem-on-rolls* *rem-statutory-path* *rem-text-edges*)
         *rem-removed*))

;;; =========================================================================
;;; 3. NOTICE IS NOT AN ENTERING EVENT FOR REMOVAL  (event guard)
;;; The only event that ever enters `removed` is `remove`; notifying or
;;; contesting never moves a record into `removed`.
;;; =========================================================================

(defthm rem-events-into-removed-is-remove-only
  (equal (lsm-events-into (list *rem-removed*) *rem-edges*)
         (list *rem-evt-remove* *rem-evt-remove* *rem-evt-remove*))
  :rule-classes nil)

(defthm removal-requires-remove-event
  (implies (and (not (equal s *rem-removed*))
                (equal (rem-next-state s e) *rem-removed*))
           (equal e *rem-evt-remove*))
  :hints (("Goal" :use ((:instance lsm-step-event-guard
                                   (targets (list *rem-removed*))
                                   (edges *rem-edges*)))))
  :rule-classes :forward-chaining)

;;; =========================================================================
;;; 4. REMOVED IS ABSORBING: THE TEXT PROVIDES NO REINSTATEMENT
;;; =========================================================================

(defthm removed-is-absorbing
  (equal (rem-run-trace *rem-removed* events) *rem-removed*))

;; Reinstatement exists ONLY through the overlay (contested → on-rolls).
(defthm reinstatement-requires-contest-path
  (equal (lsm-sources-into (list *rem-on-rolls*) *rem-edges*)
         (list *rem-contested*))
  :rule-classes nil)

;;; =========================================================================
;;; 5. THE PROCESS NEVER LEAVES ITS STATE SPACE
;;; =========================================================================

(defthm rem-run-trace-stays-in-state-space
  (implies (rem-statep s)
           (rem-statep (rem-run-trace s events)))
  :hints (("Goal" :use ((:instance lsm-run-closed
                                   (set *rem-states*) (edges *rem-edges*))))))
