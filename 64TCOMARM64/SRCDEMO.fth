\ SRCDEMO.fth — Load samples/hello.tfth via generic TSRC-INCLUDE
\ Public domain. Pack-specific wrapper; loader is 64TCOMSRC/64SRC.fth.

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

S" samples/hello.tfth" TSRC-INCLUDE

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: SRC-DEMO-CHECK  ( -- )
  S" --- SRC-DEMO (hello.tfth) ---" TYPE CR
  S" MAIN" RUN-SYM RX !
  S" MAIN => " TYPE RX @ . CR
  RX @ 42 <> IF S" SRC-DEMO fail MAIN want 42" TYPE CR ABORT THEN
  [DEFINED] RUN-SYM-N [IF]
    S" MAIN" RUN-SYM-N RX !
    S" MAIN native => " TYPE RX @ . CR
    RX @ 42 <> IF S" SRC-DEMO fail MAIN native" TYPE CR ABORT THEN
  [THEN]
  S" SRC-DEMO: OK (TSRC-INCLUDE samples/hello.tfth => 42)" TYPE CR
  ;

SRC-DEMO-CHECK
