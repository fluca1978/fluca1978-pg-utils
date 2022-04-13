;; pgformatter.el
;;
;; This snippet of code can help configuring Emacs
;; to use pgFormatter to format a buffer or region
;; while editing it in Emacs.
;;
;; pgFormatter is a project available at
;; <https://github.com/darold/pgFormatter>
;;
;; The code defines an interactive function
;; that accepts either a region or works on the
;; whole buffer, and invokes pgFormatter as a
;; shell command. This means that the time needed
;; to format the buffer is the same as required
;; by the external program.


;; Interactive function that can be called
;; by executing
;; M-x pgformatter-on-region
;;
;; The function does not take any argument, please
;; ensure the 'pgfrm' variable is set correctly to
;; the full path of pgFormatter on your machine.
;;
;; Variables 'b' and 'e' represents the begin and end
;; of the region or buffer. If no region is active, the whole
;; buffer will be formatted, otherwise only the specified region.
;;
;; The output of the command will replace the content of the
;; region or buffer.
;;
(defun pgformatter-on-region ()
  "A function to invoke pgFormatter as an external program."
  (interactive)
  (let ((b (if mark-active (min (point) (mark)) (point-min)))
        (e (if mark-active (max (point) (mark)) (point-max)))
        (pgfrm "/usr/bin/pg_format" ) )
    (shell-command-on-region b e pgfrm (current-buffer) 1)) )


;; If you want to bind the formatting engine to a keymap
;; use something like the following
(global-set-key (kbd "C-i") 'pgformatter-on-region)
