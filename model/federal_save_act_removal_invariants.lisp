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

;; The § 8(k) statutory edges only (both texts).
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
  ;; v6.6: `noticed` appears twice — once via the overlay `remove` edge and
  ;; once via the S. 1383 `opportunity-lapses` edge.
  (equal *rem-removal-sources*
         (list *rem-info-received* *rem-noticed* *rem-contested* *rem-noticed*))
  :rule-classes nil)

(defthm removal-implies-prior-information-receipt
  ;; v6.6: leaving the rolls starts either with § 8(k) receipt of verified
  ;; information or with the S. 1383 SAVE-system match.
  (implies (equal (rem-run-trace *rem-on-rolls* events) *rem-removed*)
           (some-in-catsp events (list *rem-evt-receive* *rem-evt-save-match*)))
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

(defthm rem-events-into-removed
  ;; v6.6: the S. 1383 systematic path adds `opportunity-lapses` (after notice).
  (equal (lsm-events-into (list *rem-removed*) *rem-edges*)
         (list *rem-evt-remove* *rem-evt-remove* *rem-evt-remove* *rem-evt-opportunity-lapses*))
  :rule-classes nil)

(defthm removal-requires-remove-or-lapse-event
  (implies (and (not (equal s *rem-removed*))
                (equal (rem-next-state s e) *rem-removed*))
           (or (equal e *rem-evt-remove*)
               (equal e *rem-evt-opportunity-lapses*)))
  :hints (("Goal" :use ((:instance lsm-step-event-guard
                                   (targets (list *rem-removed*))
                                   (edges *rem-edges*)))))
  :rule-classes :forward-chaining)

;;; =========================================================================
;;; 4. REMOVED IS ABSORBING: § 8(k) PROVIDES NO REINSTATEMENT
;;; =========================================================================

(defthm removed-is-absorbing
  (equal (rem-run-trace *rem-removed* events) *rem-removed*))

;; Routes back onto the rolls: the overlay (contested → on-rolls) and, in the
;; S. 1383 vehicle, providing documentary proof after notice (noticed → on-rolls).
;; The § 8(k) text alone provides neither.
(defthm reinstatement-requires-contest-or-proof-path
  (equal (lsm-sources-into (list *rem-on-rolls*) *rem-edges*)
         (list *rem-contested* *rem-noticed*))
  :rule-classes nil)

;;; =========================================================================
;;; 5. THE PROCESS NEVER LEAVES ITS STATE SPACE
;;; =========================================================================

(defthm rem-run-trace-stays-in-state-space
  (implies (rem-statep s)
           (rem-statep (rem-run-trace s events)))
  :hints (("Goal" :use ((:instance lsm-run-closed
                                   (set *rem-states*) (edges *rem-edges*))))))

;;; =========================================================================
;;; 6. THE SAVE AMERICA ACT'S SYSTEMATIC PATH REQUIRES NOTICE  (v6.6)
;;;
;;; S. 1383 § 8(j)(4)(B): the State submits its list to DHS for SAVE-system
;;; comparison and removes identified non-citizens "after notice is given
;;; ... and ... the opportunity to provide documentary proof".  So on THAT
;;; path removal cannot occur without the notify event — while the § 8(k)
;;; "at any time upon receipt" path (sections 2-3 above) is unchanged.
;;; The two results together are the honest statement of the new vehicle.
;;; =========================================================================

;; {save-identified} is closed under every edge except the notify edge.
(defthm save-identified-closed-except-notice
  (lsm-closedp-except (list *rem-save-identified*) (list *rem-evt-notify*) *rem-edges*)
  :rule-classes nil)

(defthm save-match-removal-requires-notice
  (implies (equal (rem-run-trace *rem-save-identified* events) *rem-removed*)
           (some-in-catsp events (list *rem-evt-notify*)))
  :hints (("Goal" :use ((:instance lsm-run-closed-except
                                   (set (list *rem-save-identified*))
                                   (evs (list *rem-evt-notify*))
                                   (s *rem-save-identified*)
                                   (edges *rem-edges*))))))

;; After notice, the registrant can return to the rolls by providing proof.
(defthm noticed-registrant-who-provides-proof-stays-on-rolls
  (equal (rem-run-trace *rem-on-rolls*
                        (list *rem-evt-save-match* *rem-evt-notify* *rem-evt-provide-proof*))
         *rem-on-rolls*))

;; ... and is removed if the opportunity lapses.
(defthm noticed-registrant-who-lapses-is-removed
  (equal (rem-run-trace *rem-on-rolls*
                        (list *rem-evt-save-match* *rem-evt-notify* *rem-evt-opportunity-lapses*))
         *rem-removed*))

;; The § 8(k) path is still there, and still has no notice (section 2).
(defthm section-8k-path-unchanged-by-save-america-act
  (and (equal (rem-run-trace *rem-on-rolls* *rem-statutory-path*) *rem-removed*)
       (none-in-catsp *rem-statutory-path* (list *rem-evt-notify*)))
  :rule-classes nil)
