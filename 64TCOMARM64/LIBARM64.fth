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
[DEFINED] HOST-RELOC-CLEAR [IF] HOST-RELOC-CLEAR [THEN]

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
  X1 X19 LDR-X0,                 \ X1 = under
  X0 X19 STR-X0,                 \ under = old TOS
  X1 X0 MOV-X-X,                 \ TOS = old under
  ;

: BODY-OVER   ( -- )
  BTI,
  X1 X19 LDR-X0,                 \ X1 = under
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

VARIABLE ARG-P1
VARIABLE ARG-P2
VARIABLE ARG-P3
VARIABLE ARG-P4
VARIABLE IO-P1
VARIABLE IO-P2
VARIABLE IO-P3
VARIABLE IO-P4

\ write: X3=fd, TOS=u, under=c-addr → consume both, restore under
: (BODY-WRITE-FD)  ( -- )
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X3 X0 MOV-X-X,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,
  ;

\ TYPE# ( c-addr u -- ) host slot 11 → grid (GUI) or stdout (CLI)
: BODY-TYPE  ( -- )
  BTI,
  X0 X2 MOV-X-X,                     \ X2 = u
  X1 X19 8 LDR-POST,                 \ X1 = c-addr; [X19]=new TOS
  X0 X19 LDR-X0,                     \ peek new TOS
  X0 X19 -8 STR-PRE,                 \ save TOS
  X1 X0 MOV-X-X,                     \ X0 = c-addr
  X2 X1 MOV-X-X,                     \ X1 = u
  11 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

: BODY-ETYPE  ( -- )
  BTI,  2 X3 MOV-X-IMM64,  (BODY-WRITE-FD)  ;

: BODY-WRITE  ( -- )
  BTI,
  X0 X3 MOV-X-X,
  X0 X19 8 LDR-POST,
  (BODY-WRITE-FD)
  ;

\ READ# ( c-addr u fd -- n )  Darwin: CS set ⇒ error → 0
: BODY-READ  ( -- )
  BTI,
  X0 X3 MOV-X-X,
  X2 X19 8 LDR-POST,
  X1 X19 8 LDR-POST,
  X3 X0 MOV-X-X,
  3 X16 MOV-X-IMM64,
  $80 SVC,
  ALIGN4-T HERE-T IO-P1 !
  0 CS B.COND,
  AHEAD IO-P2 !
  HERE-T IO-P1 @ PATCH-BCOND
  0 X0 MOV-X-IMM64,
  IO-P2 @ THEN,
  ;

\ KEY# ( -- c | -1 ) host slot 7 (GUI key queue / CLI stdin)
: BODY-KEY  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,                 \ save prior TOS
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  7 HOST-CALL,                       \ result in X0
  ;

\ ACCEPT# ( c-addr u1 -- u2 )
: BODY-ACCEPT  ( -- )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X1 X4 MOV-X-X,
  X2 X5 MOV-X-X,
  X4 X1 MOV-X-X,
  X5 X2 MOV-X-X,
  0 X0 MOV-X-IMM64,
  3 X16 MOV-X-IMM64,
  $80 SVC,
  ALIGN4-T HERE-T IO-P1 !
  0 CS B.COND,
  XZR X0 CMP-X,
  ALIGN4-T HERE-T IO-P4 !
  0 EQ B.COND,
  X0 X2 MOV-X-X,
  1 X0 X3 SUB-IMM,
  X3 X4 X6 ADD-X-X,
  X1 X6 LDRB-X,
  10 X5 MOV-X-IMM64,
  X5 X1 CMP-X,
  ALIGN4-T HERE-T IO-P3 !
  0 NE B.COND,
  X3 X0 MOV-X-X,
  HERE-T IO-P3 @ PATCH-BCOND
  AHEAD IO-P2 !
  HERE-T IO-P1 @ PATCH-BCOND
  HERE-T IO-P4 @ PATCH-BCOND
  0 X0 MOV-X-IMM64,
  IO-P2 @ THEN,
  ;

