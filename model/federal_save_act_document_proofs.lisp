(in-package "ACL2")

(include-book "federal_save_act_process")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_document_proofs.lisp  —  v6.0
;;
;; Document-bundle reasoning for the SAVE Act documentary proof requirement,
;; as instances of lib/enum_list over the generated § 3(b) category tables.
;;
;; Legal relevance: these model how an official evaluates a bundle of
;; submitted documents.  The structural-denial theorem proves that a citizen
;; whose bundle contains nothing from the statutory lists CANNOT satisfy the
;; requirement — the denial is structurally mandated, not discretionary.
;; v6 adds the § 3(b)(5) structure: supporting documents are useless
;; without an anchor photo ID, and vice versa.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. HELPER FUNCTIONS  (wrappers over library predicates)
;;; =========================================================================

(defconst *all-recognized-document-types*
  (append *standalone-proof-types*
          *anchor-photo-id-types*
          *supporting-document-types*))

;; Are ALL documents in the bundle unrecognized by the statute?
(defun all-nonqualifying-documentsp (docs)
  (none-in-catsp docs *all-recognized-document-types*))

;; Keep only statute-recognized documents.
(defun filter-qualifying-documents (docs)
  (filter-in-cats docs *all-recognized-document-types*))

;;; =========================================================================
;;; 2. EMPTY COLLECTION / 3. SINGLETON SUFFICIENCY
;;; =========================================================================

(defthm empty-document-list-has-no-qualifying-document
  (not (has-qualifying-docs-from-listp nil)))

;; A single STANDALONE document suffices ...
(defthm singleton-standalone-list-has-proof
  (implies (member-equal d *standalone-proof-types*)
           (has-qualifying-docs-from-listp (list d))))

;; ... but a single SUPPORTING document never does, nor a lone anchor.
(defthm singleton-supporting-list-has-no-proof
  (implies (member-equal d *supporting-document-types*)
           (not (has-qualifying-docs-from-listp (list d)))))

(defthm singleton-anchor-list-has-no-proof
  (implies (member-equal d *anchor-photo-id-types*)
           (not (has-qualifying-docs-from-listp (list d)))))

;; The § 3(b)(5) pair always suffices.
(defthm anchor-and-supporting-pair-has-proof
  (implies (and (member-equal a *anchor-photo-id-types*)
                (member-equal d *supporting-document-types*))
           (has-qualifying-docs-from-listp (list a d))))

;;; =========================================================================
;;; 4. ALL-NONQUALIFYING IMPLIES NO PROOF  (structural denial)
;;; =========================================================================

;; A bundle with nothing recognized has nothing standalone, no anchor and
;; nothing supporting.  (Narrowing lemma from enum_list, by evaluation of
;; the subsetp-equal side conditions.)
(defthm all-nonqualifying-implies-no-standalone
  (implies (all-nonqualifying-documentsp docs)
           (none-in-catsp docs *standalone-proof-types*)))

(defthm all-nonqualifying-implies-no-anchor
  (implies (all-nonqualifying-documentsp docs)
           (none-in-catsp docs *anchor-photo-id-types*)))

(defthm all-nonqualifying-implies-no-supporting
  (implies (all-nonqualifying-documentsp docs)
           (none-in-catsp docs *supporting-document-types*)))

(defthm all-nonqualifying-implies-not-qualifying-list
  (implies (and (consp docs)
                (all-nonqualifying-documentsp docs))
           (not (qualifying-document-listp docs))))

;; Main structural-denial theorem.
(defthm all-nonqualifying-implies-no-documentary-proof
  (implies (all-nonqualifying-documentsp docs)
           (not (has-qualifying-docs-from-listp docs))))

;;; =========================================================================
;;; 5. FILTERING
;;; =========================================================================

(defthm filter-qualifying-is-qualifying-list
  (qualifying-document-listp (filter-qualifying-documents docs)))

;; Filtering out unrecognized documents does not change whether the
;; bundle is proof — only recognized documents matter.
(defthm filter-in-cats-preserves-some-in-catsp-of-subset
  (implies (subsetp-equal sub cats)
           (iff (some-in-catsp (filter-in-cats xs cats) sub)
                (some-in-catsp xs sub))))

(defthm filter-preserves-documentary-proof
  (iff (has-qualifying-docs-from-listp (filter-qualifying-documents docs))
       (has-qualifying-docs-from-listp docs)))

;;; =========================================================================
;;; 6. APPEND ALGEBRA
;;; Legal relevance: combining two inadequate bundles of UNRECOGNIZED
;;; documents cannot create proof; but combining a lone photo ID with a
;;; lone birth certificate CAN (the § 3(b)(5) pairing).
;;; =========================================================================

(defthm all-nonqualifying-append
  (equal (all-nonqualifying-documentsp (append a b))
         (and (all-nonqualifying-documentsp a)
              (all-nonqualifying-documentsp b))))

(defthm pairing-two-insufficient-bundles-can-create-proof
  (and (not (has-qualifying-docs-from-listp (list *doc-govt-photo*)))
       (not (has-qualifying-docs-from-listp (list *doc-birth-cert*)))
       (has-qualifying-docs-from-listp
        (append (list *doc-govt-photo*) (list *doc-birth-cert*))))
  :rule-classes nil)

;;; =========================================================================
;;; 7. CONTRAPOSITIVE: QUALIFYING LIST IMPLIES NOT ALL-NONQUALIFYING
;;; =========================================================================

(defthm qualifying-list-implies-not-all-nonqualifying
  (implies (and (consp docs)
                (qualifying-document-listp docs))
           (not (all-nonqualifying-documentsp docs))))

;;; =========================================================================
;;; 8. STATUTORY AMENDMENT LEMMA
;;; If Congress ADDS a standalone document type, every bundle that was
;;; proof remains proof.  (Instance of some-in-catsp-widen.)
;;; =========================================================================

(defun documentary-proof-bundlep-under (docs standalone anchors supporting)
  (or (some-in-catsp docs standalone)
      (and (some-in-catsp docs anchors)
           (some-in-catsp docs supporting))))

(defthm widening-standalone-list-preserves-proof
  (implies (and (has-qualifying-docs-from-listp docs)
                (subsetp-equal *standalone-proof-types* wider))
           (documentary-proof-bundlep-under
            docs wider *anchor-photo-id-types* *supporting-document-types*)))
