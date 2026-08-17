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

: BODY-MUL  ( -- )
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 X0 MUL-X,                \ X0 = X1 * X0
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
' BODY-MUL     LIB-PRIM-XT MUL#
\ ----- compares: leave 0 or 1 (TIF treats any non-zero as true) -----
: BODY-ZEQ  ( -- )   \ 0=  ( n -- flag )
  BTI,
  T0=,
  ;

: BODY-EQ  ( -- )    \ =  ( n1 n2 -- flag )
  BTI,
  X1 X19 8 LDR-POST,             \ X1=n1, X0=n2
  X0 X1 CMP-X,
  EQ X0 CSET-X,
  ;

: BODY-LT  ( -- )    \ <  signed
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,                   \ CMP n1, n2
  LT X0 CSET-X,
  ;

: BODY-GT  ( -- )    \ >  signed
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  GT X0 CSET-X,
  ;

\ ----- stack -----
: BODY-ROT  ( -- )   \ ( a b c -- b c a )
  BTI,
  X1 X19 0 LDR-X0,               \ X1=b  (c=X0, under b, under a)
  X2 X19 8 LDR-X0,               \ X2=a at [X19,#8]
  X1 X19 8 STR-X0,               \ [X19,#8]=b
  X0 X19 0 STR-X0,               \ [X19]=c
  X2 X0 MOV-X-X,                 \ TOS=a
  ;

: BODY-NIP  ( -- )   \ ( a b -- b )
  BTI,
  8 X19 X19 ADD-IMM,             \ drop under
  ;

: BODY-2DUP  ( -- )  \ ( a b -- a b a b )
  BTI,
  X1 X19 0 LDR-X0,               \ X1=a, X0=b
  X1 X19 -8 STR-PRE,
  X0 X19 -8 STR-PRE,
  ;

\ EMIT# ( c -- ) write one char to stdout
: BODY-EMIT  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,             \ store char cell at DSP
  X19 X1 MOV-X-X,                \ X1 → low byte of cell (LE)
  1 X2 MOV-X-IMM64,
  1 X0 MOV-X-IMM64,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,             \ drop char cell; restore TOS
  ;

\ CR#  emit newline
: BODY-CR  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,             \ save TOS
  10 X0 MOV-X-IMM64,
  X0 X19 -8 STR-PRE,
  X19 X1 MOV-X-X,
  1 X2 MOV-X-IMM64,
  1 X0 MOV-X-IMM64,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,             \ drop temp
  X0 X19 8 LDR-POST,             \ restore TOS
  ;

\ SPACE#  emit blank
: BODY-SPACE  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  BL X0 MOV-X-IMM64,
  X0 X19 -8 STR-PRE,
  X19 X1 MOV-X-X,
  1 X2 MOV-X-IMM64,
  1 X0 MOV-X-IMM64,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  ;


VARIABLE DOT-P1
VARIABLE DOT-P2
VARIABLE DOT-P3
VARIABLE DOT-P4
VARIABLE DOT-P5
VARIABLE SN-P0
VARIABLE SN-P1
VARIABLE SN-P2
VARIABLE SN-P3

\ Emit low 8 bits of X0 (clobbers X1,X2,X16)
: (EMIT-X0-BYTE,)  ( -- )
  X0 X19 -8 STR-PRE,
  X19 X1 MOV-X-X,
  1 X2 MOV-X-IMM64,
  1 X0 MOV-X-IMM64,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,
  ;

\ DOT# ( n -- ) signed decimal, no trailing blank
: BODY-DOT  ( -- )
  BTI,
  X0 X2 MOV-X-X,
  0 X4 MOV-X-IMM64,
  0 X3 MOV-X-IMM64,
  ALIGN4-T HERE-T DOT-P1 !
  X2 0 CBNZ-X,
  48 X0 MOV-X-IMM64,
  (EMIT-X0-BYTE,)
  X0 X19 8 LDR-POST,
  AHEAD DOT-P2 !
  HERE-T DOT-P1 @ PATCH-CBZ
  XZR X2 CMP-X,
  ALIGN4-T HERE-T DOT-P3 !
  0 GE B.COND,
  1 X3 MOV-X-IMM64,
  X2 XZR X2 SUB-X-X,
  HERE-T DOT-P3 @ PATCH-BCOND
  ALIGN4-T HERE-T DOT-P4 !
  10 X5 MOV-X-IMM64,
  X5 X2 X6 UDIV-X,
  X5 X2 X6 X7 MSUB-X,
  X7 X0 MOV-X-X,
  X0 X19 -8 STR-PRE,
  1 X4 X4 ADD-IMM,
  X6 X2 MOV-X-X,
  ALIGN4-T
  DOT-P4 @ HERE-T - 4 / X2 SWAP CBNZ-X,   \ back to digit extract
  ALIGN4-T HERE-T DOT-P5 !
  X3 0 CBZ-X,
  45 X0 MOV-X-IMM64,
  (EMIT-X0-BYTE,)
  HERE-T DOT-P5 @ PATCH-CBZ
  ALIGN4-T HERE-T DOT-P1 !
  ALIGN4-T HERE-T DOT-P3 !
  X4 0 CBZ-X,
  X0 X19 8 LDR-POST,
  48 X0 X0 ADD-IMM,
  (EMIT-X0-BYTE,)
  1 X4 X4 SUB-IMM,
  ALIGN4-T
  DOT-P1 @ HERE-T - 4 / B-IMM,            \ back to emit head
  HERE-T DOT-P3 @ PATCH-CBZ
  X0 X19 8 LDR-POST,
  DOT-P2 @ THEN,
  ;

\ SNUMBER# ( c-addr u -- n ) decimal; leading - ; bad/empty → 0
: BODY-SNUMBER  ( -- )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  0 X0 MOV-X-IMM64,
  0 X3 MOV-X-IMM64,
  ALIGN4-T HERE-T SN-P0 !
  X2 0 CBZ-X,
  X4 X1 LDRB-X,
  45 X5 MOV-X-IMM64,
  X5 X4 CMP-X,
  ALIGN4-T HERE-T SN-P1 !
  0 NE B.COND,
  1 X3 MOV-X-IMM64,
  1 X1 X1 ADD-IMM,
  1 X2 X2 SUB-IMM,
  HERE-T SN-P1 @ PATCH-BCOND
  ALIGN4-T HERE-T SN-P2 !
  ALIGN4-T HERE-T SN-P3 !
  X2 0 CBZ-X,
  X4 X1 LDRB-X,
  48 X4 X4 SUB-IMM,
  9 X5 MOV-X-IMM64,
  X5 X4 CMP-X,
  ALIGN4-T HERE-T SN-P1 !
  0 HI B.COND,
  X0 X6 MOV-X-X,
  3 X0 X0 LSL-IMM,
  1 X6 X6 LSL-IMM,
  X6 X0 X0 ADD-X-X,
  X4 X0 X0 ADD-X-X,
  1 X1 X1 ADD-IMM,
  1 X2 X2 SUB-IMM,
  ALIGN4-T
  SN-P2 @ HERE-T - 4 / B-IMM,             \ back to digit scan
  HERE-T SN-P3 @ PATCH-CBZ
  HERE-T SN-P1 @ PATCH-BCOND
  ALIGN4-T HERE-T SN-P1 !
  X3 0 CBZ-X,
  X0 XZR X0 SUB-X-X,                      \ X0 = -X0
  HERE-T SN-P1 @ PATCH-CBZ
  HERE-T SN-P0 @ PATCH-CBZ
  ;

' BODY-TYPE    LIB-PRIM-XT TYPE#
' BODY-ARGNUM  LIB-PRIM-XT ARG##
' BODY-ZEQ     LIB-PRIM-XT ZEQ#
' BODY-EQ      LIB-PRIM-XT EQ#
' BODY-LT      LIB-PRIM-XT LT#
' BODY-GT      LIB-PRIM-XT GT#
' BODY-ROT     LIB-PRIM-XT ROT#
' BODY-NIP     LIB-PRIM-XT NIP#
' BODY-2DUP    LIB-PRIM-XT 2DUP#
' BODY-EMIT    LIB-PRIM-XT EMIT#
' BODY-CR      LIB-PRIM-XT CR#
' BODY-SPACE   LIB-PRIM-XT SPACE#
' BODY-DOT     LIB-PRIM-XT DOT#
' BODY-SNUMBER LIB-PRIM-XT SNUMBER#

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
