;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : 7002.scm
;; DESCRIPTION : LaTeX matrix import/export: matrix <-> pmatrix, bmatrix <-> bmatrix
;; COPYRIGHT   : (C) 2026
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(import (liii check))

(check-set-mode! 'report-failed)

(load "./TeXmacs/plugins/latex/progs/init-latex.scm")
(import-from (latex latex-format))

(define (matrix-body tag)
  `(,tag (table (row (cell "1") (cell "2")) (row (cell "3") (cell "4"))))
) ;define

(define (export-math tag)
  (serialize-latex
    (texmacs->latex (stree->tree `(math ,(matrix-body tag)))
      '(("texmacs->latex:encoding" . "utf-8"))
    ) ;texmacs->latex
  ) ;serialize-latex
) ;define

(define (import-math env)
  (tree->stree
    (latex->texmacs
      (parse-latex (string-append "$\\begin{" env "}1&2\\\\3&4\\end{" env "}$"))
    ) ;latex->texmacs
  ) ;tree->stree
) ;define

(define (contains-tag? t tag)
  (cond ((== t tag) #t)
        ((pair? t) (or (contains-tag? (car t) tag) (contains-tag? (cdr t) tag)))
        (else #f)
  ) ;cond
) ;define

(define (test-export)
  (with m (export-math 'matrix)
    (check (string-contains? m "begin{pmatrix}") => #t)
    (check (string-contains? m "begin{array}") => #f)
    (check (string-contains? m "left(") => #f)
  ) ;with
  (with b (export-math 'bmatrix)
    (check (string-contains? b "begin{bmatrix}") => #t)
    (check (string-contains? b "begin{array}") => #f)
    (check (string-contains? b "left[") => #f)
  ) ;with
) ;define

(define (test-import)
  (with p (import-math "pmatrix")
    (check (contains-tag? p 'matrix) => #t)
  ) ;with
  (with b (import-math "bmatrix")
    (check (contains-tag? b 'bmatrix) => #t)
    (check (contains-tag? b 'tabular*) => #f)
  ) ;with
  (with m (import-math "matrix")
    (check (contains-tag? m 'tabular*) => #t)
    (check (contains-tag? m 'matrix) => #f)
  ) ;with
) ;define

(tm-define (test_7002)
  (test-export)
  (test-import)
  (check-report)
) ;tm-define
