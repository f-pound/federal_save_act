(in-package "ACL2")
(include-book "mega_act_s113_scenario")
;; Hinge: § 113(a)(1) removes registrants "who are determined to be ineligible
;; voters by reason of ... status as a noncitizen ... supplied by ... SAVE".
;; Reading A (data): the SAVE information itself is the determination.
;; Reading B (process): a determination requires notice to the registrant.
;; The two hinge books cannot be loaded together.
(defthm hinge-common-placeholder (equal 'mega-act 'mega-act) :rule-classes nil)
