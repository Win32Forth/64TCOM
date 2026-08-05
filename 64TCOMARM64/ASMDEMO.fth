\ ASMDEMO.fth — Phase 3.1 assembler smoke
\ Public domain. Loaded by ASM-DEMO.
\
\ FORTH vars (not TARGET). Checks in a colon (not interpret IF).
\ A: 6+1 => 7
\ B: AHEAD/THEN, skip junk => 3
\ C: unrolled three adds => 3  (stable; no CBNZ back-edge)

FORTH DEFINITIONS
VARIABLE TA
VARIABLE TB
VARIABLE TC
VARIABLE RX

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

\ ----- A: 6+1 = 7 -----
ALIGN4-T
HERE-T TA !
6 X0 MOV-X-IMM64,
1 X1 MOV-X-IMM64,
X1 X0 X0 ADD-X-X,
RET,

\ ----- B: AHEAD skips mov #99 => 3 -----
ALIGN4-T
HERE-T TB !
AHEAD
99 X0 MOV-X-IMM64,
THEN,
3 X0 MOV-X-IMM64,
RET,

\ ----- C: 0+1+1+1 = 3 -----
ALIGN4-T
HERE-T TC !
0 X0 MOV-X-IMM64,
1 X1 MOV-X-IMM64,
X1 X0 X0 ADD-X-X,
X1 X0 X0 ADD-X-X,
X1 X0 X0 ADD-X-X,
RET,

ARM64-FINISH
FORTH DEFINITIONS

: ASM-DEMO-CHECK  ( -- )
  S" ASM-DEMO A @" TYPE TA @ SYM-HEX. CR
  S" ASM-DEMO B @" TYPE TB @ SYM-HEX. CR
  S" ASM-DEMO C @" TYPE TC @ SYM-HEX. CR

  TC @ RUN-T RX !
  S" leafC => " TYPE RX @ . CR
  RX @ 3 <> IF S" ASM-DEMO fail leafC" TYPE CR ABORT THEN

  TB @ RUN-T RX !
  S" leafB => " TYPE RX @ . CR
  RX @ 3 <> IF S" ASM-DEMO fail leafB" TYPE CR ABORT THEN

  TA @ RUN-T RX !
  S" leafA => " TYPE RX @ . CR
  RX @ 7 <> IF S" ASM-DEMO fail leafA" TYPE CR ABORT THEN

  S" ASM-DEMO: OK" TYPE CR
  ;

ASM-DEMO-CHECK
