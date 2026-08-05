\ FWDDEMO.fth — interpret-time forward-ref smoke (loaded by FWD-DEMO)
\ Public domain. Requires TARGETGEN already loaded.
\
\ Use VARIABLE + ! / @ only — not VALUE/TO (interpret TO has been flaky
\ on some 64Forth builds). No names starting with "(".

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

VARIABLE FD-IX
VARIABLE FD-TY

S" HELLO" SYM-FIND-IX FD-IX !
FD-IX @ SYM-TYPE@ FD-TY !

FD-TY @ SYM-TARGET <> IF
  S" FWD-DEMO fail: HELLO type=" TYPE FD-TY @ .
  S" ix=" TYPE FD-IX @ .
  S" want TARGET=" TYPE SYM-TARGET . CR
  ABORT
THEN

FD-IX @ SYM-USES@ 1 < IF
  S" FWD-DEMO fail: HELLO uses < 1" TYPE CR ABORT
THEN

S" MAIN" SYM-FIND-IX FD-IX !
FD-IX @ SYM-TYPE@ SYM-TARGET <> IF
  S" FWD-DEMO fail: MAIN not TARGET" TYPE CR ABORT
THEN

S" FWD-DEMO: OK (forward HELLO resolved)" TYPE CR
