\ ASMARM64.fth — Forth-style AArch64 assembler for 64TCOMARM64
\
\ Public domain. Requires 64HOST.fth.
\ Emits little-endian 32-bit A64 into target CODE (W, / C,-T).
\
\ ABI (subroutine-threaded Forth):
\   X0 = TOS   X19 = DSP   X1 = scratch   X16 = call   X30 = LR
\
\ Phase 3.1 adds: X0–X30, AND/ORR/EOR, ADDS/SUBS/CMP, ADD/SUB imm,
\ LDR/STR scaled, B/BL/B.cond, CBZ/CBNZ, labels L0..L15, AHEAD/THEN,,
\ AIF,/AELSE,/ATHEN,.

TCOM-ANEW ASMARM64

FORTH DEFINITIONS
DECIMAL

VOCABULARY ASMARM64
: [ASMARM64]  ( -- )  ASMARM64 ; IMMEDIATE

FALSE VALUE ?ASM-ACTIVE

VARIABLE A64-I
VARIABLE A64-D
VARIABLE A64-H
VARIABLE A64-N
VARIABLE A64-M
VARIABLE A64-T
VARIABLE A64-A

: (REG)  ( n -- n )  $1F AND ;

: W,  ( u32 -- )
  DUP $FF AND C,-T
  8 RSHIFT DUP $FF AND C,-T
  8 RSHIFT DUP $FF AND C,-T
  8 RSHIFT $FF AND C,-T
  ;

: ALIGN4-T  ( -- )
  BEGIN HERE-T 3 AND WHILE  0 C,-T  REPEAT
  ;

: PATCH-W  ( u32 taddr -- )
  OVER $FF AND OVER C!-T
  OVER 8 RSHIFT $FF AND OVER 1 + C!-T
  OVER 16 RSHIFT $FF AND OVER 2 + C!-T
  SWAP 24 RSHIFT $FF AND SWAP 3 + C!-T
  ;

: W@-T  ( taddr -- u32 )
  DUP C@-T
  OVER 1 + C@-T 8 LSHIFT OR
  OVER 2 + C@-T 16 LSHIFT OR
  SWAP 3 + C@-T 24 LSHIFT OR
  ;

\ ----- registers -----
0 CONSTANT X0   1 CONSTANT X1   2 CONSTANT X2   3 CONSTANT X3
4 CONSTANT X4   5 CONSTANT X5   6 CONSTANT X6   7 CONSTANT X7
8 CONSTANT X8   9 CONSTANT X9  10 CONSTANT X10 11 CONSTANT X11
12 CONSTANT X12 13 CONSTANT X13 14 CONSTANT X14 15 CONSTANT X15
16 CONSTANT X16 17 CONSTANT X17 18 CONSTANT X18 19 CONSTANT X19
20 CONSTANT X20 21 CONSTANT X21 22 CONSTANT X22 23 CONSTANT X23
24 CONSTANT X24 25 CONSTANT X25 26 CONSTANT X26 27 CONSTANT X27
28 CONSTANT X28 29 CONSTANT X29 30 CONSTANT X30
31 CONSTANT XZR
31 CONSTANT SP

\ ----- basic -----
: NOP,   ( -- )  $D503201F W, ;
\ BTI landing pad (HINT). Required on some Apple exec pages for BL/BR targets;
\ executes as NOP if BTI is not enforced.
\ Optional landing pad; default NOP so native BLR/BL is not required for demos.
: BTI,   ( -- )  NOP, ;
: RET,   ( -- )  $D65F03C0 W, ;
: RET-X, ( xn -- )  (REG) 5 LSHIFT $D65F0000 OR W, ;
: BLR-X, ( xn -- )  (REG) 5 LSHIFT $D63F0000 OR W, ;
: BR-X,  ( xn -- )  (REG) 5 LSHIFT $D61F0000 OR W, ;

\ SVC #imm16  — encoding 0xD4000001 | (imm16 << 5)
\ Darwin/macOS user SVC uses #0x80 with X16 = BSD syscall number.
: SVC,  ( imm16 -- )
  $FFFF AND 5 LSHIFT $D4000001 OR W,
  ;

