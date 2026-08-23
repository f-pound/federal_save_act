(in-package "ACL2")
(include-book "mega_act_s113_hinge_data")

;; Challenger: under Reading A registrant-r is removed on erroneous SAVE data
;; with no notice or hearing — a due-process deprivation of the vote.
(encapsulate
  ((challenger-right-to-vote-establishedp (p) t)
   (challenger-removal-due-process-violationp (law p) t))
  (local (defun challenger-right-to-vote-establishedp (p) (declare (ignore p)) t))
  (local (defun challenger-removal-due-process-violationp (law p) (declare (ignore law p)) t))
  ;; DOCTRINAL_RULE: the right to vote is fundamental (Harper; Reynolds)
  (defthm challenger-fundamental-right-rule
    (implies (qualified-federal-voterp p) (challenger-right-to-vote-establishedp p)))
  ;; INTERPRETATION_CHALLENGER (Mathews): removal of a qualified registrant
  ;; without notice or hearing violates due process
  (defthm challenger-removal-without-process-is-violation
    (implies (and (qualified-federal-voterp p) (registered-voterp p)
                  (statute-removes-registrantp 'mega-act p)
                  (not (adequate-notice-before-removalp p))
                  (not (opportunity-to-be-heardp p)))
             (challenger-removal-due-process-violationp 'mega-act p))))

(defaxiom challenger-bridge-right-to-vote
  (implies (challenger-right-to-vote-establishedp p)
           (protected-right-to-votep 'amend-v-due-process p)))

(defaxiom challenger-bridge-removal-invalid
  (implies (challenger-removal-due-process-violationp 'mega-act p)
           (not (valid-regulationp 'mega-act p))))

(defthm challenger-removal-conflict-general
  (implies (and (personp p) (citizen-of-usp p) (eligible-voterp p) (registered-voterp p)
                (save-indicates-noncitizenp p)
                (not (adequate-notice-before-removalp p))
                (not (opportunity-to-be-heardp p)))
           (constitutional-removal-conflict-conditionp 'mega-act 'amend-v-due-process p))
  :hints (("Goal" :in-theory (enable constitutional-removal-conflict-conditionp
                               removal-transactionp qualified-federal-voterp)))
  :rule-classes nil)

(defthm challenger-model-finds-removal-conflict
  (constitutional-removal-conflict-conditionp 'mega-act 'amend-v-due-process 'registrant-r)
  :hints (("Goal" :use ((:instance challenger-removal-conflict-general (p 'registrant-r)))))
  :rule-classes nil)
