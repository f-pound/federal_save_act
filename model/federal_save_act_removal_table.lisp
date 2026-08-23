(in-package "ACL2")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_removal_table.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_removal_table.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : d826199ec8830b8516bf26cf26fce5a6c9a1d46ed8fdfdc45061a2e0eb546ffd
;; NVRA § 8(k) (as added by SAVE Act § 2(f)) — removal of noncitizens from the rolls
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; PROCESS rem   [SAVE Act § 2(f) / NVRA § 8(k); NVRA § 8(a)(3)(D)]
;;; Lifecycle of one registrant's record. § 8(k) (both texts) names two steps: receipt of documentation or verified information of noncitizenship, and removal 'at any time' upon receipt — no notice. The SAVE America Act vehicle (S. 1383 § 8(j)(4)(B)) adds a SYSTEMATIC path — DHS SAVE-system comparison of the State's list — on which removal comes only 'after notice is given ... and ... the opportunity to provide documentary proof'. DUE_PROCESS_OVERLAY edges are not in either text; they let theorems state what the texts do not require.
;;; =========================================================================
(defconst *rem-on-rolls* 'on-rolls)  ; registrant on the official list of eligible voters
(defconst *rem-info-received* 'info-received)  ; State has received documentation or verified information that the registrant is not a citizen (§ 8(k))
(defconst *rem-noticed* 'noticed)  ; registrant notified of pending removal (overlay — not in text)
(defconst *rem-contested* 'contested)  ; registrant has contested the information (overlay — not in text)
(defconst *rem-removed* 'removed)  ; terminal: removed from the official list (§ 8(k), § 8(a)(3)(D))
(defconst *rem-save-identified* 'save-identified)  ; identified as a non-citizen by the DHS SAVE-system comparison of the State's list (S. 1383 § 8(j)(4)(B))

(defconst *rem-evt-receive* 'receive-noncitizen-information)  ; State receives documentation or verified information of noncitizenship
(defconst *rem-evt-notify* 'notify-registrant)  ; State notifies the registrant (overlay)
(defconst *rem-evt-contest* 'contest)  ; registrant contests (overlay)
(defconst *rem-evt-confirm* 'confirm-citizenship)  ; registrant's citizenship confirmed (overlay)
(defconst *rem-evt-remove* 'remove)  ; State removes the registrant
(defconst *rem-evt-save-match* 'save-system-match)  ; State submits its voter list to DHS; SAVE comparison flags the registrant
(defconst *rem-evt-provide-proof* 'provide-documentary-proof)  ; registrant provides documentary proof of citizenship after notice
(defconst *rem-evt-opportunity-lapses* 'opportunity-lapses)  ; registrant does not provide proof after notice

(defconst *rem-states*
  (list *rem-on-rolls* *rem-info-received* *rem-noticed* *rem-contested* *rem-removed* *rem-save-identified*))
(defconst *rem-events*
  (list *rem-evt-receive* *rem-evt-notify* *rem-evt-contest* *rem-evt-confirm* *rem-evt-remove* *rem-evt-save-match* *rem-evt-provide-proof* *rem-evt-opportunity-lapses*))

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
   ;; [s1383-eah] "Each State shall submit the complete, official list of individuals registered as eligible voters for Federal office in the State to the Department of Homeland Security for comparison through the Systematic Alien Verification for Entitlements ('SAVE') system for the purposes of identifying individuals who are not citizens of the United States"
   (list *rem-on-rolls* *rem-evt-save-match* *rem-save-identified*)  ; TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B)
   ;; [s1383-eah] "taking the necessary steps to remove such individuals who are not citizens from the official list, after notice is given to such individuals and such individuals are given the opportunity to provide documentary proof of United States citizenship"
   (list *rem-save-identified* *rem-evt-notify* *rem-noticed*)  ; TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B)
   (list *rem-noticed* *rem-evt-provide-proof* *rem-on-rolls*)  ; TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B) ('opportunity to provide documentary proof')
   (list *rem-noticed* *rem-evt-opportunity-lapses* *rem-removed*)  ; TEXT_FACT (S. 1383 only) S. 1383 § 2(f) / NVRA § 8(j)(4)(B) ('taking the necessary steps to remove')
   ))