\ OPEN-R# ( c-addr u pathbuf -- fd )  O_RDONLY; -1 fail
: BODY-OPEN-R  ( -- )
  BTI,
  X0 X7 MOV-X-X,                 \ pathbuf
  X2 X19 8 LDR-POST,             \ u
  X1 X19 8 LDR-POST,             \ src
  255 X3 MOV-X-IMM64,
  X3 X2 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 LS B.COND,
  255 X2 MOV-X-IMM64,
  HERE-T IO-P1 @ PATCH-BCOND
  0 X6 MOV-X-IMM64,
  ALIGN4-T HERE-T IO-P2 !
  X6 X2 CMP-X,
  ALIGN4-T HERE-T IO-P3 !
  0 EQ B.COND,
  X1 X6 X4 ADD-X-X,
  X0 X4 LDRB-X,
  X7 X6 X4 ADD-X-X,
  X0 X4 STRB-X,
  1 X6 X6 ADD-IMM,
  IO-P2 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P3 @ PATCH-BCOND
  0 X0 MOV-X-IMM64,
  X7 X6 X4 ADD-X-X,
  X0 X4 STRB-X,                  \ NUL
  X7 X0 MOV-X-X,                 \ path
  0 X1 MOV-X-IMM64,              \ O_RDONLY
  0 X2 MOV-X-IMM64,              \ mode
  5 X16 MOV-X-IMM64,             \ SYS_open
  $80 SVC,
  ALIGN4-T HERE-T IO-P4 !
  0 CS B.COND,
  AHEAD IO-P1 !
  HERE-T IO-P4 @ PATCH-BCOND
  -1 X0 MOV-X-IMM64,
  IO-P1 @ THEN,
  ;

\ OPEN-W# ( c-addr u pathbuf -- fd )  WRONLY|CREAT|TRUNC 0644
: BODY-OPEN-W  ( -- )
  BTI,
  X0 X7 MOV-X-X,
  X2 X19 8 LDR-POST,
  X1 X19 8 LDR-POST,
  255 X3 MOV-X-IMM64,
  X3 X2 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 LS B.COND,
  255 X2 MOV-X-IMM64,
  HERE-T IO-P1 @ PATCH-BCOND
  0 X6 MOV-X-IMM64,
  ALIGN4-T HERE-T IO-P2 !
  X6 X2 CMP-X,
  ALIGN4-T HERE-T IO-P3 !
  0 EQ B.COND,
  X1 X6 X4 ADD-X-X,
  X0 X4 LDRB-X,
  X7 X6 X4 ADD-X-X,
  X0 X4 STRB-X,
  1 X6 X6 ADD-IMM,
  IO-P2 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P3 @ PATCH-BCOND
  0 X0 MOV-X-IMM64,
  X7 X6 X4 ADD-X-X,
  X0 X4 STRB-X,
  X7 X0 MOV-X-X,
  $601 X1 MOV-X-IMM64,           \ O_WRONLY|O_CREAT|O_TRUNC
  $1A4 X2 MOV-X-IMM64,           \ 0644
  5 X16 MOV-X-IMM64,
  $80 SVC,
  ALIGN4-T HERE-T IO-P4 !
  0 CS B.COND,
  AHEAD IO-P1 !
  HERE-T IO-P4 @ PATCH-BCOND
  -1 X0 MOV-X-IMM64,
  IO-P1 @ THEN,
  ;

