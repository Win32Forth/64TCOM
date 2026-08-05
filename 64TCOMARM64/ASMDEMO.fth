\ ASMDEMO.fth — Phase 3.1 assembler smoke
\ Public domain. Loaded by ASM-DEMO.
\
\ Host VARIABLEs must live in FORTH (TARGET-INIT sets DEFINITIONS TARGET;
\ ARM64-FINISH >FORTH removes TARGET from the search order).

FORTH DEFINITIONS
VARIABLE TA
VARIABLE TB
VARIABLE TC
VARIABLE IMM

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS                \ keep assembling helpers visible; emit still uses HERE-T

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

\ ----- C: countdown x0=3; cbnz x0,L0; mov #3 -----
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

S" ASM-DEMO A @" TYPE TA @ SYM-HEX. CR
S" ASM-DEMO B @" TYPE TB @ SYM-HEX. CR
S" ASM-DEMO C @" TYPE TC @ SYM-HEX. CR

TC @ RUN-T
S" leafC => " TYPE DUP . CR
3 <> IF S" ASM-DEMO fail leafC (want 3)" TYPE CR ABORT THEN
DROP

TB @ RUN-T
S" leafB => " TYPE DUP . CR
3 <> IF S" ASM-DEMO fail leafB (want 3)" TYPE CR ABORT THEN
DROP

TA @ RUN-T
S" leafA => " TYPE DUP . CR
7 <> IF S" ASM-DEMO fail leafA (want 7)" TYPE CR ABORT THEN
DROP

S" ASM-DEMO: OK" TYPE CR
