\ FWDDEMO.fth — interpret-time forward-ref smoke (loaded by FWD-DEMO)
\ Public domain. Requires TARGETGEN already loaded.
\
\ Do not name words with leading "(" — at interpret time "(" is the
\ comment word, so (FD-IX) never fetches a VALUE.

TARGET-INIT
/SHOW

T: MAIN
  G' HELLO
;T

T: HELLO
  $1111 G,
;T

GEN-FINISH

CR
S" FWD-DEMO done. HERE-T=" TYPE HERE-T . CR
.SYMBOLS

0 VALUE FD-IX
0 VALUE FD-TY

S" HELLO" SYM-FIND-IX TO FD-IX
FD-IX SYM-TYPE@ TO FD-TY

FD-TY SYM-TARGET <> IF
  S" FWD-DEMO fail: HELLO type=" TYPE FD-TY .
  S" ix=" TYPE FD-IX .
  S" want TARGET=" TYPE SYM-TARGET . CR
  ABORT
THEN

FD-IX SYM-USES@ 1 < IF
  S" FWD-DEMO fail: HELLO uses < 1" TYPE CR ABORT
THEN

S" MAIN" SYM-FIND-IX TO FD-IX
FD-IX SYM-TYPE@ SYM-TARGET <> IF
  S" FWD-DEMO fail: MAIN not TARGET" TYPE CR ABORT
THEN

S" FWD-DEMO: OK (forward HELLO resolved)" TYPE CR
