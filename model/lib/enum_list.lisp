(in-package "ACL2")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; lib/enum_list.lisp  —  Enumerated-category list library  (v6.0)
;;
;; Statutes constantly define a term by ENUMERATION: "documentary proof
;; means any of the following: (1) ... (7)".  Reasoning about a bundle of
;; items against such a list is always the same three questions:
;;
;;   all-in-catsp   — is every item in the enumerated category list?
;;   some-in-catsp  — is at least one item in it?
;;   none-in-catsp  — is no item in it?
;;
;; plus the filter that keeps only enumerated items.  This book proves the
;; algebra of those predicates ONCE, for an arbitrary category list `cats`,
;; so that every statute-specific document book (SAVE Act § 3(b), a voter
;; ID list, an eligible-evidence list, ...) inherits the lemmas by
;; instantiating `cats` with a defconst.  No statute-specific vocabulary
;; appears here.
;;
;; Every theorem is a rewrite rule with no hints: the definitions are
;; written so that ACL2's default list induction discharges them.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; =========================================================================
;;; 1. Definitions
;;; =========================================================================

(defun all-in-catsp (xs cats)
  (if (endp xs)
      t
    (and (member-equal (car xs) cats)
         (all-in-catsp (cdr xs) cats))))

(defun some-in-catsp (xs cats)
  (if (endp xs)
      nil
    (or (member-equal (car xs) cats)
        (some-in-catsp (cdr xs) cats))))

(defun none-in-catsp (xs cats)
  (if (endp xs)
      t
    (and (not (member-equal (car xs) cats))
         (none-in-catsp (cdr xs) cats))))

(defun filter-in-cats (xs cats)
  (cond ((endp xs) nil)
        ((member-equal (car xs) cats)
         (cons (car xs) (filter-in-cats (cdr xs) cats)))
        (t (filter-in-cats (cdr xs) cats))))

;;; =========================================================================
;;; 2. Boolean normalisation — the predicates return t/nil, which lets
;;;    them be stated as `iff`/`equal` rewrite rules below.
;;; =========================================================================

(defthm booleanp-all-in-catsp
  (booleanp (all-in-catsp xs cats))
  :rule-classes :type-prescription)

(defthm booleanp-none-in-catsp
  (booleanp (none-in-catsp xs cats))
  :rule-classes :type-prescription)

;;; =========================================================================
;;; 3. Duality:  some  <=>  not none
;;; =========================================================================

(defthm some-in-catsp-iff-not-none-in-catsp
  (iff (some-in-catsp xs cats)
       (not (none-in-catsp xs cats))))

;;; =========================================================================
;;; 4. Append algebra
;;;
;;; Legal reading:  combining two bundles of evidence —
;;;   - all-qualifying is preserved only if both halves are;
;;;   - "nothing qualifies" is preserved only if nothing qualifies in either;
;;;   - "something qualifies" holds if either half has something.
;;; The third is the MONOTONICITY of enumerated proof: presenting more
;;; documents never destroys a qualifying bundle.
;;; =========================================================================

(defthm all-in-catsp-append
  (equal (all-in-catsp (append a b) cats)
         (and (all-in-catsp a cats)
              (all-in-catsp b cats))))

(defthm none-in-catsp-append
  (equal (none-in-catsp (append a b) cats)
         (and (none-in-catsp a cats)
              (none-in-catsp b cats))))

(defthm some-in-catsp-append
  (iff (some-in-catsp (append a b) cats)
       (or (some-in-catsp a cats)
           (some-in-catsp b cats))))

;;; =========================================================================
;;; 5. Membership and nonemptiness
;;; =========================================================================

;; A nonempty all-qualifying bundle has a qualifying member.
(defthm all-in-catsp-and-consp-implies-some-in-catsp
  (implies (and (consp xs)
                (all-in-catsp xs cats))
           (some-in-catsp xs cats)))

;; One qualifying member suffices.
(defthm member-in-cats-implies-some-in-catsp
  (implies (and (member-equal d xs)
                (member-equal d cats))
           (some-in-catsp xs cats)))

;; A singleton qualifies iff its element is enumerated.
(defthm some-in-catsp-singleton
  (iff (some-in-catsp (list d) cats)
       (member-equal d cats)))

;; If every member is enumerated then a member is enumerated.
(defthm all-in-catsp-member
  (implies (and (all-in-catsp xs cats)
                (member-equal d xs))
           (member-equal d cats)))

;; If nothing is enumerated then no member is enumerated.
(defthm none-in-catsp-member
  (implies (and (none-in-catsp xs cats)
                (member-equal d xs))
           (not (member-equal d cats))))

;;; =========================================================================
;;; 6. Removal
;;; =========================================================================

(defthm all-in-catsp-remove-equal
  (implies (all-in-catsp xs cats)
           (all-in-catsp (remove-equal d xs) cats)))

(defthm none-in-catsp-remove-equal
  (implies (none-in-catsp xs cats)
           (none-in-catsp (remove-equal d xs) cats)))

;;; =========================================================================
;;; 7. Filtering
;;; =========================================================================

;; The filtered bundle is all-qualifying.
(defthm all-in-catsp-filter-in-cats
  (all-in-catsp (filter-in-cats xs cats) cats))

;; The filtered bundle is nonempty exactly when something qualified.
(defthm consp-filter-in-cats
  (iff (consp (filter-in-cats xs cats))
       (some-in-catsp xs cats)))

;; Filtering an all-qualifying bundle is the identity.
(defthm filter-in-cats-of-all-in-catsp
  (implies (and (all-in-catsp xs cats)
                (true-listp xs))
           (equal (filter-in-cats xs cats) xs)))

;; Filtering a none-qualifying bundle is empty.
(defthm filter-in-cats-of-none-in-catsp
  (implies (none-in-catsp xs cats)
           (equal (filter-in-cats xs cats) nil)))

;;; =========================================================================
;;; 8. Widening the category list  (statutory amendment lemma)
;;;
;;; If an amendment ADDS categories (cats1 ⊆ cats2), then whatever
;;; qualified before still qualifies, and whatever fails the wider list
;;; also fails the narrower one.
;;; =========================================================================

(defthm member-equal-of-subsetp-equal
  (implies (and (subsetp-equal c1 c2)
                (member-equal a c1))
           (member-equal a c2)))

(defthm all-in-catsp-widen
  (implies (and (all-in-catsp xs c1)
                (subsetp-equal c1 c2))
           (all-in-catsp xs c2)))

(defthm some-in-catsp-widen
  (implies (and (some-in-catsp xs c1)
                (subsetp-equal c1 c2))
           (some-in-catsp xs c2)))

(defthm none-in-catsp-narrow
  (implies (and (none-in-catsp xs c2)
                (subsetp-equal c1 c2))
           (none-in-catsp xs c1)))
