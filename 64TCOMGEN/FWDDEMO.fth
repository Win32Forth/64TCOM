\ FWDDEMO.fth — interpret-time forward-ref smoke (loaded by FWD-DEMO)
\ Public domain. Requires TARGETGEN already loaded.
\
\ MAIN references HELLO before HELLO is defined; resolve patches CALL.

TARGET-INIT
/SHOW

T: MAIN
  G' HELLO
;T

T: HELLO
  $1111 G,
;T

GEN-FINISH

CR ." FWD-DEMO done. HERE-T=" HERE-T . CR
.SYMBOLS

S" HELLO" SYM-FIND 0= IF
  ." FWD-DEMO fail: HELLO missing" CR ABORT
THEN
DROP
DROP

S" HELLO" SYM-FIND 0= IF
  ." FWD-DEMO fail: HELLO missing (2)" CR ABORT
THEN
DROP
SYM-TYPE@ SYM-FORWARD = IF
  ." FWD-DEMO fail: HELLO still FWD" CR ABORT
THEN

S" MAIN" SYM-FIND 0= IF
  ." FWD-DEMO fail: MAIN missing" CR ABORT
THEN
DROP
SYM-TYPE@ SYM-TARGET <> IF
  ." FWD-DEMO fail: MAIN not TARGET" CR ABORT
THEN

S" HELLO" SYM-FIND 0= IF
  ." FWD-DEMO fail: HELLO uses" CR ABORT
THEN
DROP
SYM-USES@ 1 < IF
  ." FWD-DEMO fail: HELLO uses < 1" CR ABORT
THEN

." FWD-DEMO: OK (forward HELLO resolved)" CR
