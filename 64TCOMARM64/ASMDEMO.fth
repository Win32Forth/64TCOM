\ ASMDEMO.fth — Phase 3.1 assembler smoke
\ Public domain. Loaded by ASM-DEMO.
\
\ Host VARIABLEs in FORTH (not TARGET). Checks inside a colon
\ (interpret-time IF is unreliable on 64Forth).

FORTH DEFINITIONS
VARIABLE TA
VARIABLE TB
VARIABLE TC
VARIABLE IMM
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

\ ----- C: x0=3; L0: x0--; cbnz x0,L0; mov #3 -----
ALIGN4-T
HERE-T TC !
3 X0 MOV-X-IMM64,
0 L:
1 X1 MOV-X-IMM64,
X1 X0 X0 SUB-X-X,
0 CELLS LL-POS + @
ALIGN4-T
HERE-T - 4 / IMM !
X0 IMM @ CBNZ-X,
3 X0 MOV-X-IMM64,
RET,

ARM64-FINISH
FORTH DEFINITIONS

: ASM-DEMO-CHECK  ( -- )
  S" ASM-DEMO A @" TYPE TA @ SYM-HEX. CR
  S" ASM-DEMO B @" TYPE TB @ SYM-HEX. CR
  S" ASM-DEMO C @" TYPE TC @ SYM-HEX. CR

  TC @ RUN-T RX !
  S" leafC => " TYPE RX @ . CR
  RX @ 3 <> IF
    S" ASM-DEMO fail leafC (want 3)" TYPE CR ABORT
  THEN

  TB @ RUN-T RX !
  S" leafB => " TYPE RX @ . CR
  RX @ 3 <> IF
    S" ASM-DEMO fail leafB (want 3)" TYPE CR ABORT
  THEN

  TA @ RUN-T RX !
  S" leafA => " TYPE RX @ . CR
  RX @ 7 <> IF
    S" ASM-DEMO fail leafA (want 7)" TYPE CR ABORT
  THEN

  S" ASM-DEMO: OK" TYPE CR
  ;

ASM-DEMO-CHECK
