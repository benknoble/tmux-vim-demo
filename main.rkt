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

(module reader syntax/module-reader
  -ignored-
  #:wrapper2 (λ (in rd stx?)
               (define parsed (rd in))
               (define module
                 (syntax-parse (datum->syntax #f parsed)
                   #:datum-literals (module #%module-begin)
                   [(module _ _
                      (#%module-begin
                       {~optional {~seq #:name name:string} #:defaults ([name #'#f])}
                       {~optional {~seq #:dir dir:string} #:defaults ([dir #'#f])}
                       {~optional {~seq #:pre commands:string} #:defaults ([commands #'#f])}
                       {~optional {~seq #:demo? demo?:boolean} #:defaults ([demo? #'#t])}
                       _:expr ...))
                    #:with filename (path->string (object-name in))
                    #'(module demo racket/base
                        (require tmux-vim-demo)
                        (exit (run-demo name dir filename commands demo?)))]))
               (if stx?
                 (strip-context module)
                 (syntax->datum module)))

  (require syntax/parse syntax/strip-context))
