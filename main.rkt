#lang racket/base

(provide run-demo
         run
         run-racket-demo
         run-racket)

(require racket/path racket/system)

(define (run-demo name dir filename pre-commands demo?)
  (define session-name (or name (path->string (file-name-from-path filename))))
  (define session-dir (or dir (path->string (expand-user-path "~"))))
  (define tmux (find-executable-path "tmux"))
  (if tmux
    (apply system*/exit-code
           tmux
           `("new-session" "-s" ,session-name "-c" ,session-dir ,@(if pre-commands (list pre-commands) null)
             ";"
             "split-window" "-h" ,(if demo? "view" "vim")
             "+nnoremap <silent> r :silent .Twrite {left} <bar> +<CR>"
             "+xnoremap <silent> r :<C-u>silent '<,'>Twrite {left} <bar> '>+<CR>"
             "+set nospell"
             "+0"
             ,filename))
    (begin0
      127 ;; not found
      (eprintf "tmux not found\n"))))

(define (run name dir filename pre-commands)
  (run name dir filename pre-commands #f))

(define (run-racket-demo name dir filename)
  (run name dir filename "racket" #t))

(define (run-racket name dir filename)
  (run name dir filename "racket" #f))

(module reader racket/base
  (provide (rename-out [read-tmux-syntax read-syntax]))
  (require syntax/strip-context
           racket/port)

  (define (read-tmux-syntax src in)
    (define filename (path->string (object-name in)))
    (define (read-next-datum)
      (with-handlers ([exn:fail:read? values])
        (read-syntax src in)))
    (define-values (name dir commands demo?)
      ;; defaults
      ;; N.B. demo? is null? to distinguish between set to a boolean (like #f)
      ;; and unset (null?). The default is therefore (null? demo?) === #t.
      (let loop ([name #f]
                 [dir #f]
                 [commands #f]
                 [demo? null])
        (with-handlers ([exn:fail:read?
                          (λ (e)
                            (values name dir commands demo?))])
          (define datum (read-syntax src in))
          (cond
            [(and (syntax? datum)
                  (keyword? (syntax-e datum)))
             (case (syntax-e datum)
               [(#:name)
                (define maybe-name (read-next-datum))
                (if (and (not name)
                         (syntax? maybe-name)
                         (string? (syntax-e maybe-name)))
                  (loop (syntax-e maybe-name) dir commands demo?)
                  (values name dir commands demo?))]
               [(#:dir)
                (define maybe-dir (read-next-datum))
                (if (and (not dir)
                         (syntax? maybe-dir)
                         (string? (syntax-e maybe-dir)))
                  (loop name (syntax-e maybe-dir) commands demo?)
                  (values name dir commands demo?))]
               [(#:pre)
                (define maybe-commands (read-next-datum))
                (if (and (not commands)
                         (syntax? maybe-commands)
                         (string? (syntax-e maybe-commands)))
                  (loop name dir (syntax-e maybe-commands) demo?)
                  (values name dir commands demo?))]
               [(#:demo?)
                (define maybe-demo? (read-next-datum))
                (if (and (null? demo?)
                         (syntax? maybe-demo?)
                         (boolean? (syntax-e maybe-demo?)))
                  (loop name dir commands (syntax-e maybe-demo?))
                  (values name dir commands demo?))]
               [else (values name dir commands demo?)])]
            [else (values name dir commands demo?)]))))
    ;; Throw away the rest of the content to avoid spurious forms after the
    ;; module. This means that the `#lang` form consumed the whole file and
    ;; didn't leave leftovers for racket's `read-syntax` to use, which manifest
    ;; as extra forms after the module this is intended to return. The extra
    ;; stuff could be used by `racket -f`, but `racket` errors.
    (port->string in)
    (strip-context
      #`(module demo racket/base
          (require tmux-vim-demo)
          (exit (run-demo #,name
                          #,dir
                          #,filename
                          #,commands
                          #,(or (null? demo?) demo?)))))))
