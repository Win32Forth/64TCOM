\ ASMARM64.fth — Minimal AArch64 assembler for 64TCOMARM64
\
\ Public domain. Requires 64HOST.fth.
\ Little-endian A64 fixed-length 32-bit instructions into T-CODE via C,-T.
\
\ First milestone: enough to emit RET, NOP, BLR Xn, LDR literal+quad,
\ and MOVZ/MOVK materialization of 64-bit immediates.

TCOM-ANEW ASMARM64

FORTH DEFINITIONS
DECIMAL

VOCABULARY ASMARM64
: [ASMARM64]  ( -- )  ASMARM64 ; IMMEDIATE

FALSE VALUE ?ASM-ACTIVE

: (SETASSEM)  ( -- )
  TRUE TO ?ASM-ACTIVE
  ALSO ASMARM64 DEFINITIONS
  ;
' (SETASSEM) IS SETASSEM

: (A;)  ( -- )  ;
' (A;) IS A;

: (END-CODE)  ( -- )
  ?ASM-ACTIVE IF  PREVIOUS FORTH DEFINITIONS  FALSE TO ?ASM-ACTIVE  THEN
  ;
' (END-CODE) IS END-CODE

: C;  ( -- )  END-CODE ; IMMEDIATE

\ -----------------------------------------------------------------------------
\ Emit 32-bit LE instruction word
\ -----------------------------------------------------------------------------

: W,  ( u32 -- )
  DUP $FF AND C,-T
  8 RSHIFT DUP $FF AND C,-T
  8 RSHIFT DUP $FF AND C,-T
  8 RSHIFT $FF AND C,-T
  ;

: ALIGN4-T  ( -- )
  BEGIN HERE-T 3 AND WHILE  0 C,-T  REPEAT
  ;

\ -----------------------------------------------------------------------------
\ Core instructions (Xn = 0..30; 31 = XZR/SP as appropriate)
\ -----------------------------------------------------------------------------

: NOP,   ( -- )  $D503201F W, ;
: RET,   ( -- )  $D65F03C0 W, ;          \ RET X30
: RET-X, ( xn -- )  $D65F0000 OR  5 LSHIFT OR  W, ;
: BLR-X, ( xn -- )  $D63F0000 SWAP 5 LSHIFT OR W, ;
: BR-X,  ( xn -- )  $D61F0000 SWAP 5 LSHIFT OR W, ;

VARIABLE A64-I
VARIABLE A64-D
VARIABLE A64-H

\ MOVZ Xd, #imm16, LSL #(hw*16)   hw = 0..3
\ Encoding: sf=1 opc=10 100101 hw:2 imm16:16 Rd:5 → base $D2800000
: MOVZ-X,  ( imm16 xd hw -- )
  A64-H !
  A64-D !
  A64-I !
  A64-H @ 3 U> IF  S" MOVZ hw must be 0..3" TCOM-ABORT  THEN
  $D2800000
  A64-H @ 21 LSHIFT OR
  A64-I @ $FFFF AND 5 LSHIFT OR
  A64-D @ $1F AND OR
  W,
  ;

\ MOVK Xd, #imm16, LSL #(hw*16)
: MOVK-X,  ( imm16 xd hw -- )
  A64-H !
  A64-D !
  A64-I !
  A64-H @ 3 U> IF  S" MOVK hw must be 0..3" TCOM-ABORT  THEN
  $F2800000
  A64-H @ 21 LSHIFT OR
  A64-I @ $FFFF AND 5 LSHIFT OR
  A64-D @ $1F AND OR
  W,
  ;

\ Materialize full 64-bit imm into Xd (4 instructions)
: MOV-X-IMM64,  ( imm64 xd -- )
  $1F AND A64-D !
  DUP $FFFF AND               A64-D @ 0 MOVZ-X,
  DUP 16 RSHIFT $FFFF AND     A64-D @ 1 MOVK-X,
  DUP 32 RSHIFT $FFFF AND     A64-D @ 2 MOVK-X,
      48 RSHIFT $FFFF AND     A64-D @ 3 MOVK-X,
  ;

\ LDR Xt, label — 64-bit literal load, imm19 = byte_offset/4 from this insn
\ We use a fixed pattern: LDR Xn, +8 ; BLR Xn ; .quad target
\ imm19 = 2 for +8 bytes
: LDR64-PC+8,  ( xn -- )
  $1F AND
  $58000000 OR
  2 5 LSHIFT OR                    \ imm19 = 2
  W,
  ;

\ Call sequence with patchable 8-byte absolute address at HERE-T after emit:
\   LDR X16, [PC+8]
\   BLR X16
\   .quad addr          ← COMP-CALL leaves this cell; RESOLVE-1 patches it
\
\ After CALL-ABS, HERE-T points past the quad if we ,-T inside.
: X16  ( -- n )  16 ;

: CALL-ABS-PREP,  ( -- )
  \ emit LDR+BLR; next 8 bytes are address cell
  ALIGN4-T
  X16 LDR64-PC+8,
  X16 BLR-X,
  ;

: CALL-ABS,  ( addr -- )
  CALL-ABS-PREP,
  ,-T                              \ 8-byte absolute target
  ;

\ Literal into X0 (demo / COMP-SINGLE): MOV sequence only
: LIT-X0,  ( n -- )
  0 MOV-X-IMM64,                   \ xd = 0
  ;

: .ASMARM64  ( -- )
  S" ASMARM64: AArch64 emitters W, NOP, RET, BLR-X, MOV-X-IMM64, CALL-ABS" TYPE CR
  ;

FORTH DEFINITIONS
S" ASMARM64 loaded." TYPE CR
