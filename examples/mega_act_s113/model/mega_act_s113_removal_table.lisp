(in-package "ACL2")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mega_act_s113_removal_table.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/mega_act_s113_removal_table.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : b4b33ad882e588e87528043c71cc702109322e30f4bb86e624c0c065bf430582
;; H.R. 7300 § 113 — registrant record lifecycle
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; PROCESS mrem   [H.R. 7300 § 113(a)-(c)]
;;; A registrant's record under § 113. The noncitizen ground (a)(1)(E) is fed by DHS SAVE data and is exempt from the pre-election freeze (b)(1); residence removals (a)(1)(D) go through the return-card procedure (c)(2)-(3). Notice for SAVE-based removals is NOT in the text; overlay edges make that statable.
;;; =========================================================================
(defconst *mrem-on-rolls* 'on-rolls)  ; registrant on the official list
(defconst *mrem-save-flagged* 'save-flagged)  ; SAVE data indicates noncitizen status (a)(1)(E)
(defconst *mrem-residence-flagged* 'residence-flagged)  ; change-of-address information indicates a move (a)(2)
(defconst *mrem-card-sent* 'card-sent)  ; return card sent by nonforwardable mail (c)(2)
(defconst *mrem-noticed* 'noticed)  ; registrant notified of pending noncitizen removal (overlay — not in text)
(defconst *mrem-removed* 'removed)  ; terminal: removed from the official list

(defconst *mrem-evt-save* 'save-noncitizen-match)  ; DHS SAVE information demonstrates noncitizen status
(defconst *mrem-evt-remove* 'remove)  ; State removes the registrant
(defconst *mrem-evt-residence* 'residence-change-indicated)  ; postal change-of-address information
(defconst *mrem-evt-card* 'send-return-card)  ; registrar sends the return card
(defconst *mrem-evt-returned* 'card-returned)  ; registrant returns the card confirming residence
(defconst *mrem-evt-not-returned* 'card-not-returned)  ; card not returned or notice undeliverable
(defconst *mrem-evt-notify* 'notify-registrant)  ; notice of pending removal (overlay)
(defconst *mrem-evt-proof* 'provide-proof)  ; registrant provides proof of citizenship (overlay)

(defconst *mrem-states*
  (list *mrem-on-rolls* *mrem-save-flagged* *mrem-residence-flagged* *mrem-card-sent* *mrem-noticed* *mrem-removed*))
(defconst *mrem-events*
  (list *mrem-evt-save* *mrem-evt-remove* *mrem-evt-residence* *mrem-evt-card* *mrem-evt-returned* *mrem-evt-not-returned* *mrem-evt-notify* *mrem-evt-proof*))

;; Edge table: (from-state event to-state).  Unlisted pairs are no-ops.
(defconst *mrem-edges*
  (list
   ;; [] "information with respect to citizenship status supplied by the Department of Homeland Security through the Systematic Alien Verification for Entitlements (``SAVE'') system that demonstrates a registrant is not a citizen of the United States"
   (list *mrem-on-rolls* *mrem-evt-save* *mrem-save-flagged*)  ; TEXT_FACT § 113(a)(1)(E)
   ;; [] "the removal of names from official lists of voters at any time on a basis described in paragraph (1)(A), (1)(B), or (1)(E)"
   (list *mrem-save-flagged* *mrem-evt-remove* *mrem-removed*)  ; TEXT_FACT § 113(a)(1)(E), (b)(1)
   ;; [] "change-of-address information supplied by the Postal Service through its licensees is used to identify registrants whose addresses may have changed"
   (list *mrem-on-rolls* *mrem-evt-residence* *mrem-residence-flagged*)  ; TEXT_FACT § 113(a)(2)
   ;; [] "a postage prepaid and pre-addressed return card, sent by nonforwardable mail, on which the registrant may state his or her current address"
   (list *mrem-residence-flagged* *mrem-evt-card* *mrem-card-sent*)  ; TEXT_FACT § 113(c)(2)
   ;; [] "the registrant should return the card not later than the time provided for mail registration"
   (list *mrem-card-sent* *mrem-evt-returned* *mrem-on-rolls*)  ; TEXT_FACT § 113(c)(2)(A)
   ;; [] "the registrant shall be removed from the official list of eligible voters as described in paragraph (1)"
   (list *mrem-card-sent* *mrem-evt-not-returned* *mrem-removed*)  ; TEXT_FACT § 113(c)(3)(A)
   (list *mrem-save-flagged* *mrem-evt-notify* *mrem-noticed*)  ; DUE_PROCESS_OVERLAY not in statute
   (list *mrem-noticed* *mrem-evt-proof* *mrem-on-rolls*)  ; DUE_PROCESS_OVERLAY not in statute
   (list *mrem-noticed* *mrem-evt-remove* *mrem-removed*)  ; DUE_PROCESS_OVERLAY not in statute
   ))
