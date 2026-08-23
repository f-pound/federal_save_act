(in-package "ACL2")
(include-book "mega_act_s113_hinge_common")
;; INTERPRETIVE_ASSUMPTION (Reading B): no determination without notice.
(defaxiom semantic-b-determination-requires-notice
  (implies (not (adequate-notice-before-removalp p))
           (not (determined-ineligible-noncitizenp p))))

(defthm hinge-process-no-determination-for-registrant-r
  (not (determined-ineligible-noncitizenp 'registrant-r))
  :rule-classes nil)
