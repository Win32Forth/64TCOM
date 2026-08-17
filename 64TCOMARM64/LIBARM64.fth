\ LIBARM64.fth — ARM64 target library with real primitive bodies
\
\ Public domain. Requires 64HOST, 64DIR, ASMARM64, OPTARM64.
\ ABI: X0 = TOS, X19 = DSP. Cells = 8 bytes. Prims end with RET.
\ Body words are named BODY-* (no leading paren — avoids ' and ( clash).

TCOM-ANEW LIBARM64

FORTH DEFINITIONS
DECIMAL

T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN

VARIABLE LIB-PRIM-COUNT
0 LIB-PRIM-COUNT !

\ LIB-SYM-N is defined in OPTARM64 — do not redefine here.

FALSE VALUE LIB-VERBOSE
: LIB-VERBOSE-ON   ( -- )  TRUE  TO LIB-VERBOSE ;
: LIB-VERBOSE-OFF  ( -- )  FALSE TO LIB-VERBOSE ;

VARIABLE LIB-I
VARIABLE LIB-CA
VARIABLE LIB-U
VARIABLE LIB-CK
VARIABLE LIB-BODY-XT

: LIB-PRIM-XT  ( body-xt -- )  \ name follows in input
  LIB-BODY-XT !
  HOST-DEFS
  ALIGN4-T
  HERE-T LIB-CK !
  LIB-BODY-XT @ EXECUTE
  RET,
  LIB-CK @ CONSTANT
  SYM-N @ LIB-I !
  LAST NAME>STRING LIB-U ! LIB-CA !
  LIB-CA @ LIB-U @ LIB-I @ SYM-PUT-NAME
  SYM-LIBRARY LIB-I @ SYM-TYPE!
  LIB-CK @ LIB-I @ SYM-ADDR!
  0 LIB-I @ SYM-USES!
  1 SYM-N +!
  LIB-VERBOSE IF
    S" LIB " TYPE LIB-CA @ LIB-U @ TYPE S"  @ " TYPE LIB-CK @ SYM-HEX. CR
  THEN
  1 LIB-PRIM-COUNT +!
  FORTH-DEFS
  ;

: BODY-NOOP   ( -- )  BTI, ;
: BODY-EXIT   ( -- )  BTI, ;
: BODY-STUB   ( -- )  BTI, ;

: BODY-DUP    ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  ;

: BODY-DROP   ( -- )
  BTI,
  X0 X19 8 LDR-POST,
  ;

: BODY-SWAP   ( -- )
  BTI,
  X1 X19 0 LDR-X0,
  X0 X19 0 STR-X0,
  X1 X0 MOV-X-X,
  ;

: BODY-OVER   ( -- )
  BTI,
  X1 X19 0 LDR-X0,
  X0 X19 -8 STR-PRE,
  X1 X0 MOV-X-X,
  ;

: BODY-PLUS   ( -- )
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 X0 ADD-X-X,
  ;

: BODY-MINUS  ( -- )
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 X0 SUB-X-X,
  ;

: BODY-FETCH  ( -- )
  BTI,
  X0 X0 LDR-X0,
  ;

: BODY-STORE  ( -- )
  BTI,
  X1 X19 8 LDR-POST,
  X1 X0 STR-X0,
  X0 X19 8 LDR-POST,
  ;

\ TYPE# ( c-addr u -- )  write(1, c-addr, u) via Darwin write syscall
\ Entry: X0=u, [X19]=c-addr. Exit: both consumed; new TOS from under.
: BODY-TYPE  ( -- )
  BTI,
  X0 X2 MOV-X-X,              \ X2 = length
  X1 X19 8 LDR-POST,          \ X1 = c-addr
  1 X0 MOV-X-IMM64,           \ X0 = STDOUT_FILENO
  4 X16 MOV-X-IMM64,          \ X16 = SYS_write (BSD/Darwin)
  $80 SVC,                    \ svc #0x80
  X0 X19 8 LDR-POST,          \ restore previous TOS
  ;

VARIABLE ARG-P1
VARIABLE ARG-P2
VARIABLE ARG-P3
VARIABLE ARG-P4

\ ARG## ( n base -- c-addr u )
\ n = 1-based user arg; base = abs addr of arg table (daddr 8).
\ argc at base-8. Invalid → (base, 0). Memory: counted string [len][chars].
: BODY-ARGNUM  ( -- )
  BTI,
  X0 X1 MOV-X-X,                 \ X1 = table base
  X0 X19 8 LDR-POST,             \ X0 = n
  8 X1 X2 SUB-IMM,
  X2 X2 LDR-X0,                  \ X2 = argc
  \ n == 0 → empty
  ALIGN4-T HERE-T ARG-P1 !
  X0 0 CBZ-X,
  \ n > 16 → empty  (CMP X0,#16; B.HI)
  16 X3 MOV-X-IMM64,
  X3 X0 CMP-X,
  ALIGN4-T HERE-T ARG-P2 !
  0 HI B.COND,
  \ n > argc → empty
  X2 X0 CMP-X,
  ALIGN4-T HERE-T ARG-P3 !
  0 HI B.COND,
  \ valid: c-addr u from counted string at base+(n-1)*256
  1 X0 X0 SUB-IMM,
  8 X0 X0 LSL-IMM,
  X0 X1 X3 ADD-X-X,              \ X3 → counted
  X0 X3 LDRB-X,                  \ X0 = len
  1 X3 X3 ADD-IMM,               \ X3 = body
  X3 X19 -8 STR-PRE,             \ push c-addr; TOS = len
  AHEAD ARG-P4 !
  \ empty:
  HERE-T ARG-P1 @ PATCH-CBZ
  HERE-T ARG-P2 @ PATCH-BCOND
  HERE-T ARG-P3 @ PATCH-BCOND
  X1 X19 -8 STR-PRE,             \ dummy c-addr = base
  0 X0 MOV-X-IMM64,              \ u = 0
  ARG-P4 @ THEN,
  ;

\ BRANCH# ( taddr -- ) tail BR to image_base+taddr (relocatable; no host bake-in)
: BODY-BRANCH  ( -- )
  BTI,
  (TADDR-BR,)
  ;

\ ZBRANCH# ( flag dest -- )  TOS=dest, under=flag
\ if flag <> 0: drop dest, continue; if flag = 0: BR to dest
\ Branch path: ADR + 4*MOVZ/K + SUB + ADD + BR = 8 insns → CBNZ #9
: BODY-ZBRANCH  ( -- )
  BTI,
  X1 X19 8 LDR-POST,             \ X1=flag, X0=dest taddr
  X1 9 CBNZ-X,                   \ non-zero: skip branch block
  (TADDR-BR,)
  X0 X19 8 LDR-POST,             \ drop dest on fall-through
  ;

' BODY-STUB    LIB-PRIM-XT LIT#
' BODY-EXIT    LIB-PRIM-XT EXIT#
' BODY-EXIT    LIB-PRIM-XT UNNEST#
' BODY-BRANCH  LIB-PRIM-XT BRANCH#
' BODY-ZBRANCH LIB-PRIM-XT ZBRANCH#
' BODY-FETCH   LIB-PRIM-XT FETCH#
' BODY-STORE   LIB-PRIM-XT STORE#
' BODY-DUP     LIB-PRIM-XT DUP#
' BODY-DROP    LIB-PRIM-XT DROP#
' BODY-SWAP    LIB-PRIM-XT SWAP#
' BODY-OVER    LIB-PRIM-XT OVER#
' BODY-PLUS    LIB-PRIM-XT PLUS#
' BODY-MINUS   LIB-PRIM-XT MINUS#
' BODY-TYPE    LIB-PRIM-XT TYPE#
' BODY-ARGNUM  LIB-PRIM-XT ARG##
' BODY-STUB    LIB-PRIM-XT EXEC#
' BODY-NOOP    LIB-PRIM-XT NOOP#

HERE-T LIB-CODE-END !
SYM-N @ LIB-SYM-N !
?QUIET 0= IF
  S" LIB-CODE-END=" TYPE LIB-CODE-END @ SYM-HEX. CR
THEN

: .LIBARM64  ( -- )
  S" LIBARM64: " TYPE LIB-PRIM-COUNT @ 0 .R
  S"  prims. LIB-CODE-END=" TYPE LIB-CODE-END @ SYM-HEX. CR
  ;

FORTH DEFINITIONS
>FORTH
S" LIBARM64: " TYPE LIB-PRIM-COUNT @ 0 .R S"  real prims ready." TYPE CR