\ ----- move / logic / arith -----
: MOVZ-X,  ( imm16 xd hw -- )
  A64-H ! A64-D ! A64-I !
  A64-H @ 3 U> IF S" MOVZ hw 0..3" TCOM-ABORT THEN
  $D2800000 A64-H @ 21 LSHIFT OR
  A64-I @ $FFFF AND 5 LSHIFT OR
  A64-D @ (REG) OR W,
  ;

: MOVK-X,  ( imm16 xd hw -- )
  A64-H ! A64-D ! A64-I !
  A64-H @ 3 U> IF S" MOVK hw 0..3" TCOM-ABORT THEN
  $F2800000 A64-H @ 21 LSHIFT OR
  A64-I @ $FFFF AND 5 LSHIFT OR
  A64-D @ (REG) OR W,
  ;

: MOV-X-IMM64,  ( imm64 xd -- )
  (REG) A64-D !
  DUP $FFFF AND            A64-D @ 0 MOVZ-X,
  DUP 16 RSHIFT $FFFF AND  A64-D @ 1 MOVK-X,
  DUP 32 RSHIFT $FFFF AND  A64-D @ 2 MOVK-X,
      48 RSHIFT $FFFF AND  A64-D @ 3 MOVK-X,
  ;

: MOV-X-X,  ( xm xd -- )
  A64-D ! A64-M !
  $AA0003E0 A64-M @ (REG) 16 LSHIFT OR A64-D @ (REG) OR W,
  ;

: ORR-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $AA000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: AND-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $8A000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: EOR-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $CA000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: ADD-X-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $8B000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: SUB-X-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $CB000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: ADDS-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $AB000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: SUBS-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $EB000000 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: CMP-X,  ( xm xn -- )  XZR SUBS-X, ;

\ 0= on TOS (X0): MOV X1,X0; CMP X1,XZR; CSET X0,EQ
$EB1F003F CONSTANT (A64-CMP-X1-XZR)   \ CMP X1, XZR
$9A9F17E0 CONSTANT (A64-CSET-X0-EQ)   \ CSET X0, EQ

