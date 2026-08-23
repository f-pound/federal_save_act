(in-package "ACL2")

(include-book "federal_save_act_voting_table")
(include-book "federal_save_act_voting_id_rules")
(include-book "federal_save_act_document_rules")
(include-book "lib/lsm")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_voting_invariants.lisp  —  v6.5
;; SAVE America Act § 3 / HAVA § 303A: photo identification to vote.
;; Third client of lib/lsm; second client of lib/enum_list.
;;
;; Two kinds of neutral result:
;;   (1) PROCESS: over *vote-edges*, a ballot is counted only after a valid
;;       photo ID was presented or a provisional ballot was cured within 3
;;       days; an uncured provisional ballot is rejected; both terminal
;;       states are final.
;;   (2) ENUMERATION: § 3(b) (registration) and § 303A(c) (voting) are two
;;       DIFFERENT lists.  Satisfying one does not entail the other.  A
;;       passport satisfies both; a photo-ID-plus-birth-certificate bundle
;;       registers a citizen yet is not "valid photo identification" at the
;;       polls, because the registration-side photo ID need not carry an
;;       expiration date and is a different enumeration.
;;
;; NEUTRAL: no defaxiom; no claim about burden or validity.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun vote-next-state (s e) (lsm-step s e *vote-edges*))
(defun vote-run-trace (s events) (lsm-run s events *vote-edges*))
(defun vote-statep (s) (member-equal s *vote-states*))

(defthm vote-edges-well-formed
  (lsm-wf-tablep *vote-states* *vote-events* *vote-edges*)
  :rule-classes nil)

;;; =========================================================================
;;; 1. COUNTING REQUIRES A REGULAR BALLOT OR A CURED PROVISIONAL BALLOT
;;; =========================================================================

(defconst *vote-counting-sources*
  (lsm-sources-into (list *vote-counted*) *vote-edges*))

(defthm counting-sources-are-regular-or-cured
  (equal *vote-counting-sources* (list *vote-regular-cast* *vote-cured*))
  :rule-classes nil)

(defun vote-trace-passed-through-countable-statep (start events)
  (lsm-trace-visits *vote-counting-sources* start events *vote-edges*))

(defthm counted-implies-regular-or-cured
  (implies (and (not (equal start *vote-counted*))
                (equal (vote-run-trace start events) *vote-counted*))
           (vote-trace-passed-through-countable-statep start events))
  :hints (("Goal" :use ((:instance lsm-run-entry-guard
                                   (targets (list *vote-counted*))
                                   (s start) (edges *vote-edges*)))))
  :rule-classes nil)

;;; =========================================================================
;;; 2. WITHOUT IDENTIFICATION, COUNTING REQUIRES THE CURE EVENT
;;; {provisional-cast, rejected} is closed under every edge except the
;;; cure edge (lsm-closedp-except, evaluated on the table).
;;; =========================================================================

(defconst *vote-uncured-states* (list *vote-provisional-cast* *vote-rejected*))

(defthm uncured-states-closed-except-cure
  (lsm-closedp-except *vote-uncured-states* (list *vote-evt-cure*) *vote-edges*)
  :rule-classes nil)

(defthm provisional-counted-requires-cure
  (implies (equal (vote-run-trace *vote-provisional-cast* events) *vote-counted*)
           (some-in-catsp events (list *vote-evt-cure*)))
  :hints (("Goal" :use ((:instance lsm-run-closed-except
                                   (set *vote-uncured-states*)
                                   (evs (list *vote-evt-cure*))
                                   (s *vote-provisional-cast*)
                                   (edges *vote-edges*))))))

;; The lapse path: no ID, deadline passes, ballot rejected — by evaluation.
(defthm no-id-and-lapse-rejects
  (equal (vote-run-trace *vote-at-polls*
                         (list *vote-evt-no-id* *vote-evt-lapse*))
         *vote-rejected*))

;; The cure path: no ID, cure within 3 days, counted.
(defthm no-id-and-cure-counts
  (equal (vote-run-trace *vote-at-polls*
                         (list *vote-evt-no-id* *vote-evt-cure* *vote-evt-count*))
         *vote-counted*))

;;; =========================================================================
;;; 3. TERMINAL STATES ARE FINAL; THE PROCESS STAYS IN ITS STATE SPACE
;;; =========================================================================

