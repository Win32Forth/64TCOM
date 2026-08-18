\ args.fth — Layer 2 CLI arguments (ARGCOUNT ARG1 ARG2 ARG#)
\
\ How to build (from 64Forth, working folder = 64TCOMARM64/):
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/args.fth
\
\ Run examples (from 64TCOMARM64/):
\   ./samples/args
\   ./samples/args hello world
\   ./samples/args "" foo
\
\ Expect:
\   line 1 = ARG1 (or empty)
\   line 2 = ARG2 (or empty)
\   exit status = ARGCOUNT (number of user args, not including program name)
\
\ See samples/README.txt

: MAIN
  ARG1 TYPE
  S" 
"
  TYPE
  ARG2 TYPE
  S" 
"
  TYPE
  ARGCOUNT
;
