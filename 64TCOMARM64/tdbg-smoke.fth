\ Non-interactive debugger smoke (no interactive KEY)
\ FLOAD TARGETARM64.fth  then  FLOAD tdbg-smoke.fth

ARM64-DEMO

: SMOKE-RUN  ( -- )
  S" ANS" SYM-FIND-IX SYM-ADDR@ DBG-START
  WHERE
  0
  BEGIN
    DUP 40 <
    DBG-HALTED? 0= AND
  WHILE
    DBG-STEP-INTO
    1+
  REPEAT
  DROP
  DBG-HALTED? 0= IF DBG-GO THEN
  S" X0=" TYPE DBG-X0@ DUP . CR
  5 <> IF S" TDBG smoke FAIL" TYPE CR ABORT THEN
  .RUN-ANS
  S" TDBG smoke: OK" TYPE CR
  ;

SMOKE-RUN
BYE
