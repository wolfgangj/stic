;; stic-mode.el -- Emacs mode for "Sanity-To-Insanity Converter" input files
;; Copyright (C) 2017 Wolfgang Jaehrling
;;
;; ISC License
;;
;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

(defvar stic-mode-hook nil)

(defvar stic-mode-map
  (let ((map (make-sparse-keymap)))
    ;(define-key map "\t" 'stic-indent-line)
    map)
  "Keymap for stic major mode")

(defun stic-indent-line ()
  "Interactively indent the current line and maybe reposition cursor."
  (interactive)
  (indent-rigidly (line-beginning-position)
                  (line-end-position)
                  (- (find-indentation-level)
                     (current-indentation)))
  (if (string-match "^ +\n" (thing-at-point 'line t))
      (end-of-line)
    (when (string-match "^ *$"
                        (buffer-substring-no-properties (line-beginning-position) (point)))
      (while (= ?  (following-char))
        (forward-char 1)))))

(defun current-indentation ()
  (save-excursion
    (beginning-of-line)
    (let ((indent 0))
      (while (= 32 (following-char))
        (right-char)
        (setq indent (1+ indent)))
      indent)))

(defun find-indentation-level ()
  (+ (find-indentation-level-based-on-previous-indentation)
     (if (string-match "^ *}" (thing-at-point 'line t))
	 -2
       0)))

(defun last-char-before-newline (line)
  (substring line -2 -1))

(defun find-indentation-level-based-on-previous-indentation ()
  (save-excursion
    (beginning-of-line)
    (if (bobp)
        0
      (forward-line -1)
      (if (= ?\n (following-char))
          (find-indentation-level-based-on-previous-indentation)
        (let ((stripped-line
               (replace-regexp-in-string " *;;.*" "" (thing-at-point 'line t))))
          (if (and (not (equal stripped-line "\n"))
                   (equal "{" (last-char-before-newline stripped-line)))
              (+ 2 (current-indentation))
            (current-indentation)))))))

(defun stic-mode ()
  "Major mode for editing stic input files"
  (interactive)
  (kill-all-local-variables)
  ;(use-local-map stic-mode-map)
  (set (make-local-variable 'indent-line-function) 'stic-indent-line)
  (setq major-mode 'stic-mode)
  (setq mode-name "stic")
  (run-hooks 'stic-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.stic\\'" . stic-mode))

(provide 'stic-mode)
