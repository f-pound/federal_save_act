(in-package "ACL2")

(include-book "federal_save_act_facts")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_scenario.lisp  —  v6.0
;; The shared stress-test scenario, stated ONCE.
;;
;; v5 stipulated the same six ground facts about citizen-a twice — once in
;; the challenger model and once in the government model — and proved the
;; same two lemmas about them twice.  Both parties CONCEDE these facts;
;; they are the common ground on which the models diverge.  Factoring them
;; here makes that explicit and shrinks the trusted base from 33 to 27
;; defaxioms without changing any conclusion.
;;
;;   citizen-a:              an elderly U.S. citizen born at home in a rural
;;                           area who lacks any § 3(b) document
;;   registration-attempt-a: a mail voter registration application for a
;;                           federal election
;;
;; Every axiom here is a SCENARIO_FACT (self-evidently consistent
;; stipulation about fresh constants).  Party-specific facts — whether the
;; alternative process approves or denies, whether the burden is material,
;; whether the right is conceded — stay in the party books.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; SCENARIO_FACT: citizen-a is a person
(defaxiom scenario-person
  (personp 'citizen-a))

;; SCENARIO_FACT: citizen-a is a U.S. citizen
(defaxiom scenario-citizen
  (citizen-of-usp 'citizen-a))

;; SCENARIO_FACT: citizen-a is eligible to vote
(defaxiom scenario-eligible
  (eligible-voterp 'citizen-a))

;; SCENARIO_FACT: registration-attempt-a is a voter registration application
(defaxiom scenario-application
  (voter-registration-applicationp 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a attempts to register via registration-attempt-a
(defaxiom scenario-attempts-to-register
  (attempts-to-registerp 'citizen-a 'registration-attempt-a))

;; SCENARIO_FACT: citizen-a does NOT possess documentary proof
(defaxiom scenario-no-documentary-proof
  (not (has-documentary-proofp 'citizen-a)))

;;; =========================================================================
;;; Shared derived lemmas (previously challenger-lemma-* / government-*)
;;; =========================================================================

;; citizen-a is a qualified federal voter
(defthm scenario-qualified-voter
  (qualified-federal-voterp 'citizen-a))

;; citizen-a's attempt is a registration transaction
(defthm scenario-registration-transaction
  (registration-transactionp 'citizen-a 'registration-attempt-a))

;; Contrapositive of the text bridge rule: lacking documentary proof,
;; citizen-a possesses no qualifying document at all.
(defthm scenario-lacks-all-qualifying-documents
  (not (has-any-qualifying-documentp 'citizen-a))
  :hints (("Goal" :use ((:instance text-documentary-proof-from-qualifying-documents
                                   (p 'citizen-a))))))

;;; =========================================================================
;;; v6.1 — Second scenario: citizen-b, an ERRONEOUS § 8(k) REMOVAL
;;;
;;;   citizen-b: a registered U.S. citizen whose record is matched, by a
;;;   database check of the kind § 8(j)(4) authorizes, to "verified
;;;   information" that they are not a citizen.  The information is wrong
;;;   (citizen-b IS a citizen), and — consistent with the statutory path in
;;;   federal_save_act_removal_invariants.lisp — no notice or hearing
;;;   precedes removal.
;;;
;;; Both parties concede these facts; they diverge on whether removal on
;;; verified information without notice is a valid regulation.
;;; =========================================================================

(defaxiom scenario-b-person
  (personp 'citizen-b))

(defaxiom scenario-b-citizen
  (citizen-of-usp 'citizen-b))

(defaxiom scenario-b-eligible
  (eligible-voterp 'citizen-b))

(defaxiom scenario-b-registered
  (registered-voterp 'citizen-b))

;; The State holds "verified information" that citizen-b is a noncitizen.
;; (Stipulated; it is erroneous given scenario-b-citizen.)
(defaxiom scenario-b-verified-noncitizen-information
  (verified-noncitizen-informationp 'citizen-b))

;; Consistent with the statutory path: no notice, no hearing.
(defaxiom scenario-b-no-notice
  (not (adequate-notice-before-removalp 'citizen-b)))

(defaxiom scenario-b-no-hearing
  (not (opportunity-to-be-heardp 'citizen-b)))

;; Derived: citizen-b is a qualified voter in a removal transaction, and the
;; statute (text rule) removes citizen-b.
(defthm scenario-b-qualified-voter
  (qualified-federal-voterp 'citizen-b))

(defthm scenario-b-removal-transaction
  (removal-transactionp 'citizen-b))

(defthm scenario-b-statute-removes
  (statute-removes-registrantp 'federal-save-act 'citizen-b))
