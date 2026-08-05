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
: RET,   ( -- )  $D65F03C0 W, ;
: RET-X, ( xn -- )  (REG) 5 LSHIFT $D65F0000 OR W, ;
: BLR-X, ( xn -- )  (REG) 5 LSHIFT $D63F0000 OR W, ;
: BR-X,  ( xn -- )  (REG) 5 LSHIFT $D61F0000 OR W, ;

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

: CALL-ABS,  ( taddr -- )
  ALIGN4-T
  X16 LDR64-PC+12,
  X16 BLR-X,
  3 B-IMM,
  THERE ,-T
  ;

: JMP-ABS,  ( taddr -- )
  ALIGN4-T
  X16 LDR64-PC+12,
  X16 BR-X,
  3 B-IMM,
  THERE ,-T
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

: L:  ( n -- )   \ define label n at HERE-T
  DUP #LLAB U>= IF S" label 0..15" TCOM-ABORT THEN
  A64-T !
  HERE-T A64-T @ CELLS LL-POS + !
  A64-T @ CELLS LL-FWD + @
  DUP -1 <> IF
    HERE-T SWAP PATCH-B
    -1 A64-T @ CELLS LL-FWD + !
  ELSE DROP THEN
  ;

: BR>L  ( n -- )  \ B to label n (back or one forward site)
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

: DSP-INIT,  ( host-dsp-top -- )
  X19 MOV-X-IMM64,
  0 X0 MOV-X-IMM64,
  ;

: .ASMARM64  ( -- )
  S" ASMARM64 3.1: X0-X30 AND/ORR/EOR ADD/SUB CMP B/BL/B.cond CBZ" TYPE CR
  S"   L: BR>L  AHEAD THEN, AIF, AELSE, ATHEN,  CALL-ABS" TYPE CR
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
