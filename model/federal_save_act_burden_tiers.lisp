(in-package "ACL2")

(include-book "federal_save_act_core")
(include-book "lib/enum_list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; federal_save_act_burden_tiers.lisp  —  v7.3
;; The Anderson-Burdick framework as an explicit DECISION TABLE.
;;
;; Burdick v. Takushi, 504 U.S. 428, 434 (1992):
;;   "when those rights are subjected to 'severe' restrictions, the
;;    regulation must be 'narrowly drawn to advance a state interest of
;;    compelling importance.' ... But when a state election law provision
;;    imposes only 'reasonable, nondiscriminatory restrictions' upon the
;;    First and Fourteenth Amendment rights of voters, 'the State's
;;    important regulatory interests are generally sufficient to justify'
;;    the restrictions."
;;
;; v5-v7.2 modeled burden as a boolean (burden-not-severep).  This book
;; replaces the boolean with an ORDINAL level and makes the standard of
;; review a function of it.  What remains a premise is the LEVEL a
;; fact-finder assigns and whether the interest meets the selected standard;
;; the tier structure itself — which standard applies at which level — is
;; now logic, not assumption.  NEUTRAL: no defaxiom.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst *burden-levels* '(none minimal moderate severe))

(defun burden-levelp (x) (if (member-equal x *burden-levels*) t nil))

;; Ordinal rank (position in *burden-levels*).
(defun burden-rank (x)
  (cond ((equal x 'none) 0) ((equal x 'minimal) 1) ((equal x 'moderate) 2) ((equal x 'severe) 3) (t 0)))

(defun burden-at-least (x y)
  (>= (burden-rank x) (burden-rank y)))

;; Standard of review as a function of the burden level (the decision table).
(defun standard-of-review (level)
  (if (equal level 'severe)
      'strict-scrutiny              ; "narrowly drawn to advance a state interest of compelling importance"
    'important-interest-review))    ; "important regulatory interests are generally sufficient"

;; A fact-finder assigns the level; the stubs of core are connected to it.
(defstub burden-level-of (law p) t)

(defun severe-burden-by-levelp (law p)
  (equal (burden-level-of law p) 'severe))

;;; ---- Structural theorems ----

(defthm standard-is-strict-iff-severe
  (iff (equal (standard-of-review level) 'strict-scrutiny)
       (equal level 'severe)))

(defthm non-severe-levels-get-important-interest-review
  (implies (and (burden-levelp level) (not (equal level 'severe)))
           (equal (standard-of-review level) 'important-interest-review)))

(defthm burden-rank-monotone
  (implies (and (burden-levelp x) (burden-levelp y) (burden-at-least x y))
           (>= (burden-rank x) (burden-rank y))))

;; Raising the assigned level never lowers the standard: the only way to reach
;; strict scrutiny is the top level, and every lower level shares one standard.
(defthm only-top-level-changes-the-standard
  (implies (and (burden-levelp x) (burden-levelp y)
                (not (equal x 'severe)) (not (equal y 'severe)))
           (equal (standard-of-review x) (standard-of-review y))))

;; Connection to the boolean vocabulary used by the party books.
(defthm severe-level-means-strict-scrutiny-applies
  (implies (severe-burden-by-levelp law p)
           (equal (standard-of-review (burden-level-of law p)) 'strict-scrutiny)))

(defthm non-severe-level-means-important-interest-review
  (implies (and (burden-levelp (burden-level-of law p))
                (not (severe-burden-by-levelp law p)))
           (equal (standard-of-review (burden-level-of law p)) 'important-interest-review)))
