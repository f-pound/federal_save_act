(in-package "ACL2")
(include-book "mega_act_s113_hinge_common")
;; INTERPRETIVE_ASSUMPTION (Reading A): SAVE data demonstrating noncitizen
;; status IS the determination of ineligibility.
(defaxiom semantic-a-save-data-is-determination
  (implies (save-indicates-noncitizenp p)
           (determined-ineligible-noncitizenp p)))

(defthm hinge-data-statute-removes-on-save-data
  (implies (and (personp p) (registered-voterp p) (save-indicates-noncitizenp p))
           (statute-removes-registrantp 'mega-act p))
  :rule-classes nil)
