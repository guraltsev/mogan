;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : kbd-define-test.scm
;; DESCRIPTION : Test suite for delayed-kbd-map
;; COPYRIGHT   : (C) 2026  Da Shen
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (kernel gui kbd-define-test) (:use (kernel gui kbd-define)))

(import (liii check))

(check-set-mode! 'report-failed)

;; kbd-find-key-binding 对 shorthand 返回 (插入串 help) 列表

(define (test-enqueue-defers)
  ;; 入队后未 flush:绑定留在队列里,尚未写表
  (delayed-kbd-map ("T17a" "AAA"))
  (check (kbd-pending-empty?) => #f)
) ;define

(define (test-flush-registers)
  (kbd-flush-pending)
  (check (kbd-pending-empty?) => #t)
  (check (kbd-find-key-binding "T17a") => (list "AAA" ""))
) ;define

(define (test-getter-drains)
  ;; 不经显式 flush,按键查询路径(kbd-find-key-binding)自动 drain
  (delayed-kbd-map ("T17b" "BBB"))
  (check (kbd-find-key-binding "T17b") => (list "BBB" ""))
  (check (kbd-pending-empty?) => #t)
) ;define

(define (test-override-after-delayed)
  ;; 同步写不触发 drain:delayed 批次的 old 在查询 drain 时才执行,
  ;; 按执行先后后执行的 old 覆盖先写入的 new
  (delayed-kbd-map ("T17c" "old"))
  (kbd-map ("T17c" "new"))
  (check (kbd-find-key-binding "T17c") => (list "old" ""))
) ;define

(define (test-override-before-delayed)
  ;; 同步先写 old,delayed 后入队 new:flush 后后定义胜出
  (kbd-map ("T17d" "old"))
  (delayed-kbd-map ("T17d" "new"))
  (kbd-flush-pending)
  (check (kbd-find-key-binding "T17d") => (list "new" ""))
) ;define

(define (test-multi-key-sequence)
  ;; 多键序列:完整序列命中 shorthand
  (delayed-kbd-map ("T17e x y" "EEE"))
  (kbd-flush-pending)
  (check (kbd-find-key-binding "T17e x y") => (list "EEE" ""))
) ;define

(define (test-user-beats-later-builtin)
  ;; 内置模块后加载（lazy）也不能覆盖同键同条件的用户绑定
  (user-kbd-map ("T20a" "USER"))
  (kbd-map ("T20a" "BUILTIN"))
  (check (kbd-find-key-binding "T20a") => (list "USER" ""))
) ;define

(define (test-user-beats-earlier-builtin)
  (kbd-map ("T20b" "BUILTIN"))
  (user-kbd-map ("T20b" "USER"))
  (check (kbd-find-key-binding "T20b") => (list "USER" ""))
) ;define

(define (test-user-beats-later-builtin-other-conds)
  ;; 用户带条件、后加载的内置无条件：按最近优先本会选内置，分层后仍选用户
  (user-kbd-map (:require #t) ("T20c" "USER"))
  (kbd-map ("T20c" "BUILTIN"))
  (check (kbd-find-key-binding "T20c") => (list "USER" ""))
) ;define

(define (test-builtin-fallback-when-user-condition-fails)
  (user-kbd-map (:require #f) ("T20d" "USER"))
  (kbd-map ("T20d" "BUILTIN"))
  (check (kbd-find-key-binding "T20d") => (list "BUILTIN" ""))
) ;define

(define (test-unmap-masks-later-builtin)
  (kbd-map ("T20e" "BUILTIN"))
  (user-kbd-unmap "T20e")
  (check (kbd-find-key-binding "T20e") => #f)
  (kbd-map ("T20e" "LATER"))
  (check (kbd-find-key-binding "T20e") => #f)
) ;define

(define (test-unmap-keeps-other-conditions)
  (kbd-map (:require #t) ("T20f" "OTHER"))
  (kbd-map ("T20f" "PLAIN"))
  (user-kbd-unmap "T20f")
  (check (kbd-find-key-binding "T20f") => (list "OTHER" ""))
) ;define

(define (test-user-key-normalization)
  (check (user-kbd-key "A-x") => "A-x")
  (check (user-kbd-key "` <") => "` <")
  (check (user-kbd-key "α") => "alpha")
  (check (user-kbd-key "` α") => "` alpha")
  (check (user-kbd-key "￥") => "<#FFE5>")
) ;define

(define (test-user-literal-unicode-key)
  ;; 字面 α 与具名 alpha 落到同一个键（C++ 侧到达 Scheme 的就是 alpha）
  (user-kbd-map ("α" "ALPHA"))
  (check (kbd-find-key-binding "alpha") => (list "ALPHA" ""))
) ;define

(define (test-user-multi-key-sequence)
  (user-kbd-map ("T20g x y" "GGG"))
  (check (kbd-find-key-binding "T20g x y") => (list "GGG" ""))
) ;define

(define (cleanup)
  ;; kbd-unmap 的条目是裸按键字符串;"T17e"/"T17e x" 是多键序列的中间回显绑定
  (kbd-unmap "T17a" "T17b" "T17c" "T17d" "T17e" "T17e x" "T17e x y")
  (kbd-unmap "T20a" "T20b" "T20c" "T20d" "T20e" "T20f" "T20g" "T20g x"
    "T20g x y" "alpha"
  ) ;kbd-unmap
) ;define

(tm-define (regtest-kbd-define)
  (test-enqueue-defers)
  (test-flush-registers)
  (test-getter-drains)
  (test-override-after-delayed)
  (test-override-before-delayed)
  (test-multi-key-sequence)
  (test-user-beats-later-builtin)
  (test-user-beats-earlier-builtin)
  (test-user-beats-later-builtin-other-conds)
  (test-builtin-fallback-when-user-condition-fails)
  (test-unmap-masks-later-builtin)
  (test-unmap-keeps-other-conditions)
  (test-user-key-normalization)
  (test-user-literal-unicode-key)
  (test-user-multi-key-sequence)
  (cleanup)
  (check-report)
) ;tm-define
