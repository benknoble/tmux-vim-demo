#lang scribble/manual
@(require (for-label tmux-vim-demo racket/base racket/contract)
          scribble/bnf)

@title{tmux-vim-demo}
@author{D. Ben Knoble}

@defmodulelang[tmux-vim-demo]

This language provides a convenient way to run a demo.

The demo is formed from a running shell and a script. The script is simply a
record of commands you may or may not want to send to the shell, so it has some
things in common with an actor's script of lines as well as with a programmer's
program script.

Running a program in this language will spawn a new tmux session with a shell on
the left and Vim (in readonly mode) on the right. Vim will have two keybindings:
Normal-mode @tt{r} sends the line under the cursor to the shell and moves down a
line. Visual-mode @tt{r} does the same for the visually-selected lines.

If the @racket[#:pre] directive is given, the corresponding commands will be
given to @tt{tmux new-session}: the shell pane on the left will be replaced with
the result of those commands.

This requires @hyperlink["https://github.com/tpope/vim-tbone"]{tpope/vim-tbone}
to be installed in Vim, or at least a compatible definition of @tt{:Twrite}.

@BNF[(list @nonterm{demo}
           @BNF-seq-lines[
            (list @optional{@nonterm{name}})
            (list @optional{@nonterm{dir}})
            (list @optional{@nonterm{pre-commands}})
            (list @elem{Script lines @BNF-etc})])
     (list @nonterm{name}
           @BNF-seq[@litchar{#:name} @elem{session name (string)}])
     (list @nonterm{dir}
           @BNF-seq[@litchar{#:dir} @elem{directory for demo (string)}])
     (list @nonterm{pre-commands}
           @BNF-seq[@litchar{#:pre} @elem{commands for shell (string)}])]

@defmodule[tmux-vim-demo]

The language expands into a call to @racket[run-demo] and @racket[exit]s with
the returned status-code.

@defproc[(run-demo [name (or/c #f string?)] [dir (or/c #f string?)] [filename string?] [pre-commands (or/c #f string?)])
         byte?]{
    Runs the demo in a tmux session named @racket[name] with directory
    @racket[dir]. The opened file is @racket[filename]. Returns the exit code of
    the @tt{tmux} invocation.

    If @racket[name] is @racket[#f], uses the base-name of @racket[filename].

    If @racket[dir] is @racket[#f], uses the user's home directory.

    If @racket[pre-commands] is @racket[#f], lets tmux spawn a shell or its
    @tt{default-command}. Otherwise, they are given to @tt{new-session}.
}
