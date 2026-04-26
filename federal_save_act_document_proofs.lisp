(in-package "ACL2")

(include-book "federal_save_act_process")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_document_proofs.lisp  —  v5.2
;;
;; Document-list reasoning for the SAVE Act documentary proof requirement.
;;
;; The SAVE Act requires "documentary proof of United States citizenship"
;; from a statutory list of qualifying document types.  This book proves
;; properties of document COLLECTIONS, not just individual documents.
;;
;; These theorems demonstrate ACL2 reasoning over recursive list structures:
;;   - Empty collections cannot satisfy the requirement
;;   - A single qualifying document suffices
;;   - Collections of nonqualifying documents cannot satisfy the requirement
;;   - Filtering operations preserve or destroy qualifying status predictably
;;
;; Legal relevance: These properties model how a registration official
;; evaluates a bundle of submitted documents.  The all-nonqualifying
;; theorem is particularly important because it proves that a citizen
;; who possesses only nonqualifying documents CANNOT satisfy the statutory
;; requirement — the denial is structurally mandated, not discretionary.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. HELPER FUNCTIONS
;;; =========================================================================

;; Are ALL documents in the list nonqualifying?
(defun all-nonqualifying-documentsp (docs)
  (if (endp docs)
      t
    (and (not (qualifying-document-typep (car docs)))
         (all-nonqualifying-documentsp (cdr docs)))))

;; Filter: keep only qualifying documents from a list
(defun filter-qualifying-documents (docs)
  (if (endp docs)
      nil
    (if (qualifying-document-typep (car docs))
        (cons (car docs) (filter-qualifying-documents (cdr docs)))
      (filter-qualifying-documents (cdr docs)))))

;;; =========================================================================
;;; 2. EMPTY COLLECTION THEOREM
;;;
;;; An empty document collection cannot satisfy the documentary proof
;;; requirement.  This is the base case for document-list reasoning.
;;; =========================================================================

(defthm empty-document-list-has-no-qualifying-document
  (not (has-qualifying-docs-from-listp nil)))

;;; =========================================================================
;;; 3. SINGLETON SUFFICIENCY
;;;
;;; A single qualifying document is sufficient to satisfy the
;;; documentary proof requirement.
;;; =========================================================================

(defthm singleton-qualifying-list-has-proof
  (implies (qualifying-document-typep d)
           (has-qualifying-docs-from-listp (list d))))

;;; =========================================================================
;;; 4. ALL-NONQUALIFYING IMPLIES NO PROOF
;;;
;;; If every document in a collection fails the qualifying-document-typep
;;; test, then the collection cannot satisfy the documentary proof
;;; requirement.
;;;
;;; This is the key "structural denial" theorem: a citizen who possesses
;;; only nonqualifying documents is STRUCTURALLY unable to satisfy
;;; the SAVE Act requirement through the documentary proof path.
;;;
;;; Proof by induction on the document list.
;;; =========================================================================

;; Helper: all-nonqualifying docs are not qualifying-document-listp
;; (since qualifying-document-listp requires every element to be qualifying)
(defthm all-nonqualifying-implies-not-qualifying-list
  (implies (and (consp docs)
                (all-nonqualifying-documentsp docs))
           (not (qualifying-document-listp docs))))

;; Main: all-nonqualifying → no documentary proof from list
(defthm all-nonqualifying-implies-no-documentary-proof
  (implies (all-nonqualifying-documentsp docs)
           (not (has-qualifying-docs-from-listp docs))))

;;; =========================================================================
;;; 5. FILTER PRESERVES QUALIFYING STATUS
;;;
;;; Filtering a document list to keep only qualifying documents
;;; preserves the qualifying-document-listp property.
;;;
;;; Proof by induction on the document list.
;;; =========================================================================

(defthm filter-qualifying-is-qualifying-list
  (qualifying-document-listp (filter-qualifying-documents docs)))

;;; =========================================================================
;;; 6. FILTER PRODUCES PROOF WHEN SOURCE HAS QUALIFYING MEMBER
;;;
;;; If the original list contains at least one qualifying document,
;;; filtering produces a nonempty qualifying list — which has proof.
;;; =========================================================================

;; Helper: if a qualifying doc is a member, filter is nonempty
(defthm member-qualifying-implies-filter-nonempty
  (implies (and (member-equal d docs)
                (qualifying-document-typep d))
           (consp (filter-qualifying-documents docs))))

;; Main: filter of a list with a qualifying member has proof
(defthm filter-qualifying-has-proof-when-member-qualifies
  (implies (and (member-equal d docs)
                (qualifying-document-typep d))
           (has-qualifying-docs-from-listp
            (filter-qualifying-documents docs))))

;;; =========================================================================
;;; 7. ALL-NONQUALIFYING IS CLOSED UNDER APPEND
;;;
;;; Combining two collections of nonqualifying documents still
;;; produces a collection of nonqualifying documents.
;;;
;;; Legal relevance: Combining two inadequate document bundles
;;; cannot create a qualifying bundle.
;;; =========================================================================

(defthm all-nonqualifying-append
  (equal (all-nonqualifying-documentsp (append a b))
         (and (all-nonqualifying-documentsp a)
              (all-nonqualifying-documentsp b))))

;;; =========================================================================
;;; 8. CONTRAPOSITIVE: QUALIFYING LIST IMPLIES NOT ALL-NONQUALIFYING
;;;
;;; If a nonempty list satisfies qualifying-document-listp, then
;;; not all documents are nonqualifying (at least one must qualify).
;;; =========================================================================

(defthm qualifying-list-implies-not-all-nonqualifying
  (implies (and (consp docs)
                (qualifying-document-listp docs))
           (not (all-nonqualifying-documentsp docs))))
