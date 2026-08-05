\ ASMDEMO.fth — Phase 3.1 assembler smoke
\ Public domain. Loaded by ASM-DEMO.
\
\ Leaf A: 6 + 1 => 7
\ Leaf B: count 0,1,2,3 with L: / B.NE => 3

TARGET-INIT
/SHOW
LL-INIT

\ ----- Leaf A -----
ALIGN4-T
HERE-T                          \ tA
6 X0 MOV-X-IMM64,
1 X1 MOV-X-IMM64,
X1 X0 X0 ADD-X-X,
RET,

\ ----- Leaf B: for i=0; i!=3; i++ -----
ALIGN4-T
HERE-T                          \ tB
0 X0 MOV-X-IMM64,
0 L:                            \ top of loop
1 X1 MOV-X-IMM64,
X1 X0 X0 ADD-X-X,               \ x0++
3 X1 MOV-X-IMM64,
X1 X0 CMP-X,                    \ cmp x0, x1  (SUBS XZR,X0,X1)
0 CELLS LL-POS + @              \ L0 address
ALIGN4-T
HERE-T - 4 / NE B.COND,         \ b.ne L0
RET,

ARM64-FINISH

\ stack: tA tB
S" ASM-DEMO A @" TYPE OVER SYM-HEX. CR
S" ASM-DEMO B @" TYPE DUP SYM-HEX. CR

RUN-T
S" leafB => " TYPE DUP . CR
3 <> IF S" ASM-DEMO fail leafB" TYPE CR ABORT THEN
DROP

RUN-T
S" leafA => " TYPE DUP . CR
7 <> IF S" ASM-DEMO fail leafA" TYPE CR ABORT THEN
DROP

S" ASM-DEMO: OK" TYPE CR
