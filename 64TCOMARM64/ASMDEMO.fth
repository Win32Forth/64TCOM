\ ASMDEMO.fth — Phase 3.1 assembler smoke
\ Public domain. Loaded by ASM-DEMO.
\
\ Leaf A: mov/add => 7
\ Leaf B: count with L: and CBNZ => 3

TARGET-INIT
/SHOW
LL-INIT

\ ----- Leaf A: 6+1 = 7 -----
ALIGN4-T
HERE-T                                 \ tA
6 X0 MOV-X-IMM64,
1 X1 MOV-X-IMM64,
X1 X0 X0 ADD-X-X,                      \ x0 = x0 + x1
RET,

\ ----- Leaf B: x0=0; L0: x0+=1; x2=x0-3; cbnz x2,L0; ret => 3 -----
ALIGN4-T
HERE-T                                 \ tB
0 X0 MOV-X-IMM64,
0 L:
1 X1 MOV-X-IMM64,
X1 X0 X0 ADD-X-X,
3 X1 MOV-X-IMM64,
X1 X0 X2 SUB-X-X,                      \ x2 = x0 - 3
\ CBNZ X2, L0  (backward)
0 CELLS LL-POS + @                     \ dest
ALIGN4-T
HERE-T - 4 /                           \ imm19
X2 SWAP CBNZ-X,
RET,

ARM64-FINISH

\ stack: tA tB
S" ASM-DEMO A @" TYPE OVER SYM-HEX. CR
S" ASM-DEMO B @" TYPE DUP SYM-HEX. CR

RUN-T
S" leafB => " TYPE DUP . CR
3 <> IF S" ASM-DEMO fail leafB (want 3)" TYPE CR ABORT THEN
DROP

RUN-T
S" leafA => " TYPE DUP . CR
7 <> IF S" ASM-DEMO fail leafA (want 7)" TYPE CR ABORT THEN
DROP

S" ASM-DEMO: OK" TYPE CR
