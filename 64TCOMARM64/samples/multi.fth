\ multi.fth — multi-file sample: FLOAD math.fth then use its words
\
\ How to build (from 64Forth, working folder = 64TCOMARM64/):
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/multi.fth
\
\ Run:
\   ./samples/multi 7     → prints 14 and 49, exit 0
\   ./samples/multi       → usage, exit 1
\
\ Relative FLOAD looks next to this file (samples/math.fth).
\
\ See samples/README.txt

FLOAD math.fth

: MAIN
  ARGCOUNT 1 =
  IF
    ARG1 S>N
    DUP DOUBLE . SPACE
    SQUARE . CR
    0
  ELSE
    S" usage: multi n
"
    TYPE
    1
  THEN
;
