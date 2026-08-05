\ ASMARM64.fth — Minimal AArch64 assembler for 64TCOMARM64
\
\ Public domain. Requires 64HOST.fth.
\ Little-endian A64 32-bit instructions into target CODE via C,-T / W,.
\
\ ABI (Phase 3.0c subroutine-threaded):
\   X0  = TOS (top of data stack)
\   X19 = DSP (points at next free cell toward lower addresses; push pre-dec)
\   X1  = scratch in primitives
\   X16 = call scratch (LDR/BLR absolute)
\   X30 = link (BLR / RET)

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

: W,  ( u32 -- )
  DUP $FF AND C,-T
  8 RSHIFT DUP $FF AND C,-T
  8 RSHIFT DUP $FF AND C,-T
  8 RSHIFT $FF AND C,-T
  ;

: ALIGN4-T  ( -- )
  BEGIN HERE-T 3 AND WHILE  0 C,-T  REPEAT
  ;

: X0   0 ;  : X1   1 ;  : X16 16 ;  : X19 19 ;  : X30 30 ;

: NOP,   ( -- )  $D503201F W, ;
: RET,   ( -- )  $D65F03C0 W, ;
: RET-X, ( xn -- )  $1F AND 5 LSHIFT $D65F0000 OR W, ;
: BLR-X, ( xn -- )  $1F AND 5 LSHIFT $D63F0000 OR W, ;
: BR-X,  ( xn -- )  $1F AND 5 LSHIFT $D61F0000 OR W, ;

VARIABLE A64-I
VARIABLE A64-D
VARIABLE A64-H
VARIABLE A64-N
VARIABLE A64-M

: MOVZ-X,  ( imm16 xd hw -- )
  A64-H !  A64-D !  A64-I !
  A64-H @ 3 U> IF  S" MOVZ hw 0..3" TCOM-ABORT  THEN
  $D2800000
  A64-H @ 21 LSHIFT OR
  A64-I @ $FFFF AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

: MOVK-X,  ( imm16 xd hw -- )
  A64-H !  A64-D !  A64-I !
  A64-H @ 3 U> IF  S" MOVK hw 0..3" TCOM-ABORT  THEN
  $F2800000
  A64-H @ 21 LSHIFT OR
  A64-I @ $FFFF AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

: MOV-X-IMM64,  ( imm64 xd -- )
  $1F AND A64-D !
  DUP $FFFF AND            A64-D @ 0 MOVZ-X,
  DUP 16 RSHIFT $FFFF AND  A64-D @ 1 MOVK-X,
  DUP 32 RSHIFT $FFFF AND  A64-D @ 2 MOVK-X,
      48 RSHIFT $FFFF AND  A64-D @ 3 MOVK-X,
  ;

\ MOV Xd, Xm  (ORR Xd, XZR, Xm)  64-bit
: MOV-X-X,  ( xm xd -- )
  A64-D !  A64-M !
  $AA0003E0
  A64-M @ $1F AND 16 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ ADD Xd, Xn, Xm
: ADD-X-X,  ( xm xn xd -- )
  A64-D !  A64-N !  A64-M !
  $8B000000
  A64-M @ $1F AND 16 LSHIFT OR
  A64-N @ $1F AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ SUB Xd, Xn, Xm
: SUB-X-X,  ( xm xn xd -- )
  A64-D !  A64-N !  A64-M !
  $CB000000
  A64-M @ $1F AND 16 LSHIFT OR
  A64-N @ $1F AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ 9-bit signed imm helper → imm9 field
: (IMM9)  ( n -- imm9 )
  DUP 0< IF  $200 +  THEN  $1FF AND
  ;

\ STR Xt, [Xn, #simm]!   pre-index writeback  (64-bit)
: STR-PRE,  ( xt xn simm -- )
  (IMM9) A64-I !
  A64-N !
  A64-D !
  $F8000C00
  A64-I @ 12 LSHIFT OR
  A64-N @ $1F AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ LDR Xt, [Xn], #simm   post-index writeback  (64-bit)
: LDR-POST,  ( xt xn simm -- )
  (IMM9) A64-I !
  A64-N !
  A64-D !
  $F8400400
  A64-I @ 12 LSHIFT OR
  A64-N @ $1F AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ LDR Xt, [Xn]   unsigned offset 0
: LDR-X0,  ( xt xn -- )
  A64-N !  A64-D !
  $F9400000
  A64-N @ $1F AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ STR Xt, [Xn]   unsigned offset 0
: STR-X0,  ( xt xn -- )
  A64-N !  A64-D !
  $F9000000
  A64-N @ $1F AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

\ LDR Xt, PC+8 literal (imm19=2)
: LDR64-PC+8,  ( xn -- )
  $1F AND  $58000000 OR  2 5 LSHIFT OR  W,
  ;

: CALL-ABS-PREP,  ( -- )
  ALIGN4-T
  X16 LDR64-PC+8,
  X16 BLR-X,
  ;

\ taddr → host address in .quad so BLR works if code runs from T-CODE-BASE mapping
: CALL-ABS,  ( taddr -- )
  CALL-ABS-PREP,
  THERE ,-T
  ;

: JMP-ABS,  ( taddr -- )
  ALIGN4-T
  X16 LDR64-PC+8,
  X16 BR-X,
  THERE ,-T
  ;

\ Push old TOS (X0) then load literal into X0
: LIT-PUSH-X0,  ( n -- )
  X0 X19 -8 STR-PRE,              \ str x0, [x19, #-8]!
  X0 MOV-X-IMM64,                 \ mov x0, #n
  ;

: LIT-X0,  ( n -- )  X0 MOV-X-IMM64, ;   \ replace TOS only (no push)

\ DSP init: X19 = host address of data-stack top (grows down)
: DSP-INIT,  ( host-dsp-top -- )
  X19 MOV-X-IMM64,
  0 X0 MOV-X-IMM64,               \ empty TOS
  ;

\ CBNZ/CBZ Xt, imm19 (word offset from this instruction)
: CBNZ-X,  ( xt imm19 -- )
  A64-I !   A64-D !
  $B5000000
  A64-I @ $7FFFF AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

: CBZ-X,  ( xt imm19 -- )
  A64-I !   A64-D !
  $B4000000
  A64-I @ $7FFFF AND 5 LSHIFT OR
  A64-D @ $1F AND OR  W,
  ;

: .ASMARM64  ( -- )
  S" ASMARM64: ABI X0=TOS X19=DSP; CALL-ABS; CBNZ/CBZ" TYPE CR
  ;

FORTH DEFINITIONS
S" ASMARM64 loaded." TYPE CR