(defthm counted-is-absorbing
  (equal (vote-run-trace *vote-counted* events) *vote-counted*))

(defthm rejected-is-absorbing
  (equal (vote-run-trace *vote-rejected* events) *vote-rejected*))

(defthm vote-run-trace-stays-in-state-space
  (implies (vote-statep s)
           (vote-statep (vote-run-trace s events)))
  :hints (("Goal" :use ((:instance lsm-run-closed
                                   (set *vote-states*) (edges *vote-edges*))))))

;;; =========================================================================
;;; 4. TWO ENUMERATIONS: REGISTRATION PROOF vs VOTING IDENTIFICATION
;;; =========================================================================

;; A passport satisfies both requirements.
(defthm passport-satisfies-both-requirements
  (and (documentary-proof-bundlep (list 'valid-us-passport))
       (valid-photo-identification-bundlep (list 'valid-us-passport))))

;; The § 3(b)(5) pairing registers a citizen but is NOT valid photo
;; identification under § 303A(c): the registration-side government photo
;; ID is a different enumeration and need not carry an expiration date.
(defthm registration-proof-does-not-entail-voting-id
  (and (documentary-proof-bundlep
        (list 'govt-photo-id 'certified-birth-certificate))
       (not (valid-photo-identification-bundlep
             (list 'govt-photo-id 'certified-birth-certificate)))))

;; Conversely, a state driver's licence with expiration is valid photo ID
;; at the polls but — unless it indicates citizenship — is not documentary
;; proof of citizenship at registration.
(defthm voting-id-does-not-entail-registration-proof
  (and (valid-photo-identification-bundlep
        (list 'state-drivers-license-with-expiration))
       (not (documentary-proof-bundlep
             (list 'state-drivers-license-with-expiration)))))

;; Monotonicity: more documents never lose valid photo identification.
(defthm append-preserves-valid-photo-id
  (implies (valid-photo-identification-bundlep a)
           (valid-photo-identification-bundlep (append a b))))

;; The religious-objection affidavit cures a provisional ballot but is not
;; itself photo identification.
(defthm affidavit-cures-but-is-not-photo-id
  (and (provisional-cure-bundlep (list 'religious-objection-affidavit))
       (not (valid-photo-identification-bundlep
             (list 'religious-objection-affidavit)))))

;; Any valid photo identification also cures.
(defthm photo-id-cures
  (implies (valid-photo-identification-bundlep docs)
           (provisional-cure-bundlep docs)))

;;; =========================================================================
;;; 5. MAIL BALLOTS  (§ 303A(a)(2)) — v7.3
;;; A ballot cast other than in person is accepted with a copy of a valid
;;; photo identification, or with the last four SSN digits TOGETHER WITH the
;;; inability affidavit.  Exceptions (UOCAVA voters; VAEHA disability voters)
;;; are in § 303A(a)(2)(B) and are not modeled as document bundles.
;;; =========================================================================

(defthm mail-ballot-accepted-with-photo-id-copy
  (mail-ballot-identification-bundlep (list 'valid-us-passport)))

(defthm mail-ballot-accepted-with-ssn-and-affidavit
  (mail-ballot-identification-bundlep
   (list 'ssn-last-four-digits 'affidavit-unable-to-obtain-copy)))

(defthm mail-ballot-rejected-with-ssn-alone
  (not (mail-ballot-identification-bundlep (list 'ssn-last-four-digits))))

(defthm mail-ballot-rejected-with-affidavit-alone
  (not (mail-ballot-identification-bundlep (list 'affidavit-unable-to-obtain-copy))))

;; In-person validity implies mail validity (a copy of the same ID suffices),
;; but not conversely: the SSN-plus-affidavit route exists only by mail.
(defthm in-person-id-implies-mail-acceptance
  (implies (valid-photo-identification-bundlep docs)
           (mail-ballot-identification-bundlep docs)))

(defthm mail-route-not-available-in-person
  (and (mail-ballot-identification-bundlep
        (list 'ssn-last-four-digits 'affidavit-unable-to-obtain-copy))
       (not (valid-photo-identification-bundlep
             (list 'ssn-last-four-digits 'affidavit-unable-to-obtain-copy)))))
