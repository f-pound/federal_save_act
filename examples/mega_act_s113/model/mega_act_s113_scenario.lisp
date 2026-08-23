(in-package "ACL2")
(include-book "mega_act_s113_text_rules")

;; Shared scenario: registrant-r, a registered U.S. citizen whose record DHS
;; SAVE data (erroneously) shows as noncitizen; no notice, no hearing.
(defaxiom scenario-r-person (personp 'registrant-r))
(defaxiom scenario-r-citizen (citizen-of-usp 'registrant-r))
(defaxiom scenario-r-eligible (eligible-voterp 'registrant-r))
(defaxiom scenario-r-registered (registered-voterp 'registrant-r))
(defaxiom scenario-r-save-indicates-noncitizen (save-indicates-noncitizenp 'registrant-r))
(defaxiom scenario-r-no-notice (not (adequate-notice-before-removalp 'registrant-r)))
(defaxiom scenario-r-no-hearing (not (opportunity-to-be-heardp 'registrant-r)))
(defaxiom text-mega-act-is-law (lawp 'mega-act))

(defthm scenario-r-qualified-voter (qualified-federal-voterp 'registrant-r))
(defthm scenario-r-removal-transaction (removal-transactionp 'registrant-r))