\ CSET Xd, cond  = CSINC Xd,XZR,XZR, invert(cond)
\ CSINC encoding needs bits[11:10]=01 (not CSEL's 00).
: CSET-X,  ( cond xd -- )
  A64-D !
  1 XOR $F AND 12 LSHIFT
  $9A9F07E0 OR
  A64-D @ (REG) OR W,
  ;

: T0=,  ( -- )
  X0 X1 MOV-X-X,
  (A64-CMP-X1-XZR) W,
  (A64-CSET-X0-EQ) W,
  X0 XZR X0 SUB-X-X,             \ Forth flag: 0 or -1 (not C 0/1)
  ;

: ADD-IMM,  ( imm12 xn xd -- )
  A64-D ! A64-N ! A64-I !
  $91000000 A64-I @ $FFF AND 10 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: SUB-IMM,  ( imm12 xn xd -- )
  A64-D ! A64-N ! A64-I !
  $D1000000 A64-I @ $FFF AND 10 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ 64-bit LSL Xd,Xn,#uimm (UBFM alias)
: LSL-IMM,  ( uimm xn xd -- )
  A64-D ! A64-N ! A64-I !
  A64-I @ 0= IF  A64-N @ A64-D @ MOV-X-X, EXIT  THEN
  A64-I @ 63 U> IF S" LSL-IMM 0..63" TCOM-ABORT THEN
  $D3400000
  64 A64-I @ - $3F AND 16 LSHIFT OR   \ immr
  63 A64-I @ - $3F AND 10 LSHIFT OR   \ imms
  A64-N @ (REG) 5 LSHIFT OR
  A64-D @ (REG) OR W,
  ;

\ LDRB Xt,[Xn]  (zero-extend byte)
: LDRB-X,  ( xt xn -- )
  A64-N ! A64-D !
  $39400000 A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ STRB Xt,[Xn]
: STRB-X,  ( xt xn -- )
  A64-N ! A64-D !
  $39000000 A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ MUL Xd, Xn, Xm  — 64-bit multiply (alias MADD Xd,Xn,Xm,XZR)
: MUL-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $9B007C00 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ UDIV Xd, Xn, Xm  — unsigned divide
: UDIV-X,  ( xm xn xd -- )
  A64-D ! A64-N ! A64-M !
  $9AC00800 A64-M @ (REG) 16 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ MSUB Xd, Xn, Xm, Xa  — Xd = Xa - Xn*Xm
: MSUB-X,  ( xm xa xn xd -- )
  A64-D ! A64-N ! A64-A ! A64-M !
  $9B008000 A64-M @ (REG) 16 LSHIFT OR
  A64-A @ (REG) 10 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ ADR Xd, #0 — Xd := address of this instruction (relocatable base recovery)
: ADR-X0,  ( xd -- )
  (REG) $10000000 OR W,
  ;

\ Emit: X16 := image base (runtime). Uses X17. PC-relative ADR - taddr.
\ base = ADR_result - taddr_of_ADR
: (BASE-X16,)  ( -- )
  ALIGN4-T
  HERE-T A64-T !                 \ taddr of ADR
  X16 ADR-X0,
  A64-T @ X17 MOV-X-IMM64,
  X17 X16 X16 SUB-X-X,           \ X16 = X16 - X17
  ;

\ X0 = dest taddr → BR to base+X0 (relocatable BRANCH helper)
: (TADDR-BR,)  ( -- )
  (BASE-X16,)
  X0 X16 X16 ADD-X-X,
  X16 BR-X,
  ;

\ ----- load/store -----
: (IMM9)  ( n -- u )  DUP 0< IF $200 + THEN $1FF AND ;

: STR-PRE,  ( xt xn simm -- )
  (IMM9) A64-I ! A64-N ! A64-D !
  $F8000C00 A64-I @ 12 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: LDR-POST,  ( xt xn simm -- )
  (IMM9) A64-I ! A64-N ! A64-D !
  $F8400400 A64-I @ 12 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: LDR-X0,  ( xt xn -- )
  A64-N ! A64-D !
  $F9400000 A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: STR-X0,  ( xt xn -- )
  A64-N ! A64-D !
  $F9000000 A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: LDR-OFF,  ( xt xn imm-bytes -- )
  DUP 7 AND IF S" LDR-OFF needs 8-aligned offset" TCOM-ABORT THEN
  3 RSHIFT A64-I ! A64-N ! A64-D !
  $F9400000 A64-I @ $FFF AND 10 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: STR-OFF,  ( xt xn imm-bytes -- )
  DUP 7 AND IF S" STR-OFF needs 8-aligned offset" TCOM-ABORT THEN
  3 RSHIFT A64-I ! A64-N ! A64-D !
  $F9000000 A64-I @ $FFF AND 10 LSHIFT OR
  A64-N @ (REG) 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: LDR64-PC+8,   ( xn -- )  (REG) $58000000 OR 2 5 LSHIFT OR W, ;
: LDR64-PC+12,  ( xn -- )  (REG) $58000000 OR 3 5 LSHIFT OR W, ;

: LDR64-LIT,  ( xn imm19 -- )
  A64-I ! A64-D !
  $58000000 A64-I @ $7FFFF AND 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ ----- branches -----
: B-IMM,   ( imm26 -- )  $3FFFFFF AND $14000000 OR W, ;
: BL-IMM,  ( imm26 -- )  $3FFFFFF AND $94000000 OR W, ;

0 CONSTANT EQ  1 CONSTANT NE
2 CONSTANT CS  2 CONSTANT HS
3 CONSTANT CC  3 CONSTANT LO
4 CONSTANT MI  5 CONSTANT PL
6 CONSTANT VS  7 CONSTANT VC
8 CONSTANT HI  9 CONSTANT LS
10 CONSTANT GE 11 CONSTANT LT
12 CONSTANT GT 13 CONSTANT LE
14 CONSTANT AL

: B.COND,  ( imm19 cond -- )
  A64-D ! A64-I !
  $54000000 A64-I @ $7FFFF AND 5 LSHIFT OR A64-D @ $F AND OR W,
  ;

: CBNZ-X,  ( xt imm19 -- )
  A64-I ! A64-D !
  $B5000000 A64-I @ $7FFFF AND 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

: CBZ-X,  ( xt imm19 -- )
  A64-I ! A64-D !
  $B4000000 A64-I @ $7FFFF AND 5 LSHIFT OR A64-D @ (REG) OR W,
  ;

\ In-image call (Phase 3.5 — preserves LR so colon RET works after BLR):
\   STP X30,XZR,[SP,#-16]!
\   LDR X16,[PC+16]     ; .quad at +20 from LDR (= +16 from this LDR)
\   BLR X16
\   LDP X30,XZR,[SP],#16
\   B +3                ; skip 8-byte .quad (from B: +1=quad, +2=mid, +3=after)
\   .quad taddr         ; TARGET OFFSET (not host). Native/Mach-O fixup adds base.
\
\ Why STP/LDP: bare BLR overwrites X30; a following RET then jumps to the
\ instruction after BLR forever (SIM OK because it uses a separate R-stack).
\ Why B+3 not B+2: imm is in instructions from B itself; .quad is 2 words,
\ so landing after it is +3 from B (B+2 lands mid-quad → SIGILL).
\ Chain cell for SYM-COMPILE-REF is the .quad (HERE-T T-CELL -).

$A9BF7FFE CONSTANT (A64-STP-X30-XZR-SP)   \ STP X30, XZR, [SP, #-16]!
$A8C17FFE CONSTANT (A64-LDP-X30-XZR-SP)   \ LDP X30, XZR, [SP], #16

: CALL-ABS,  ( taddr -- )
  ALIGN4-T
  \ .quad at HERE+20 must be 8-aligned → HERE ≡ 4 (mod 8)
  HERE-T 7 AND 0= IF  NOP,  THEN
  (A64-STP-X30-XZR-SP) W,
  X16 4 LDR64-LIT,                 \ imm19=4 → PC+16 → .quad
  X16 BLR-X,
  (A64-LDP-X30-XZR-SP) W,
  3 B-IMM,                         \ skip .quad (must be +3, not +2)
  ,-T                              \ taddr offset (NOT THERE host addr)
  ;

: JMP-ABS,  ( taddr -- )
  ALIGN4-T
  HERE-T 7 AND 0= IF  NOP,  THEN
  X16 LDR64-PC+12,
  X16 BR-X,
  3 B-IMM,
  ,-T                                 \ taddr offset
  ;

\ ----- patch helpers -----
\ imm = (dest - taddr) / 4.  With ( dest taddr ) on stack, 2DUP - gives dest-taddr.

: PATCH-B  ( dest taddr -- )
  2DUP - 4 /
  $3FFFFFF AND $14000000 OR
  SWAP PATCH-W
  DROP
  ;

: PATCH-BCOND  ( dest taddr -- )
  DUP W@-T $F AND A64-D !
  2DUP - 4 /
  $7FFFF AND 5 LSHIFT $54000000 OR A64-D @ OR
  SWAP PATCH-W
  DROP
  ;

\ Patch CBZ/CBNZ at taddr to branch to dest (keeps Rt + B4/B5 opcode)
: PATCH-CBZ  ( dest taddr -- )
  DUP W@-T $1F AND A64-D !                 \ Rt
  DUP W@-T $FF000000 AND A64-I !           \ $B4000000 or $B5000000
  2DUP - 4 /
  $7FFFF AND 5 LSHIFT A64-I @ OR A64-D @ OR
  SWAP PATCH-W
  DROP
  ;

\ ----- structured control (asm) -----
: AHEAD  ( -- orig )
  ALIGN4-T  HERE-T  0 B-IMM,
  ;

: THEN,  ( orig -- )
  HERE-T SWAP PATCH-B
  ;

: AGAIN,  ( dest -- )
  ALIGN4-T
  HERE-T - 4 / B-IMM,
  ;

\ AIF, : branch if condition FALSE to skip (user supplies skip cond)
\ e.g. after CMP, AIF, NE  means skip when not equal
: AIF,  ( cond -- orig )
  ALIGN4-T  HERE-T SWAP  0 SWAP B.COND,
  ;

: ATHEN,  ( orig -- )
  HERE-T SWAP PATCH-BCOND
  ;

: AELSE,  ( orig1 -- orig2 )
  AHEAD  SWAP ATHEN,
  ;

\ ----- Forth-ABI control (TOS = flag in X0) — for T: … ;T graphs -----
\ TIF/TELSE/TTHEN use a private control stack so host DATA stack pollution
\ (common during TSRC-INCLUDE) cannot bury branch origins → B #0 hangs.

32 CONSTANT #TCS
CREATE TCS  #TCS CELLS ALLOT
VARIABLE TCSP
: TCS-CLEAR  ( -- )  0 TCSP ! ;
: TCS-PUSH  ( x -- )
  TCSP @ #TCS U>= IF S" TIF control stack overflow" TCOM-ABORT THEN
  TCSP @ CELLS TCS + !  1 TCSP +!
  ;
: TCS-POP  ( -- x )
  TCSP @ 0= IF S" TIF control stack underflow" TCOM-ABORT THEN
  -1 TCSP +!  TCSP @ CELLS TCS + @
  ;

TCS-CLEAR

: TIF  ( -- )
  \ MOV-X-X, is (xm xd): X0 X1 = MOV X1,X0 (flag TOS → X1)
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,             \ drop flag; new TOS
  ALIGN4-T
  HERE-T TCS-PUSH                \ CBZ site
  X1 0 CBZ-X,                    \ if flag==0 skip true part (imm patched later)
  ;

\ Resolve TIF's CBZ or TELSE's B (auto-detect opcode)
: TTHEN  ( -- )
  TCS-POP
  DUP W@-T 24 RSHIFT $FF AND $14 = IF
    HERE-T SWAP PATCH-B
  ELSE
    HERE-T SWAP PATCH-CBZ
  THEN
  ;

: TELSE  ( -- )
  ALIGN4-T HERE-T 0 B-IMM,       \ branch around else-part
  TCS-POP                        \ if-orig (CBZ)
  HERE-T SWAP PATCH-CBZ          \ IF's CBZ → start of else
  TCS-PUSH                       \ ahead-orig for TTHEN
  ;

\ BEGIN / UNTIL / AGAIN / WHILE / REPEAT — nestable via TLOOP-STACK
8 CONSTANT #TLOOP
CREATE TLOOP-STACK  #TLOOP CELLS ALLOT
VARIABLE TLOOP-SP
0 TLOOP-SP !
VARIABLE TLOOP-DEST                     \ mirror of current top (compat)

: TLOOP-PUSH  ( addr -- )
  TLOOP-SP @ #TLOOP >= IF
    DROP S" ASMARM64: BEGIN nest too deep" TYPE CR TCOM-ABORT
  THEN
  DUP TLOOP-DEST !
  TLOOP-STACK TLOOP-SP @ CELLS + !
  1 TLOOP-SP +!
  ;

: TLOOP-POP  ( -- addr )
  TLOOP-SP @ 0= IF
    S" ASMARM64: UNTIL/AGAIN/REPEAT without BEGIN" TYPE CR TCOM-ABORT
  THEN
  -1 TLOOP-SP +!
  TLOOP-STACK TLOOP-SP @ CELLS + @
  TLOOP-SP @ IF
    TLOOP-STACK TLOOP-SP @ 1- CELLS + @ TLOOP-DEST !
  ELSE
    0 TLOOP-DEST !
  THEN
  ;

: TBEGIN  ( -- )
  ALIGN4-T HERE-T TLOOP-PUSH
  ;

: TUNTIL  ( -- )
  \ flag TOS → X1; restore under to X0; CBZ X1,dest
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,
  ALIGN4-T
  TLOOP-POP HERE-T - 4 /           \ imm19 = (dest - HERE) / 4
  X1 SWAP CBZ-X,
  ;

: TAGAIN  ( -- )
  ALIGN4-T
  TLOOP-POP HERE-T - 4 / B-IMM,
  ;

\ TWHILE: if flag==0 skip to after TREPEAT; else continue (flag dropped)
\ CBZ origin on TCS (not host data stack) — same hygiene as TIF/TELSE.
\ TREPEAT: B back to BEGIN; patch WHILE's CBZ to fall-through after REPEAT
: TWHILE  ( -- )
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,
  ALIGN4-T
  HERE-T TCS-PUSH                    \ CBZ site
  X1 0 CBZ-X,
  ;

: TREPEAT  ( -- )
  ALIGN4-T
  TLOOP-POP HERE-T - 4 / B-IMM,      \ back to matching BEGIN
  TCS-POP HERE-T SWAP PATCH-CBZ      \ false WHILE → here
  ;

\ Count in X0 from 0 until X0==3. Result X0=3.
\   n=0
\ L: n += 1
\    if (n - 3) != 0 goto L
\ Machine (after 4-insn MOV#0):
\   91000400  ADD X0,X0,#1
\   AA0003E1  MOV X1,X0
\   D1000C21  SUB X1,X1,#3
\   B5FFFFA1  CBNZ X1,#-3     (imm19 = -3 → back to ADD)
\ No patch. No stack effects left for caller.
: TLOOP-TO-3,  ( -- )
  0 X0 MOV-X-IMM64,
  ALIGN4-T HERE-T TLOOP-DEST !
  1 X0 X0 ADD-IMM,                 \ n++
  X0 X1 MOV-X-X,                   \ X1 = n
  3 X1 X1 SUB-IMM,                 \ X1 = n - 3
  ALIGN4-T
  TLOOP-DEST @ HERE-T - 4 /        \ imm19 = (head - cbnz) / 4  (= -3)
  X1 SWAP CBNZ-X,
  ;

\ ----- local labels 0..15 -----
16 CONSTANT #LLAB
CREATE LL-POS  #LLAB CELLS ALLOT
CREATE LL-FWD  #LLAB CELLS ALLOT

: LL-INIT  ( -- )
  0 BEGIN DUP #LLAB < WHILE
    -1 OVER CELLS LL-POS + !
    -1 OVER CELLS LL-FWD + !
    1+
  REPEAT DROP
  ;

\ Note: cannot be named L: — that is 64DIR library define. Use LL: / BR>LL.
: LL:  ( n -- )   \ define local label n at HERE-T
  DUP #LLAB U>= IF S" label 0..15" TCOM-ABORT THEN
  A64-T !
  HERE-T A64-T @ CELLS LL-POS + !
  A64-T @ CELLS LL-FWD + @
  DUP -1 <> IF
    HERE-T SWAP PATCH-B
    -1 A64-T @ CELLS LL-FWD + !
  ELSE DROP THEN
  ;

: BR>LL  ( n -- )  \ B to local label n (back or one forward site)
  DUP #LLAB U>= IF S" label 0..15" TCOM-ABORT THEN
  A64-T !
  ALIGN4-T
  A64-T @ CELLS LL-POS + @
  DUP -1 = IF
    DROP
    HERE-T  0 B-IMM,
    A64-T @ CELLS LL-FWD + !
  ELSE
    HERE-T - 4 / B-IMM,
  THEN
  ;

\ ----- Forth ABI helpers -----
: LIT-PUSH-X0,  ( n -- )
  X0 X19 -8 STR-PRE,
  X0 MOV-X-IMM64,
  ;

: LIT-X0,  ( n -- )  X0 MOV-X-IMM64, ;

4096 CONSTANT #RSTACK                     \ Forth RP bytes below DSP

: DSP-INIT,  ( host-dsp-top -- )
  \ X19 = DSP; X20 = RP (same gap as SIM #SIM-RSTACK)
  DUP X19 MOV-X-IMM64,
  #RSTACK - X20 MOV-X-IMM64,
  0 X0 MOV-X-IMM64,
  ;

\ ----- DO / LOOP / +LOOP / I / J (RP = X20; bias = 1<<63) -----
$444F0001 CONSTANT DO-SYS                 \ TCS marker

: TDO  ( -- )
  \ ( limit index -- )  X0=index, [X19]=limit
  X0 X1 MOV-X-X,                         \ X1 = index
  X2 X19 8 LDR-POST,                     \ X2 = limit; drop
  X0 X19 8 LDR-POST,                     \ new TOS
  $8000000000000000 X3 MOV-X-IMM64,      \ bias
  X3 X2 X2 ADD-X-X,                      \ limit'
  X2 X1 X1 SUB-X-X,                      \ index' = index - limit'
  X2 X20 -8 STR-PRE,                     \ push limit'
  X1 X20 -8 STR-PRE,                     \ push index'
  ALIGN4-T HERE-T TCS-PUSH               \ loop head
  DO-SYS TCS-PUSH
  ;

: TLOOP  ( -- )
  TCS-POP DO-SYS <> IF S" LOOP without DO" TCOM-ABORT THEN
  TCS-POP >R                             \ dest
  X1 X20 0 LDR-OFF,                      \ index'  (LDR Xt,[Xn,#0])
  1 X2 MOV-X-IMM64,
  X2 X1 X1 ADDS-X,                       \ index' += 1
  X1 X20 0 STR-OFF,
  ALIGN4-T
  R@ HERE-T - 4 / VC B.COND,             \ continue if no overflow
  16 X20 X20 ADD-IMM,                    \ UNLOOP
  R> DROP
  ;

: T+LOOP  ( -- )
  TCS-POP DO-SYS <> IF S" +LOOP without DO" TCOM-ABORT THEN
  TCS-POP >R
  X0 X1 MOV-X-X,                         \ n
  X0 X19 8 LDR-POST,                     \ drop n
  X2 X20 0 LDR-OFF,                      \ index'
  X1 X2 X2 ADDS-X,                       \ index' += n
  X2 X20 0 STR-OFF,
  ALIGN4-T
  R@ HERE-T - 4 / VC B.COND,
  16 X20 X20 ADD-IMM,
  R> DROP
  ;

: TI,  ( -- )
  X0 X19 -8 STR-PRE,
  X1 X20 0 LDR-OFF,                      \ index'
  X2 X20 8 LDR-OFF,                      \ limit'
  X2 X1 X0 ADD-X-X,                      \ I
  ;

: TJ,  ( -- )
  X0 X19 -8 STR-PRE,
  X1 X20 16 LDR-OFF,                     \ outer index'
  X2 X20 24 LDR-OFF,                     \ outer limit'
  X2 X1 X0 ADD-X-X,
  ;

: .ASMARM64  ( -- )
  S" ASMARM64 3.1+: X0-X30 AND/ORR/EOR ADD/SUB CMP B/BL/B.cond CBZ" TYPE CR
  S"   LL: BR>LL  AHEAD THEN, AIF, AELSE, ATHEN,  CALL-ABS" TYPE CR
  S"   Forth-ABI: TIF…  TBEGIN…  TDO TLOOP T+LOOP TI, TJ,  T0=," TYPE CR
  ;

: (SETASSEM)  ( -- )
  TRUE TO ?ASM-ACTIVE
  ALSO ASMARM64 DEFINITIONS
  LL-INIT
  ;
' (SETASSEM) IS SETASSEM

: (A;)  ( -- )  ;
' (A;) IS A;

: (END-CODE)  ( -- )
  ?ASM-ACTIVE IF PREVIOUS FORTH DEFINITIONS FALSE TO ?ASM-ACTIVE THEN
  ;
' (END-CODE) IS END-CODE

: C;  ( -- )  END-CODE ; IMMEDIATE

FORTH DEFINITIONS
LL-INIT
S" ASMARM64 loaded (3.1 richer assembler)." TYPE CR
