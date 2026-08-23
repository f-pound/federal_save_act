(in-package "ACL2")

;; mega_act_s113_core.lisp — neutral vocabulary for H.R. 7300 § 113 (list maintenance).
;; No defaxiom.  Generated-book predicates: removal-ground-typep (removal_grounds).

(defstub personp (x) t)
(defstub lawp (x) t)
(defstub citizen-of-usp (x) t)
(defstub eligible-voterp (x) t)
(defstub registered-voterp (p) t)
(defstub save-indicates-noncitizenp (p) t)          ; DHS SAVE data says noncitizen
(defstub determined-ineligible-noncitizenp (p) t)   ; State has "determined" ineligibility on ground (E)
(defstub statute-removes-registrantp (law p) t)
(defstub removable-at-any-timep (p) t)
(defstub removed-for-residence-changep (p) t)
(defstub notice-card-sentp (p) t)
(defstub adequate-notice-before-removalp (p) t)
(defstub opportunity-to-be-heardp (p) t)
(defstub protected-right-to-votep (cs p) t)
(defstub valid-regulationp (law x) t)
(defstub important-government-interestp (law) t)
(defstub removal-procedure-evenhandedp (law) t)
(defstub save-data-reliablep (law) t)

(defun qualified-federal-voterp (p)
  (and (personp p) (citizen-of-usp p) (eligible-voterp p)))

(defun removal-transactionp (p)
  (and (personp p) (registered-voterp p)))

;; Conflict condition: a qualified, registered citizen with a protected right
;; is removed by the statute, and the removal rule is not a valid regulation
;; as applied to that registrant.
(defun constitutional-removal-conflict-conditionp (law cs p)
  (and (lawp law)
       (qualified-federal-voterp p)
       (protected-right-to-votep cs p)
       (removal-transactionp p)
       (statute-removes-registrantp law p)
       (not (valid-regulationp law p))))

(defthm core-valid-regulation-defeats-removal-conflict
  (implies (valid-regulationp law p)
           (not (constitutional-removal-conflict-conditionp law cs p))))

(defthm core-removal-conflict-pivots-on-valid-regulation
  (implies (and (lawp law) (qualified-federal-voterp p) (protected-right-to-votep cs p)
                (removal-transactionp p) (statute-removes-registrantp law p))
           (iff (constitutional-removal-conflict-conditionp law cs p)
                (not (valid-regulationp law p)))))