\ CLOSE# ( fd -- ior )  0 ok; Darwin CS ⇒ errno in X0
: BODY-CLOSE  ( -- )
  BTI,
  6 X16 MOV-X-IMM64,
  $80 SVC,
  ALIGN4-T HERE-T IO-P1 !
  0 CS B.COND,
  0 X0 MOV-X-IMM64,
  AHEAD IO-P2 !
  HERE-T IO-P1 @ PATCH-BCOND
  \ X0 already errno
  IO-P2 @ THEN,
  ;

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
  X1 X19 0 LDR-OFF,              \ X1=b  (c=X0, under b, under a)
  X2 X19 8 LDR-OFF,              \ X2=a at [X19,#8]
  X1 X19 8 STR-OFF,              \ [X19,#8]=b
  X0 X19 0 STR-OFF,              \ [X19]=c
  X2 X0 MOV-X-X,                 \ TOS=a
  ;

: BODY-NIP  ( -- )   \ ( a b -- b )
  BTI,
  8 X19 X19 ADD-IMM,             \ drop under
  ;

: BODY-2DUP  ( -- )  \ ( a b -- a b a b )
  BTI,
  X1 X19 LDR-X0,                 \ X1=a, X0=b
  X1 X19 -8 STR-PRE,
  X0 X19 -8 STR-PRE,
  ;

\ EMIT# ( c -- ) host slot 5 → grid (GUI) or stdout (CLI)
: BODY-EMIT  ( -- )
  BTI,
  X0 X1 MOV-X-X,                 \ X1 = c
  X0 X19 8 LDR-POST,             \ drop c; X0 = prior TOS
  X0 X19 -8 STR-PRE,             \ save TOS across host
  X1 X0 MOV-X-X,                 \ X0 = c
  0 X1 MOV-X-IMM64,
  5 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

\ EEMIT# ( c -- ) write one char to stderr
: BODY-EEMIT  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  X19 X1 MOV-X-X,
  1 X2 MOV-X-IMM64,
  2 X0 MOV-X-IMM64,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,
  ;

\ CR#  newline via host emit (slot 5)
: BODY-CR  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  10 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  5 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

\ ECR#  emit newline to stderr
: BODY-ECR  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  10 X0 MOV-X-IMM64,
  X0 X19 -8 STR-PRE,
  X19 X1 MOV-X-X,
  1 X2 MOV-X-IMM64,
  2 X0 MOV-X-IMM64,
  4 X16 MOV-X-IMM64,
  $80 SVC,
  X0 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  ;

\ SPACE#  blank via host emit (slot 5)
: BODY-SPACE  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  BL X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  5 HOST-CALL,
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

\ DOT# ( n -- ) host slot 13 — signed decimal, no trailing blank
: BODY-DOT  ( -- )
  BTI,
  X0 X1 MOV-X-X,                     \ X1 = n
  X0 X19 8 LDR-POST,                 \ drop n; X0 = prior TOS
  X0 X19 -8 STR-PRE,                 \ save TOS
  X1 X0 MOV-X-X,                     \ X0 = n
  0 X1 MOV-X-IMM64,
  13 HOST-CALL,
  X0 X19 8 LDR-POST,
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
' BODY-TYPE    LIB-PRIM-XT TYPE#
' BODY-ETYPE   LIB-PRIM-XT ETYPE#
' BODY-WRITE   LIB-PRIM-XT WRITE#
' BODY-READ    LIB-PRIM-XT READ#
' BODY-KEY     LIB-PRIM-XT KEY#
' BODY-ACCEPT  LIB-PRIM-XT ACCEPT#
' BODY-OPEN-R  LIB-PRIM-XT OPENR#
' BODY-OPEN-W  LIB-PRIM-XT OPENW#
' BODY-CLOSE   LIB-PRIM-XT CLOSE#
' BODY-ARGNUM  LIB-PRIM-XT ARG##
' BODY-ZEQ     LIB-PRIM-XT ZEQ#
' BODY-EQ      LIB-PRIM-XT EQ#
' BODY-LT      LIB-PRIM-XT LT#
' BODY-GT      LIB-PRIM-XT GT#
' BODY-ROT     LIB-PRIM-XT ROT#
' BODY-NIP     LIB-PRIM-XT NIP#
' BODY-2DUP    LIB-PRIM-XT 2DUP#
' BODY-EMIT    LIB-PRIM-XT EMIT#
' BODY-EEMIT   LIB-PRIM-XT EEMIT#
' BODY-CR      LIB-PRIM-XT CR#
' BODY-ECR     LIB-PRIM-XT ECR#
' BODY-SPACE   LIB-PRIM-XT SPACE#
' BODY-DOT     LIB-PRIM-XT DOT#
' BODY-SNUMBER LIB-PRIM-XT SNUMBER#

\ WINDOW# ( -- )  host slot 0 → tcom_host_window(); preserves TOS
\ GUI shell opens a blank NSWindow; CLI stub returns -1 (no window).
: BODY-WINDOW  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,                 \ save TOS
  0 HOST-CALL,                       \ slot 0
  X0 X19 8 LDR-POST,                 \ restore TOS (ignore host result)
  ;

' BODY-WINDOW  LIB-PRIM-XT WINDOW#

\ APP-NAME# ( c-addr u -- )  host slot 1 → set menu / default window title
: BODY-APP-NAME  ( -- )
  BTI,
  X0 X2 MOV-X-X,                     \ X2 = u
  X1 X19 8 LDR-POST,                 \ X1 = c-addr; [X19] = new TOS
  X0 X19 LDR-X0,                     \ peek new TOS
  X0 X19 -8 STR-PRE,                 \ save TOS across host call
  X1 X0 MOV-X-X,                     \ X0 = c-addr
  X2 X1 MOV-X-X,                     \ X1 = u
  1 HOST-CALL,                       \ slot 1
  X0 X19 8 LDR-POST,                 \ restore TOS
  ;

' BODY-APP-NAME  LIB-PRIM-XT APP-NAME#

\ ----- extra stack/math/memory for TETRA-class sources -----
: BODY-AND  ( -- )
  BTI,  X1 X19 8 LDR-POST,  X0 X1 X0 AND-X,  ;
: BODY-OR  ( -- )
  BTI,  X1 X19 8 LDR-POST,  X0 X1 X0 ORR-X,  ;
: BODY-INVERT  ( -- )
  BTI,  -1 X1 MOV-X-IMM64,  X1 X0 X0 EOR-X,  ;
: BODY-2STAR  ( -- )
  BTI,  X0 X0 X0 ADD-X-X,  ;          \ 2*
: BODY-2SLASH  ( -- )
  BTI,
  $13017C00 X0 (REG) OR X0 (REG) 5 LSHIFT OR W,   \ ASR X0,X0,#1
  ;
: BODY-NEGATE  ( -- )
  BTI,  X0 XZR X0 SUB-X-X,  ;
: BODY-CELLS  ( -- )
  BTI,  3 X0 X0 LSL-IMM,              \ * 8
  ;
: BODY-2FETCH  ( -- )                 \ ( a -- x y )  2@
  BTI,
  X0 X1 MOV-X-X,
  X1 X0 LDR-X0,                       \ x = [a]
  X0 X19 -8 STR-PRE,
  8 X1 X1 ADD-IMM,
  X1 X0 LDR-X0,                       \ y = [a+8]
  ;

\ CMOVE ( src dest u -- )  forward byte copy
: BODY-CMOVE  ( -- )
  BTI,
  X0 X3 MOV-X-X,                      \ u
  X2 X19 8 LDR-POST,                  \ dest
  X1 X19 8 LDR-POST,                  \ src
  X0 X19 8 LDR-POST,                  \ restore TOS
  ALIGN4-T HERE-T IO-P1 !
  X3 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,                        \ u==0 done
  X4 X1 LDRB-X,                       \ X4 = [src]
  X4 X2 STRB-X,                       \ [dest] = X4
  1 X1 X1 ADD-IMM,
  1 X2 X2 ADD-IMM,
  1 X3 X3 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,         \ back
  HERE-T IO-P2 @ PATCH-BCOND
  ;

: BODY-SPACES  ( -- )                 \ ( n -- ) via host emit
  BTI,
  ALIGN4-T HERE-T IO-P1 !
  X0 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 LE B.COND,
  X0 X19 -8 STR-PRE,                  \ save n across host
  BL X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  5 HOST-CALL,
  X0 X19 8 LDR-POST,                  \ restore n
  1 X0 X0 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  X0 X19 8 LDR-POST,                  \ drop n
  ;

' BODY-AND     LIB-PRIM-XT AND#
' BODY-OR      LIB-PRIM-XT OR#
' BODY-INVERT  LIB-PRIM-XT INVERT#
' BODY-2STAR   LIB-PRIM-XT 2STAR#
' BODY-2SLASH  LIB-PRIM-XT 2SLASH#
' BODY-NEGATE  LIB-PRIM-XT NEGATE#
' BODY-CELLS   LIB-PRIM-XT CELLS#
' BODY-2FETCH  LIB-PRIM-XT 2FETCH#
' BODY-CMOVE   LIB-PRIM-XT CMOVE#
' BODY-SPACES  LIB-PRIM-XT SPACES#

\ MOD# ( n1 n2 -- n3 )  rem = n1 - (n1/n2)*n2  (UDIV; ok for TETRA non-neg)
: BODY-MOD  ( -- )
  BTI,
  X1 X19 8 LDR-POST,                  \ X1 = n1, X0 = n2
  X0 X2 MOV-X-X,                      \ X2 = n2
  X2 X1 X3 UDIV-X,                    \ X3 = n1 / n2
  X2 X1 X3 X0 MSUB-X,                 \ X0 = n1 - n3*n2
  ;

' BODY-MOD     LIB-PRIM-XT MOD#

: BODY-DIV  ( -- )                    \ ( n1 n2 -- n1/n2 ) UDIV
  BTI,
  X1 X19 8 LDR-POST,                  \ X1=n1 X0=n2
  X0 X2 MOV-X-X,
  X2 X1 X0 UDIV-X,
  ;

: BODY-1MINUS  ( -- )
  BTI,  1 X0 X0 SUB-IMM,
  ;

: BODY-1PLUS  ( -- )
  BTI,  1 X0 X0 ADD-IMM,
  ;

' BODY-DIV     LIB-PRIM-XT DIV#
' BODY-1MINUS  LIB-PRIM-XT 1MINUS#
' BODY-1PLUS   LIB-PRIM-XT 1PLUS#

\ Return stack via X20 (same RP as DO/LOOP). Nest >R above loop frames.
: BODY-TOR  ( -- )                    \ >R  ( x -- )
  BTI,
  X0 X20 -8 STR-PRE,
  X0 X19 8 LDR-POST,
  ;

: BODY-FROMR  ( -- )                  \ R>  ( -- x )
  BTI,
  X0 X19 -8 STR-PRE,
  X0 X20 8 LDR-POST,
  ;

: BODY-RFETCH  ( -- )                 \ R@  ( -- x )
  BTI,
  X0 X19 -8 STR-PRE,
  X0 X20 0 LDR-OFF,
  ;

' BODY-TOR     LIB-PRIM-XT TOR#
' BODY-FROMR   LIB-PRIM-XT FROMR#
' BODY-RFETCH  LIB-PRIM-XT RFETCH#

\ KEY?# ( -- flag ) host slot 6 — pumps GUI events
\ Pass DSP (X19) in X1 so the host can watch for Forth stack growth.
: BODY-KEYQ  ( -- )
  BTI,
  X19 X1 MOV-X-X,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  6 HOST-CALL,
  ;

\ BYE# — exit process
: BODY-BYE  ( -- )
  BTI,
  0 X0 MOV-X-IMM64,
  1 X16 MOV-X-IMM64,                  \ SYS_exit
  $80 SVC,
  ;

\ AT# ( x y -- ) host slot 2 — DOS cursor (0,0 top-left)
: BODY-AT  ( -- )
  BTI,
  X0 X2 MOV-X-X,                      \ X2 = y
  X1 X19 8 LDR-POST,                  \ X1 = x; [X19]=new TOS
  X0 X19 LDR-X0,                      \ peek new TOS
  X0 X19 -8 STR-PRE,                  \ save TOS
  X1 X0 MOV-X-X,                      \ X0 = x
  X2 X1 MOV-X-X,                      \ X1 = y
  2 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

\ CLS# ( -- ) host slot 3
: BODY-CLS  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  3 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

\ GET-CHAR# ( -- c ) host slot 4 — char at cursor (no advance)
: BODY-GETCHAR  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  4 HOST-CALL,
  ;

\ TONE# ( freq dur -- ) host slot 12
: BODY-TONE  ( -- )
  BTI,
  X0 X2 MOV-X-X,                      \ X2 = dur
  X1 X19 8 LDR-POST,                  \ X1 = freq
  X0 X19 LDR-X0,
  X0 X19 -8 STR-PRE,
  X1 X0 MOV-X-X,                      \ X0 = freq
  X2 X1 MOV-X-X,                      \ X1 = dur
  12 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

\ TIME-RESET# / 10TH-ELAPSED# / TENTHS# — wall clock + event pump (GUI)
: BODY-TIMERST  ( -- )
  BTI,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  8 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;
: BODY-TENTHEL  ( -- )
  BTI,
  X19 X1 MOV-X-X,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  9 HOST-CALL,
  ;
: BODY-TENTHS  ( -- )                 \ ( n -- )
  BTI,
  X0 X1 MOV-X-X,                      \ X1 = n
  X0 X19 8 LDR-POST,                  \ drop n
  X0 X19 -8 STR-PRE,
  X1 X0 MOV-X-X,
  0 X1 MOV-X-IMM64,
  10 HOST-CALL,
  X0 X19 8 LDR-POST,
  ;

' BODY-KEYQ    LIB-PRIM-XT KEYQ#
' BODY-BYE     LIB-PRIM-XT BYE#
' BODY-AT      LIB-PRIM-XT AT#
' BODY-CLS     LIB-PRIM-XT CLS#
' BODY-GETCHAR LIB-PRIM-XT GETCHAR#
' BODY-TONE    LIB-PRIM-XT TONE#
' BODY-TIMERST LIB-PRIM-XT TIMERST#
' BODY-TENTHEL LIB-PRIM-XT TENTHEL#
' BODY-TENTHS  LIB-PRIM-XT TENTHS#

\ UPC# ( c -- c' )  a-z → A-Z
: BODY-UPC  ( -- )
  BTI,
  X0 X1 MOV-X-X,
  [CHAR] a X2 MOV-X-IMM64,
  X2 X1 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 LT B.COND,
  [CHAR] z X2 MOV-X-IMM64,
  X2 X1 CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 GT B.COND,
  32 X0 X0 SUB-IMM,
  HERE-T IO-P1 @ PATCH-BCOND
  HERE-T IO-P2 @ PATCH-BCOND
  ;

' BODY-UPC     LIB-PRIM-XT UPC#

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
