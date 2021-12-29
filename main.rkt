#lang racket/base

(provide run-demo)

(require racket/path racket/system)

(define (run-demo name dir filename pre-commands)
  (define session-name (or name (path->string (file-name-from-path filename))))
  (define session-dir (or dir (path->string (expand-user-path "~"))))
  (define tmux (find-executable-path "tmux"))
  (if tmux
    (apply system*/exit-code
           tmux
           `("new-session" "-s" ,session-name "-c" ,session-dir ,@(if pre-commands (list pre-commands) null)
             ";"
             "split-window" "-h" "view"
             "+nnoremap <silent> r :silent .Twrite {left} <bar> +<CR>"
             "+xnoremap <silent> r :<C-u>silent '<,'>Twrite {left} <bar> '>+<CR>"
             "+set nospell"
             "+0"
             ,filename))
    (begin0
      127 ;; not found
      (eprintf "tmux not found\n"))))

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
                       _:expr ...))
                    #:with filename (path->string (object-name in))
                    #'(module demo racket/base
                        (require tmux-vim-demo)
                        (exit (run-demo name dir filename commands)))]))
               (if stx?
                 (strip-context module)
                 (syntax->datum module)))

  (require syntax/parse syntax/strip-context))
