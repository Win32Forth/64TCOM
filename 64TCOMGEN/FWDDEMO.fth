\ FWDDEMO.fth — interpret-time forward-ref smoke (loaded by FWD-DEMO)
\ Public domain. Requires TARGETGEN already loaded.
\
\ MAIN references HELLO before HELLO is defined; resolve patches CALL.
\ Use S" … TYPE at interpret time (." can be compile-only / awkward).

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

\ HELLO must exist, be TARGET (resolved), and have uses >= 1
S" HELLO" SYM-FIND-IX
DUP SYM-TYPE@ SYM-FORWARD = IF
  DROP
  S" FWD-DEMO fail: HELLO still FWD" TYPE CR ABORT
THEN
DUP SYM-TYPE@ SYM-TARGET <> IF
  DROP
  S" FWD-DEMO fail: HELLO not TARGET" TYPE CR ABORT
THEN
SYM-USES@ 1 < IF
  S" FWD-DEMO fail: HELLO uses < 1" TYPE CR ABORT
THEN

S" MAIN" SYM-FIND-IX
SYM-TYPE@ SYM-TARGET <> IF
  S" FWD-DEMO fail: MAIN not TARGET" TYPE CR ABORT
THEN

S" FWD-DEMO: OK (forward HELLO resolved)" TYPE CR
