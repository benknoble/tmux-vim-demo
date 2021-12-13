#lang racket/base

(provide run-demo)

(require racket/path racket/system)

(define (run-demo name dir filename)
  (define session-name (or name (path->string (file-name-from-path filename))))
  (define session-dir (or dir (path->string (expand-user-path "~"))))
  (define tmux (find-executable-path "tmux"))
  (system*/exit-code
    tmux
    "new-session" "-s" session-name "-c" session-dir
    ";"
    "split-window" "-h" "view" "+nnoremap r :.Twrite {left} <bar> +<CR>" "+xnoremap r :Twrite {left} <bar> '>+<CR>" "+set nospell" "+0"
    filename))

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
                       _:expr ...))
                    #:with filename (path->string (object-name in))
                    #'(module demo racket/base
                        (require tmux-vim-demo)
                        (exit (run-demo name dir filename)))]))
               (if stx?
                 (strip-context module)
                 (syntax->datum module)))

  (require syntax/parse syntax/strip-context))
