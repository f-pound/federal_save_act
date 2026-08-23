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
