(in-package "ACL2")
(include-book "mega_act_s113_removal_table")
(include-book "lib/lsm")
;; Neutral process invariants for § 113 (third statute-side client of lib/lsm).
(defun mrem-run-trace (s events) (lsm-run s events *mrem-edges*))
(defconst *mrem-save-path* (list *mrem-evt-save* *mrem-evt-remove*))
(defconst *mrem-text-edges*
  (list (list *mrem-on-rolls* *mrem-evt-save* *mrem-save-flagged*)
        (list *mrem-save-flagged* *mrem-evt-remove* *mrem-removed*)
        (list *mrem-on-rolls* *mrem-evt-residence* *mrem-residence-flagged*)
        (list *mrem-residence-flagged* *mrem-evt-card* *mrem-card-sent*)
        (list *mrem-card-sent* *mrem-evt-returned* *mrem-on-rolls*)
        (list *mrem-card-sent* *mrem-evt-not-returned* *mrem-removed*)))
;; SAVE-based removal: text path reaches removed with no notice event.
(defthm save-path-removes-without-notice
  (and (equal (lsm-run *mrem-on-rolls* *mrem-save-path* *mrem-text-edges*) *mrem-removed*)
       (none-in-catsp *mrem-save-path* (list *mrem-evt-notify* *mrem-evt-card*))))
;; Residence-based removal: removal from residence-flagged requires the card event
;; ({residence-flagged} is closed except via send-return-card).
(defthm residence-removal-requires-return-card
  (implies (equal (mrem-run-trace *mrem-residence-flagged* events) *mrem-removed*)
           (some-in-catsp events (list *mrem-evt-card*)))
  :hints (("Goal" :use ((:instance lsm-run-closed-except
                                   (set (list *mrem-residence-flagged*))
                                   (evs (list *mrem-evt-card*))
                                   (s *mrem-residence-flagged*) (edges *mrem-edges*))))))
(defthm removed-is-absorbing
  (equal (mrem-run-trace *mrem-removed* events) *mrem-removed*))
