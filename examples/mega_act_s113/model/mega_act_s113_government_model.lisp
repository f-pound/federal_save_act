(in-package "ACL2")
(include-book "mega_act_s113_hinge_process")

;; Government: (1) under Reading B the statute does not remove registrant-r
;; without notice at all; (2) in any event SAVE-based list maintenance is a
;; valid, evenhanded regulation (Husted).
(encapsulate
  ((government-removal-defense-establishedp (law p) t))
  (local (defun government-removal-defense-establishedp (law p) (declare (ignore law p)) t))
  ;; INTERPRETATION_GOVERNMENT (Husted): reliable SAVE data + important
  ;; interest + evenhanded procedure establish the defense
  (defthm government-removal-defense-rule
    (implies (and (save-indicates-noncitizenp p)
                  (important-government-interestp law)
                  (removal-procedure-evenhandedp law)
                  (save-data-reliablep law))
             (government-removal-defense-establishedp law p))))

(defaxiom government-bridge-removal-validates
  (implies (government-removal-defense-establishedp law p)
           (valid-regulationp law p)))
(defaxiom government-important-interest (important-government-interestp 'mega-act))
(defaxiom government-removal-procedure-evenhanded (removal-procedure-evenhandedp 'mega-act))
(defaxiom government-save-data-reliable (save-data-reliablep 'mega-act))
(defaxiom government-assume-right-to-vote-arguendo
  (protected-right-to-votep 'amend-v-due-process 'registrant-r))

(defthm government-no-removal-conflict-general
  (implies (and (save-indicates-noncitizenp p) (important-government-interestp law)
                (removal-procedure-evenhandedp law) (save-data-reliablep law))
           (not (constitutional-removal-conflict-conditionp law cs p)))
  :hints (("Goal" :in-theory (enable constitutional-removal-conflict-conditionp)))
  :rule-classes nil)

(defthm government-model-no-removal-conflict
  (not (constitutional-removal-conflict-conditionp 'mega-act 'amend-v-due-process 'registrant-r))
  :rule-classes nil)

;; And independently of validity: under Reading B there is no determination.
(defthm government-no-determination-without-notice
  (not (determined-ineligible-noncitizenp 'registrant-r))
  :rule-classes nil)
