(in-package "ACL2")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_removal_table.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_removal_table.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : c2f9bcae0e0c7096c78c7a28fbca4673bffca26f2dd53160e2656486d897322d
;; NVRA § 8(k) (as added by SAVE Act § 2(f)) — removal of noncitizens from the rolls
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; PROCESS rem   [SAVE Act § 2(f) / NVRA § 8(k); NVRA § 8(a)(3)(D)]
;;; Lifecycle of one registrant's record under § 8(k). The statute names exactly two steps: receipt of documentation or verified information that the registrant is not a citizen, and removal 'at any time' upon that receipt. Notice and an opportunity to contest are NOT in the text; they are included as DUE_PROCESS_OVERLAY edges so that theorems can state, mechanically, that the statutory path to removal does not pass through them.
;;; =========================================================================
(defconst *rem-on-rolls* 'on-rolls)  ; registrant on the official list of eligible voters
(defconst *rem-info-received* 'info-received)  ; State has received documentation or verified information that the registrant is not a citizen (§ 8(k))
(defconst *rem-noticed* 'noticed)  ; registrant notified of pending removal (overlay — not in text)
(defconst *rem-contested* 'contested)  ; registrant has contested the information (overlay — not in text)
(defconst *rem-removed* 'removed)  ; terminal: removed from the official list (§ 8(k), § 8(a)(3)(D))

(defconst *rem-evt-receive* 'receive-noncitizen-information)  ; State receives documentation or verified information of noncitizenship
(defconst *rem-evt-notify* 'notify-registrant)  ; State notifies the registrant (overlay)
(defconst *rem-evt-contest* 'contest)  ; registrant contests (overlay)
(defconst *rem-evt-confirm* 'confirm-citizenship)  ; registrant's citizenship confirmed (overlay)
(defconst *rem-evt-remove* 'remove)  ; State removes the registrant

(defconst *rem-states*
  (list *rem-on-rolls* *rem-info-received* *rem-noticed* *rem-contested* *rem-removed*))
(defconst *rem-events*
  (list *rem-evt-receive* *rem-evt-notify* *rem-evt-contest* *rem-evt-confirm* *rem-evt-remove*))

;; Edge table: (from-state event to-state).  Unlisted pairs are no-ops.
(defconst *rem-edges*
  (list
   (list *rem-on-rolls* *rem-evt-receive* *rem-info-received*)  ; TEXT_FACT § 2(f) / NVRA § 8(k) ('upon receipt of documentation or verified information')
   (list *rem-info-received* *rem-evt-remove* *rem-removed*)  ; TEXT_FACT § 2(f) / NVRA § 8(k) ('shall remove ... at any time')
   (list *rem-info-received* *rem-evt-notify* *rem-noticed*)  ; DUE_PROCESS_OVERLAY not in statute
   (list *rem-noticed* *rem-evt-remove* *rem-removed*)  ; DUE_PROCESS_OVERLAY not in statute
   (list *rem-noticed* *rem-evt-contest* *rem-contested*)  ; DUE_PROCESS_OVERLAY not in statute
   (list *rem-contested* *rem-evt-confirm* *rem-on-rolls*)  ; DUE_PROCESS_OVERLAY not in statute
   (list *rem-contested* *rem-evt-remove* *rem-removed*)  ; DUE_PROCESS_OVERLAY not in statute
   ))
