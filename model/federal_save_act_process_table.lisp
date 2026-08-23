(in-package "ACL2")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_process_table.lisp  —  GENERATED FILE, DO NOT EDIT
;; Source IR : data/parsed/federal_save_act_process_table.json
;; Generator : tools/clauses_to_acl2.py
;; IR sha256 : 0396497bd2420a0be1736ed4d1d7451a3888387a2393890a113afd194419d287
;; SAVE Act registration lifecycle — labeled state machine table
;;
;; Every defconst below is a statutory enumeration; every defun is a
;; statutory rule compiled from a boolean IR.  Provenance is carried in
;; the comments so reviewers can check each symbol against the text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; PROCESS reg   [SAVE Act § 2(b)-(f); NVRA §§ 4, 6(e), 8(j)]
;;; Lifecycle of one voter registration application under the SAVE Act. TEXT_FACT edges are named in the statute; MODEL_STRUCTURE edges are neutral bookkeeping (submission, registration/denial as terminal acts) needed to make the statutory steps a process.
;;; =========================================================================
(defconst *state-unsubmitted* 'unsubmitted)  ; no application yet
(defconst *state-submitted* 'submitted)  ; application received (NVRA § 6(e)(2): notice of proof requirement transmitted)
(defconst *state-doc-presented* 'doc-presented)  ; documentary proof presented with / after the application (§ 4(b), § 6(e)(1))
(defconst *state-doc-accepted* 'doc-accepted)  ; official accepts documentary proof
(defconst *state-doc-rejected* 'doc-rejected)  ; official rejects documentary proof (discrepancy, § 8(j)(2)(B))
(defconst *state-alt-initiated* 'alt-initiated)  ; attestation under penalty of perjury + other evidence submitted (§ 8(j)(2)(A)(i))
(defconst *state-alt-approved* 'alt-approved)  ; official determines citizenship sufficiently established; affidavit (§ 8(j)(2)(A)(ii))
(defconst *state-alt-denied* 'alt-denied)  ; official determines citizenship not sufficiently established
(defconst *state-registered* 'registered)  ; terminal: registered for federal elections
(defconst *state-denied* 'denied)  ; terminal: application not accepted / not registered (§ 4(b), § 8(j)(1))

(defconst *evt-submit* 'submit-application)  ; applicant submits the application
(defconst *evt-present-docs* 'present-documents)  ; applicant presents documentary proof
(defconst *evt-accept-docs* 'accept-documents)  ; official accepts the documents
(defconst *evt-reject-docs* 'reject-documents)  ; official rejects the documents
(defconst *evt-initiate-alt* 'initiate-alternative-process)  ; applicant signs attestation and submits other evidence
(defconst *evt-approve-alt* 'approve-alternative)  ; official determines citizenship sufficiently established
(defconst *evt-deny-alt* 'deny-alternative)  ; official determines citizenship not established
(defconst *evt-register* 'register)  ; State registers the applicant
(defconst *evt-deny* 'deny-registration)  ; State declines to accept / register

(defconst *reg-states*
  (list *state-unsubmitted* *state-submitted* *state-doc-presented* *state-doc-accepted* *state-doc-rejected* *state-alt-initiated* *state-alt-approved* *state-alt-denied* *state-registered* *state-denied*))
(defconst *reg-events*
  (list *evt-submit* *evt-present-docs* *evt-accept-docs* *evt-reject-docs* *evt-initiate-alt* *evt-approve-alt* *evt-deny-alt* *evt-register* *evt-deny*))

;; Edge table: (from-state event to-state).  Unlisted pairs are no-ops.
(defconst *reg-edges*
  (list
   (list *state-unsubmitted* *evt-submit* *state-submitted*)  ; MODEL_STRUCTURE NVRA § 6(a)
   (list *state-submitted* *evt-present-docs* *state-doc-presented*)  ; TEXT_FACT § 2(b) / NVRA § 4(b); § 2(d) / NVRA § 6(e)(1)
   (list *state-doc-presented* *evt-accept-docs* *state-doc-accepted*)  ; TEXT_FACT § 2(b) / NVRA § 4(b)
   (list *state-doc-presented* *evt-reject-docs* *state-doc-rejected*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(2)(B) (discrepancy)
   (list *state-doc-rejected* *evt-initiate-alt* *state-alt-initiated*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i)
   (list *state-submitted* *evt-initiate-alt* *state-alt-initiated*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i) ('cannot provide documentary proof')
   (list *state-alt-initiated* *evt-approve-alt* *state-alt-approved*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i)-(ii)
   (list *state-alt-initiated* *evt-deny-alt* *state-alt-denied*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(i) ('shall make a determination as to whether')
   (list *state-doc-accepted* *evt-register* *state-registered*)  ; MODEL_STRUCTURE NVRA § 8(a)(1)
   (list *state-alt-approved* *evt-register* *state-registered*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(2)(A)(iii)(I) ('register an applicant who cannot provide documentary proof')
   (list *state-doc-rejected* *evt-deny* *state-denied*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(1)
   (list *state-alt-denied* *evt-deny* *state-denied*)  ; TEXT_FACT § 2(f) / NVRA § 8(j)(1)
   (list *state-submitted* *evt-deny* *state-denied*)  ; TEXT_FACT § 2(b) / NVRA § 4(b) ('shall not accept and process ... unless')
   ))
