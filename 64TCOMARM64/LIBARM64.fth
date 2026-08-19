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
  TWL-FORTH LIB-I @ SYM-W!
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
  X1 X19 8 LDR-POST,                 \ X1 = c-addr; [X19] = remaining TOS
  X1 X0 MOV-X-X,                     \ X0 = c-addr
  X2 X1 MOV-X-X,                     \ X1 = u
  11 HOST-CALL,
  X0 X19 8 LDR-POST,                 \ remaining TOS into X0
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
  X0 XZR X0 SUB-X-X,             \ 0 or -1
  ;

: BODY-NEQ  ( -- )   \ <>  ( n1 n2 -- flag )
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  NE X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-LT  ( -- )    \ <  signed
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,                   \ CMP n1, n2
  LT X0 CSET-X,
  X0 XZR X0 SUB-X-X,             \ 0 or -1
  ;

: BODY-GT  ( -- )    \ >  signed
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  GT X0 CSET-X,
  X0 XZR X0 SUB-X-X,             \ 0 or -1
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
  X0 X19 -8 STR-PRE,             \ a b b
  X1 X19 -8 STR-PRE,             \ a b a b
  ;

\ EMIT# ( c -- ) host slot 5 → grid (GUI) or stdout (CLI)
: BODY-EMIT  ( -- )
  BTI,
  0 X1 MOV-X-IMM64,
  5 HOST-CALL,                   \ X0 = c
  X0 X19 8 LDR-POST,             \ remaining TOS into X0 (LIT left it in memory)
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
  0 X1 MOV-X-IMM64,
  13 HOST-CALL,                      \ X0 = n
  X0 X19 8 LDR-POST,                 \ remaining TOS into X0
  ;

\ STACK-HUD# ( line -- ) host slot 14 — depth + top 4 on row `line`
\ After LIT, remaining stack is already in memory at X19. Draw that,
\ then LDR-POST so TOS lives only in X0. Peek-without-drop left a
\ copy in memory; the next LIT STR-PRE'd a second copy (+1 per HUD).
: BODY-STACKHUD  ( -- )
  BTI,
  X19 X1 MOV-X-X,                    \ X1 = remaining stack (TOS in memory)
  14 HOST-CALL,                      \ X0 = line
  X0 X19 8 LDR-POST,                 \ remaining TOS into X0
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
' BODY-NEQ     LIB-PRIM-XT NEQ#
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
' BODY-STACKHUD LIB-PRIM-XT STACKHUD#
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
  X1 X19 8 LDR-POST,                 \ X1 = c-addr; [X19] = remaining TOS
  X1 X0 MOV-X-X,                     \ X0 = c-addr
  X2 X1 MOV-X-X,                     \ X1 = u
  1 HOST-CALL,
  X0 X19 8 LDR-POST,                 \ remaining TOS into X0
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
: BODY-LSHIFT  ( -- )                 \ ( x u -- x' )
  BTI,
  X1 X19 8 LDR-POST,                  \ x; X0=u
  64 X2 MOV-X-IMM64,
  X2 X0 CMP-X,                        \ CMP u, 64
  ALIGN4-T HERE-T IO-P1 !
  0 LO B.COND,
  0 X0 MOV-X-IMM64,
  ALIGN4-T HERE-T IO-P2 !
  0 B-IMM,
  HERE-T IO-P1 @ PATCH-BCOND
  X0 X1 X0 LSL-X,
  HERE-T IO-P2 @ PATCH-B
  ;
: BODY-RSHIFT  ( -- )                 \ ( x u -- x' ) logical
  BTI,
  X1 X19 8 LDR-POST,
  64 X2 MOV-X-IMM64,
  X2 X0 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 LO B.COND,
  0 X0 MOV-X-IMM64,
  ALIGN4-T HERE-T IO-P2 !
  0 B-IMM,
  HERE-T IO-P1 @ PATCH-BCOND
  X0 X1 X0 LSR-X,
  HERE-T IO-P2 @ PATCH-B
  ;
: BODY-UNLOOP  ( -- )
  BTI,
  16 X20 X20 ADD-IMM,
  ;
: BODY-2SLASH  ( -- )
  BTI,
  \ 64-bit ASR X0,X0,#1 (SBFM). Was 32-bit ASR W0 — 2/ of -2 became
  \ 0xFFFFFFFF, so RROT/LROT coords failed VALID? and looked like a no-op.
  $9341FC00 W,
  ;
: BODY-NEGATE  ( -- )
  BTI,  X0 XZR X0 SUB-X-X,  ;
: BODY-CELLS  ( -- )
  BTI,  3 X0 X0 LSL-IMM,              \ * 8
  ;
: BODY-2FETCH  ( -- )                 \ ( a -- x y )  2@  y=[a+8]
  BTI,
  X0 X1 MOV-X-X,                      \ X1 = a
  X0 X1 LDR-X0,                       \ X0 = [a]
  X0 X19 -8 STR-PRE,
  8 X1 X1 ADD-IMM,
  X0 X1 LDR-X0,                       \ X0 = [a+8]
  ;

: BODY-2STORE  ( -- )                 \ ( x y a -- )  matches 2@
  BTI,
  X1 X19 8 LDR-POST,                  \ y
  X2 X19 8 LDR-POST,                  \ x
  X2 X0 STR-X0,                       \ [a]=x
  8 X0 X3 ADD-IMM,
  X1 X3 STR-X0,                       \ [a+8]=y
  X0 X19 8 LDR-POST,
  ;

: BODY-CELLMINUS  ( -- )
  BTI,  8 X0 X0 SUB-IMM,
  ;

: BODY-COUNT  ( -- )                  \ ( c-addr -- c-addr+1 u )
  BTI,
  X1 X0 LDRB-X,                       \ u
  1 X0 X0 ADD-IMM,
  X0 X19 -8 STR-PRE,
  X1 X0 MOV-X-X,
  ;

: BODY-FILL  ( -- )                   \ ( c-addr u char -- )
  BTI,
  X0 X3 MOV-X-X,                      \ char
  X2 X19 8 LDR-POST,                  \ u
  X1 X19 8 LDR-POST,                  \ c-addr
  X0 X19 8 LDR-POST,                  \ TOS
  ALIGN4-T HERE-T IO-P1 !
  X2 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,
  X3 X1 STRB-X,
  1 X1 X1 ADD-IMM,
  1 X2 X2 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  ;

: BODY-ERASE  ( -- )                  \ ( c-addr u -- )
  BTI,
  X2 X0 MOV-X-X,                      \ u
  X1 X19 8 LDR-POST,                  \ c-addr
  X0 X19 8 LDR-POST,
  0 X3 MOV-X-IMM64,
  ALIGN4-T HERE-T IO-P1 !
  X2 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,
  X3 X1 STRB-X,
  1 X1 X1 ADD-IMM,
  1 X2 X2 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  ;

: BODY-NTRAIL  ( -- )                 \ -TRAILING ( c-addr u -- c-addr u' )
  BTI,
  X1 X19 LDR-X0,                      \ c-addr; TOS=u
  ALIGN4-T HERE-T IO-P1 !
  X0 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,
  X0 X1 X2 ADD-X-X,
  1 X2 X2 SUB-IMM,
  X3 X2 LDRB-X,
  BL X4 MOV-X-IMM64,
  X4 X3 CMP-X,
  ALIGN4-T HERE-T IO-P3 !
  0 NE B.COND,
  1 X0 X0 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P3 @ PATCH-BCOND
  HERE-T IO-P2 @ PATCH-BCOND
  ;

: BODY-SLASHSTR  ( -- )               \ /STRING ( c-addr u n -- c-addr' u' )
  BTI,
  X1 X19 8 LDR-POST,                  \ u
  X2 X19 8 LDR-POST,                  \ c-addr
  X0 X2 X2 ADD-X-X,
  X0 X1 X0 SUB-X-X,
  X2 X19 -8 STR-PRE,
  ;

: BODY-CFETCH  ( -- )                 \ ( addr -- char )
  BTI,
  X0 X0 LDRB-X,
  ;

: BODY-CSTORE  ( -- )                 \ ( char addr -- )
  BTI,
  X1 X19 8 LDR-POST,
  X1 X0 STRB-X,
  X0 X19 8 LDR-POST,
  ;

: BODY-PLUSSTORE  ( -- )              \ ( n addr -- )
  BTI,
  X1 X19 8 LDR-POST,                  \ n
  X2 X0 LDR-X0,                       \ [addr]
  X1 X2 X2 ADD-X-X,
  X2 X0 STR-X0,
  X0 X19 8 LDR-POST,
  ;

: BODY-2DROP  ( -- )
  BTI,
  X0 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  ;

: BODY-XOR  ( -- )
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 X0 EOR-X,
  ;

: BODY-ZLT  ( -- )                    \ 0<
  BTI,
  XZR X0 CMP-X,                       \ CMP X0, #0
  MI X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-ABS  ( -- )
  BTI,
  XZR X0 CMP-X,                       \ CMP X0, #0
  ALIGN4-T HERE-T IO-P1 !
  0 PL B.COND,
  X0 XZR X0 SUB-X-X,
  HERE-T IO-P1 @ PATCH-BCOND
  ;

: BODY-MIN  ( -- )                    \ ( n1 n2 -- min )
  BTI,
  X1 X19 8 LDR-POST,                  \ n1; X0=n2
  X0 X1 CMP-X,                        \ CMP n1, n2
  ALIGN4-T HERE-T IO-P1 !
  0 GE B.COND,                        \ n1 >= n2 keep n2
  X1 X0 MOV-X-X,
  HERE-T IO-P1 @ PATCH-BCOND
  ;

: BODY-MAX  ( -- )
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 LE B.COND,
  X1 X0 MOV-X-X,
  HERE-T IO-P1 @ PATCH-BCOND
  ;

: BODY-PICK  ( -- )                   \ ( xu … x0 u -- xu … x0 xu )
  BTI,
  3 X0 X1 LSL-IMM,                    \ u cells
  X1 X19 X2 ADD-X-X,
  X0 X2 LDR-X0,
  ;

: BODY-2SWAP  ( -- )                  \ ( x1 x2 x3 x4 -- x3 x4 x1 x2 )
  BTI,
  X0 X4 MOV-X-X,                      \ x4
  X1 X19 0 LDR-OFF,                   \ x3
  X2 X19 8 LDR-OFF,                   \ x2
  X3 X19 16 LDR-OFF,                  \ x1
  X2 X0 MOV-X-X,
  X3 X19 0 STR-OFF,
  X4 X19 8 STR-OFF,
  X1 X19 16 STR-OFF,
  ;

: BODY-2OVER  ( -- )                  \ ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
  BTI,
  X1 X19 8 LDR-OFF,                   \ x2
  X2 X19 16 LDR-OFF,                  \ x1
  X0 X19 -8 STR-PRE,                  \ push x4
  X2 X19 -8 STR-PRE,                  \ push x1
  X1 X0 MOV-X-X,
  ;

: BODY-TUCK  ( -- )                   \ ( x1 x2 -- x2 x1 x2 )
  BTI,
  X1 X19 LDR-X0,                      \ x1
  X0 X19 STR-X0,                      \ under = x2
  X1 X19 -8 STR-PRE,
  ;

: BODY-QDUP  ( -- )                   \ ?DUP
  BTI,
  XZR X0 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 EQ B.COND,
  X0 X19 -8 STR-PRE,
  HERE-T IO-P1 @ PATCH-BCOND
  ;

: BODY-ROLL  ( -- )                   \ ( xu … x0 u -- x_{u-1} … x0 xu )
  BTI,
  X0 X1 MOV-X-X,                      \ u
  ALIGN4-T HERE-T IO-P1 !
  X1 0 CBZ-X,                         \ 0 ROLL = DROP u
  3 X1 X2 LSL-IMM,
  X2 X19 X3 ADD-X-X,
  X4 X3 LDR-X0,                       \ xu
  ALIGN4-T HERE-T IO-P2 !             \ slide loop
  X1 XZR CMP-X,
  ALIGN4-T HERE-T IO-P3 !
  0 EQ B.COND,
  1 X1 X1 SUB-IMM,
  3 X1 X5 LSL-IMM,
  X5 X19 X6 ADD-X-X,
  X7 X6 LDR-X0,
  8 X6 X6 ADD-IMM,
  X7 X6 STR-X0,
  IO-P2 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P3 @ PATCH-BCOND
  8 X19 X19 ADD-IMM,
  X4 X0 MOV-X-X,
  ALIGN4-T HERE-T IO-P2 !
  0 B-IMM,
  HERE-T IO-P1 @ PATCH-CBZ
  X0 X19 8 LDR-POST,
  HERE-T IO-P2 @ PATCH-B
  ;

: BODY-DEPTH  ( -- n )                \ host slot 15; (dsp0-X19)/8 then push
  BTI,
  X0 X2 MOV-X-X,
  X19 X1 MOV-X-X,
  0 X0 MOV-X-IMM64,
  15 HOST-CALL,
  X2 X19 -8 STR-PRE,
  ;

: BODY-ZGT  ( -- )                    \ 0>
  BTI,
  XZR X0 CMP-X,
  GT X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-ZNE  ( -- )                    \ 0<>
  BTI,
  XZR X0 CMP-X,
  NE X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-LE  ( -- )                     \ <=
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  LE X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-GE  ( -- )                     \ >=
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  GE X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-ULT  ( -- )                    \ U<
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  LO X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-UGT  ( -- )                    \ U>
  BTI,
  X1 X19 8 LDR-POST,
  X0 X1 CMP-X,
  HI X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

: BODY-WITHIN  ( -- )                 \ ( n1 n2 n3 -- flag )  (n1-n2) U< (n3-n2)
  BTI,
  X1 X19 8 LDR-POST,                  \ n2; X0=n3
  X2 X19 8 LDR-POST,                  \ n1
  X1 X2 X2 SUB-X-X,                   \ n1-n2
  X1 X0 X0 SUB-X-X,                   \ n3-n2
  X0 X2 CMP-X,                        \ CMP n1-n2, n3-n2
  LO X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ;

\ Pictured numeric: BASE/HLD/PIC at fixed daddrs; X16 = tcom_data0 (slot 16)
: (TCOM-DATA0-X16,)  ( -- )
  X1 X20 -8 STR-PRE,                  \ C host clobbers X0–X18
  X0 X20 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  16 HOST-CALL,
  X0 X16 MOV-X-X,
  X0 X20 8 LDR-POST,
  X1 X20 8 LDR-POST,
  ;

: (PIC-HOLD-X1,)  ( -- )              \ HOLD char in X1; uses X16
  (TCOM-DATA0-X16,)
  TCOM-HLD-DADDR X2 MOV-X-IMM64,
  X2 X16 X3 ADD-X-X,
  X4 X3 LDR-X0,
  1 X4 X4 SUB-IMM,
  X4 X3 STR-X0,
  X1 X4 STRB-X,
  ;

: BODY-LTSHARP  ( -- )                \ <#
  BTI,
  (TCOM-DATA0-X16,)
  TCOM-PIC-END X2 MOV-X-IMM64,
  X2 X16 X3 ADD-X-X,
  TCOM-HLD-DADDR X2 MOV-X-IMM64,
  X2 X16 X4 ADD-X-X,
  X3 X4 STR-X0,
  ;

: BODY-HOLD  ( -- )                   \ ( char -- )
  BTI,
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,
  (PIC-HOLD-X1,)
  ;

: BODY-SIGN  ( -- )                   \ ( n -- )
  BTI,
  XZR X0 CMP-X,
  X0 X19 8 LDR-POST,
  ALIGN4-T HERE-T IO-P1 !
  0 PL B.COND,
  45 X1 MOV-X-IMM64,
  (PIC-HOLD-X1,)
  HERE-T IO-P1 @ PATCH-BCOND
  ;

: BODY-SHARPGT  ( -- )                \ ( xd -- c-addr u )
  BTI,
  X0 X19 8 LDR-POST,                  \ drop hi
  (TCOM-DATA0-X16,)
  TCOM-HLD-DADDR X2 MOV-X-IMM64,
  X2 X16 X3 ADD-X-X,
  X1 X3 LDR-X0,                       \ c-addr = HLD
  TCOM-PIC-END X2 MOV-X-IMM64,
  X2 X16 X4 ADD-X-X,
  X1 X4 X0 SUB-X-X,                   \ u
  X1 X19 STR-X0,                      \ replace lo with c-addr
  ;

: BODY-SHARP  ( -- )                  \ ( ud -- ud' ) slot 17 HOLD digit, 18 qhi
  BTI,
  X0 X1 MOV-X-X,                      \ X1 = hi
  X0 X19 LDR-X0,                      \ X0 = lo
  17 HOST-CALL,                       \ X0 = qlo; digit HOLDed
  X0 X19 STR-X0,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  18 HOST-CALL,                       \ X0 = qhi
  ;

: BODY-EXEC  ( -- )                   \ EXECUTE ( xt -- ) xt = taddr
  BTI,
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,                  \ TOS for callee
  (BASE-X16,)
  X1 X16 X16 ADD-X-X,
  (A64-STP-X30-XZR-SP) W,
  X16 BLR-X,
  (A64-LDP-X30-XZR-SP) W,
  ;

: BODY-CATCH  ( -- )                  \ ( i*x xt -- j*x 0 | i*x n )
  BTI,
  X0 X21 MOV-X-X,                     \ xt
  X0 X19 8 LDR-POST,
  (TCOM-DATA0-X16,)
  TCOM-HANDLER-DADDR X2 MOV-X-IMM64,
  X2 X16 X3 ADD-X-X,
  X4 X3 LDR-X0,                       \ prev
  X30 X20 -8 STR-PRE,                 \ CALL-ABS return (LDP)
  X19 X20 -8 STR-PRE,                 \ DSP
  $910003E5 W,                        \ ADD X5, SP, #0
  X5 X20 -8 STR-PRE,                  \ C stack (CALL-ABS STPs)
  X4 X20 -8 STR-PRE,
  X20 X3 STR-X0,
  (BASE-X16,)
  X21 X16 X16 ADD-X-X,
  X16 BLR-X,
  (TCOM-DATA0-X16,)
  TCOM-HANDLER-DADDR X2 MOV-X-IMM64,
  X2 X16 X3 ADD-X-X,
  X4 X20 8 LDR-POST,
  X4 X3 STR-X0,
  X5 X20 8 LDR-POST,                  \ discard saved SP
  X19 X20 8 LDR-POST,                 \ discard saved DSP
  X30 X20 8 LDR-POST,                 \ CALL-ABS LDP
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  ;

: BODY-THROW  ( -- )                  \ ( n -- | n )
  BTI,
  XZR X0 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 NE B.COND,
  X0 X19 8 LDR-POST,
  ALIGN4-T HERE-T IO-P2 !
  0 B-IMM,
  HERE-T IO-P1 @ PATCH-BCOND
  X0 X21 MOV-X-X,
  (TCOM-DATA0-X16,)
  TCOM-HANDLER-DADDR X2 MOV-X-IMM64,
  X2 X16 X3 ADD-X-X,
  X20 X3 LDR-X0,
  X20 XZR CMP-X,
  ALIGN4-T HERE-T IO-P3 !
  0 NE B.COND,
  X21 X0 MOV-X-X,
  1 X16 MOV-X-IMM64,
  $80 SVC,
  HERE-T IO-P3 @ PATCH-BCOND
  X4 X20 8 LDR-POST,
  X4 X3 STR-X0,
  X5 X20 8 LDR-POST,
  $910000BF W,                        \ ADD SP, X5, #0
  X19 X20 8 LDR-POST,
  X30 X20 8 LDR-POST,
  X21 X0 MOV-X-X,
  HERE-T IO-P2 @ PATCH-B
  ;

: BODY-ALLOC  ( -- )                  \ ( u -- a-addr ior )
  BTI,
  25 HOST-CALL,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  ;

: BODY-FREE  ( -- )                   \ ( a-addr -- ior )
  BTI,
  26 HOST-CALL,
  ;

: BODY-RESIZE  ( -- )                 \ ( a-addr u -- a-addr2 ior )
  BTI,
  X1 X19 8 LDR-POST,
  27 HOST-CALL,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  ;

: BODY-FIND  ( -- )                   \ FIND ( c-addr -- c-addr 0 | xt n )
  BTI,
  28 HOST-CALL,                       \ X0 = xt or c-addr
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,                       \ TOS = 0 | 1 | -1
  ;

: BODY-AUX-IOR  ( -- )                \ emit: push X0 then TOS=aux
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  ;

: BODY-OPENF  ( -- )                  \ ( c-addr u fam -- fid ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  0 X3 MOV-X-IMM64,
  29 HOST-CALL,
  BODY-AUX-IOR
  ;

: BODY-CREATF  ( -- )                 \ ( c-addr u fam -- fid ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  1 X3 MOV-X-IMM64,
  29 HOST-CALL,
  BODY-AUX-IOR
  ;

: BODY-READF  ( -- )                  \ ( c-addr u1 fileid -- u2 ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  30 HOST-CALL,
  BODY-AUX-IOR
  ;

: BODY-WRITEF  ( -- )                 \ ( c-addr u fileid -- ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  31 HOST-CALL,
  ;

: BODY-RDLINE  ( -- )                 \ ( c-addr u1 fileid -- u2 flag ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  32 HOST-CALL,
  X0 X19 -8 STR-PRE,                  \ u2
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  33 HOST-CALL,                       \ flag
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,                       \ ior
  ;

: BODY-WRLINE  ( -- )                 \ ( c-addr u fileid -- ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  34 HOST-CALL,
  ;

: BODY-UNLINK  ( -- )                 \ ( c-addr u -- ior )
  BTI,
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,
  35 HOST-CALL,
  ;

: BODY-RENAME  ( -- )                 \ ( c-addr1 u1 c-addr2 u2 -- ior )
  BTI,
  X0 X3 MOV-X-X,                      \ u2
  X1 X19 8 LDR-POST,                  \ ca2
  X1 X2 MOV-X-X,
  X1 X19 8 LDR-POST,                  \ u1
  X0 X19 8 LDR-POST,                  \ ca1
  36 HOST-CALL,
  ;

: BODY-FSIZE  ( -- )                  \ ( fileid -- ud ior )
  BTI,
  0 X1 MOV-X-IMM64,
  37 HOST-CALL,
  X0 X19 -8 STR-PRE,                  \ lo
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  33 HOST-CALL,                       \ hi
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  ;

: BODY-FPOS  ( -- )                   \ ( fileid -- ud ior )
  BTI,
  1 X1 MOV-X-IMM64,
  37 HOST-CALL,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  33 HOST-CALL,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  ;

: BODY-FLUSHF  ( -- )                 \ ( fileid -- ior )
  BTI,
  2 X1 MOV-X-IMM64,
  37 HOST-CALL,
  ;

: BODY-REPOS  ( -- )                  \ ( ud fileid -- ior )
  BTI,
  X0 X2 MOV-X-X,                      \ fid
  X1 X19 8 LDR-POST,                  \ hi
  X0 X19 8 LDR-POST,                  \ lo
  X2 X1 MOV-X-X,
  0 X2 MOV-X-IMM64,
  38 HOST-CALL,
  ;

: BODY-FTRUNC  ( -- )                 \ ( ud fileid -- ior )
  BTI,
  X0 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  X2 X1 MOV-X-X,
  1 X2 MOV-X-IMM64,
  38 HOST-CALL,
  ;

: BODY-FSTAT  ( -- )                  \ ( c-addr u -- x ior )
  BTI,
  X0 X1 MOV-X-X,
  X0 X19 8 LDR-POST,
  39 HOST-CALL,
  BODY-AUX-IOR
  ;

: BODY-COMPARE  ( -- )                \ ( ca1 u1 ca2 u2 -- n )
  BTI,
  X0 X3 MOV-X-X,
  X1 X19 8 LDR-POST,
  X1 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  40 HOST-CALL,
  ;

: BODY-SEARCH  ( -- )                 \ ( ca1 u1 ca2 u2 -- ca3 u3 flag )
  BTI,
  X0 X3 MOV-X-X,
  X1 X19 8 LDR-POST,
  X1 X2 MOV-X-X,
  X1 X19 8 LDR-POST,
  X0 X19 8 LDR-POST,
  41 HOST-CALL,
  X0 X7 MOV-X-X,                      \ flag
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,                       \ caddr3
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  33 HOST-CALL,                       \ u3
  X0 X19 -8 STR-PRE,
  X7 X0 MOV-X-X,
  ;

: BODY-PARSE  ( -- )                  \ ( delim -- c-addr u )
  BTI,
  42 HOST-CALL,                       \ u
  X0 X2 MOV-X-X,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,                       \ c-addr
  X0 X19 -8 STR-PRE,
  X2 X0 MOV-X-X,
  ;

: BODY-WORD  ( -- )                   \ ( delim -- c-addr )
  BTI,
  43 HOST-CALL,
  ;

: BODY-SRCSET  ( -- )                 \ SOURCE! ( c-addr u -- )
  BTI,
  X1 X19 8 LDR-POST,                  \ c-addr; X0=u
  44 HOST-CALL,
  X0 X19 8 LDR-POST,                  \ remaining TOS
  ;

: BODY-SOURCE  ( -- )                 \ ( -- c-addr u )
  BTI,
  X0 X19 -8 STR-PRE,                  \ save TOS
  45 HOST-CALL,                       \ u
  X0 X2 MOV-X-X,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  X0 X19 -8 STR-PRE,
  X2 X0 MOV-X-X,
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

: BODY-CMOVEUP  ( -- )                \ CMOVE>  high-to-low
  BTI,
  X0 X3 MOV-X-X,
  X2 X19 8 LDR-POST,                  \ dest
  X1 X19 8 LDR-POST,                  \ src
  X0 X19 8 LDR-POST,
  X3 X1 X1 ADD-X-X,
  X3 X2 X2 ADD-X-X,
  ALIGN4-T HERE-T IO-P1 !
  X3 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,
  1 X1 X1 SUB-IMM,
  1 X2 X2 SUB-IMM,
  X4 X1 LDRB-X,
  X4 X2 STRB-X,
  1 X3 X3 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  ;

: BODY-MOVE  ( -- )                   \ ( src dest u -- ) overlap-safe
  BTI,
  X0 X3 MOV-X-X,                      \ u
  X2 X19 8 LDR-POST,                  \ dest
  X1 X19 8 LDR-POST,                  \ src
  X0 X19 8 LDR-POST,
  X1 X2 CMP-X,                        \ dest ? src
  ALIGN4-T HERE-T IO-P3 !
  0 LS B.COND,                        \ dest <= src → forward
  X3 X1 X4 ADD-X-X,                   \ src+u
  X4 X2 CMP-X,                        \ dest ? src+u
  ALIGN4-T HERE-T IO-P4 !
  0 LO B.COND,                        \ dest < src+u → backward
  HERE-T IO-P3 @ PATCH-BCOND
  ALIGN4-T HERE-T IO-P1 !
  X3 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,
  X4 X1 LDRB-X,
  X4 X2 STRB-X,
  1 X1 X1 ADD-IMM,
  1 X2 X2 ADD-IMM,
  1 X3 X3 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  ALIGN4-T HERE-T IO-P1 !
  0 B-IMM,
  HERE-T IO-P4 @ PATCH-BCOND
  X3 X1 X1 ADD-X-X,
  X3 X2 X2 ADD-X-X,
  ALIGN4-T HERE-T IO-P3 !
  X3 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 EQ B.COND,
  1 X1 X1 SUB-IMM,
  1 X2 X2 SUB-IMM,
  X4 X1 LDRB-X,
  X4 X2 STRB-X,
  1 X3 X3 SUB-IMM,
  IO-P3 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  HERE-T IO-P1 @ PATCH-B
  ;

: BODY-DPLUS  ( -- )                  \ ( d1 d2 -- d1+d2 )
  BTI,
  X1 X19 8 LDR-POST,                  \ lo2
  X2 X19 8 LDR-POST,                  \ hi1
  X3 X19 LDR-X0,                      \ lo1
  X1 X3 X3 ADDS-X,                    \ lo'
  X3 X19 STR-X0,
  X0 X2 X0 ADC-X,                     \ hi'
  ;

: BODY-DMINUS  ( -- )                 \ ( d1 d2 -- d1-d2 )
  BTI,
  X1 X19 8 LDR-POST,                  \ lo2
  X2 X19 8 LDR-POST,                  \ hi1
  X3 X19 LDR-X0,                      \ lo1
  X1 X3 X3 SUBS-X,
  X3 X19 STR-X0,
  X0 X2 X0 SBC-X,
  ;

: BODY-STOD  ( -- )                   \ S>D  ( n -- d )
  BTI,
  X0 X19 -8 STR-PRE,
  XZR X0 CMP-X,
  MI X0 CSET-X,
  X0 XZR X0 SUB-X-X,                  \ 0 or -1
  ;

: BODY-DTOS  ( -- )                   \ D>S  ( d -- n )
  BTI,
  X0 X19 8 LDR-POST,
  ;

: BODY-DNEG  ( -- )                   \ DNEGATE ( d -- -d )
  BTI,
  X1 X19 8 LDR-POST,                  \ lo
  -1 X2 MOV-X-IMM64,
  X2 X1 X1 EOR-X,
  X2 X0 X0 EOR-X,
  1 X3 MOV-X-IMM64,
  X3 X1 X1 ADDS-X,
  XZR X0 X0 ADC-X,
  X1 X19 -8 STR-PRE,
  ;

: BODY-DABS  ( -- )                   \ DABS ( d -- |d| )
  BTI,
  XZR X0 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 MI B.COND,
  ALIGN4-T HERE-T IO-P2 !
  0 B-IMM,
  HERE-T IO-P1 @ PATCH-BCOND
  X1 X19 8 LDR-POST,
  -1 X2 MOV-X-IMM64,
  X2 X1 X1 EOR-X,
  X2 X0 X0 EOR-X,
  1 X3 MOV-X-IMM64,
  X3 X1 X1 ADDS-X,
  XZR X0 X0 ADC-X,
  X1 X19 -8 STR-PRE,
  HERE-T IO-P2 @ PATCH-B
  ;

: BODY-D2STAR  ( -- )                 \ D2* ( d -- d*2 )
  BTI,
  X1 X19 8 LDR-POST,
  X1 X1 X1 ADDS-X,
  X0 X0 X0 ADC-X,
  X1 X19 -8 STR-PRE,
  ;

: BODY-MPLUS  ( -- )                  \ M+ ( d n -- d )
  BTI,
  X1 X19 8 LDR-POST,                  \ hi
  X2 X19 8 LDR-POST,                  \ lo
  X0 X2 X2 ADDS-X,
  XZR X1 X0 ADC-X,
  X2 X19 -8 STR-PRE,
  ;

: BODY-DEQ  ( -- )                    \ D= ( d1 d2 -- flag )
  BTI,
  X1 X19 8 LDR-POST,                  \ lo2
  X2 X19 8 LDR-POST,                  \ hi1
  X3 X19 8 LDR-POST,                  \ lo1
  X1 X3 X3 EOR-X,
  X0 X2 X2 EOR-X,
  X2 X3 X0 ORR-X,
  T0=,
  ;

: BODY-DLT  ( -- )                    \ D< ( d1 d2 -- flag )
  BTI,
  X1 X19 8 LDR-POST,                  \ lo2
  X2 X19 8 LDR-POST,                  \ hi1
  X3 X19 8 LDR-POST,                  \ lo1 ; X0=hi2
  X0 X2 CMP-X,
  ALIGN4-T HERE-T IO-P1 !
  0 EQ B.COND,
  X0 X2 CMP-X,
  LT X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  ALIGN4-T HERE-T IO-P2 !
  0 B-IMM,
  HERE-T IO-P1 @ PATCH-BCOND
  X1 X3 CMP-X,
  LO X0 CSET-X,
  X0 XZR X0 SUB-X-X,
  HERE-T IO-P2 @ PATCH-B
  ;

: BODY-UMSTAR  ( -- )                 \ UM*  ( u1 u2 -- ud ) TOS=hi
  BTI,
  X1 X19 LDR-X0,                      \ u1
  19 HOST-CALL,                       \ X0=lo
  X0 X19 STR-X0,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,                       \ hi
  ;

: BODY-MSTAR  ( -- )                  \ M*  ( n1 n2 -- d ) TOS=hi
  BTI,
  X1 X19 LDR-X0,
  20 HOST-CALL,
  X0 X19 STR-X0,
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,
  ;

: (BODY-DIV3)  ( slot -- )            \ ( d n -- rem quot )  compile-time slot
  X0 X3 MOV-X-X,                      \ den
  X1 X19 8 LDR-POST,                  \ hi
  X2 X19 8 LDR-POST,                  \ lo
  X3 X0 MOV-X-X,
  HOST-CALL,
  X0 X19 -8 STR-PRE,                  \ rem
  0 X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  24 HOST-CALL,                       \ quot
  ;

: BODY-UMMOD  ( -- )  BTI,  21 (BODY-DIV3)  ;
: BODY-SMREM  ( -- )  BTI,  22 (BODY-DIV3)  ;
: BODY-FMMOD  ( -- )  BTI,  23 (BODY-DIV3)  ;

: BODY-SPACES  ( -- )                 \ ( n -- ) via host emit
  BTI,
  ALIGN4-T HERE-T IO-P1 !
  X0 XZR CMP-X,
  ALIGN4-T HERE-T IO-P2 !
  0 LE B.COND,
  X0 X20 -8 STR-PRE,                  \ n on RP across host
  BL X0 MOV-X-IMM64,
  0 X1 MOV-X-IMM64,
  5 HOST-CALL,
  X0 X20 8 LDR-POST,                  \ restore n
  1 X0 X0 SUB-IMM,
  IO-P1 @ HERE-T - 4 / B-IMM,
  HERE-T IO-P2 @ PATCH-BCOND
  X0 X19 8 LDR-POST,                  \ remaining TOS into X0
  ;

' BODY-AND     LIB-PRIM-XT AND#
' BODY-OR      LIB-PRIM-XT OR#
' BODY-INVERT  LIB-PRIM-XT INVERT#
' BODY-2STAR   LIB-PRIM-XT 2STAR#
' BODY-LSHIFT  LIB-PRIM-XT LSHIFT#
' BODY-RSHIFT  LIB-PRIM-XT RSHIFT#
' BODY-UNLOOP  LIB-PRIM-XT UNLOOP#
' BODY-2SLASH  LIB-PRIM-XT 2SLASH#
' BODY-NEGATE  LIB-PRIM-XT NEGATE#
' BODY-CELLS   LIB-PRIM-XT CELLS#
' BODY-2FETCH  LIB-PRIM-XT 2FETCH#
' BODY-2STORE    LIB-PRIM-XT 2STORE#
' BODY-CELLMINUS LIB-PRIM-XT CELLMINUS#
' BODY-COUNT     LIB-PRIM-XT COUNT#
' BODY-FILL      LIB-PRIM-XT FILL#
' BODY-ERASE     LIB-PRIM-XT ERASE#
' BODY-NTRAIL    LIB-PRIM-XT NTRAIL#
' BODY-SLASHSTR  LIB-PRIM-XT SLSTR#
' BODY-CFETCH    LIB-PRIM-XT CFETCH#
' BODY-CSTORE    LIB-PRIM-XT CSTORE#
' BODY-PLUSSTORE LIB-PRIM-XT PLUSSTORE#
' BODY-2DROP     LIB-PRIM-XT 2DROP#
' BODY-XOR       LIB-PRIM-XT XOR#
' BODY-ZLT       LIB-PRIM-XT ZLT#
' BODY-ABS       LIB-PRIM-XT ABS#
' BODY-MIN       LIB-PRIM-XT MIN#
' BODY-MAX       LIB-PRIM-XT MAX#
' BODY-PICK      LIB-PRIM-XT PICK#
' BODY-2SWAP     LIB-PRIM-XT 2SWAP#
' BODY-2OVER     LIB-PRIM-XT 2OVER#
' BODY-TUCK      LIB-PRIM-XT TUCK#
' BODY-QDUP      LIB-PRIM-XT QDUP#
' BODY-ROLL      LIB-PRIM-XT ROLL#
' BODY-DEPTH     LIB-PRIM-XT DEPTH#
' BODY-ZGT       LIB-PRIM-XT ZGT#
' BODY-ZNE       LIB-PRIM-XT ZNE#
' BODY-LE        LIB-PRIM-XT LE#
' BODY-GE        LIB-PRIM-XT GE#
' BODY-ULT       LIB-PRIM-XT ULT#
' BODY-UGT       LIB-PRIM-XT UGT#
' BODY-WITHIN    LIB-PRIM-XT WITHIN#
' BODY-EXEC      LIB-PRIM-XT EXEC#
' BODY-CATCH     LIB-PRIM-XT CATCH#
' BODY-THROW     LIB-PRIM-XT THROW#
' BODY-ALLOC     LIB-PRIM-XT ALLOC#
' BODY-FREE      LIB-PRIM-XT FREE#
' BODY-RESIZE    LIB-PRIM-XT RESIZE#
' BODY-FIND      LIB-PRIM-XT FIND#
' BODY-OPENF   LIB-PRIM-XT OPENF#
' BODY-CREATF  LIB-PRIM-XT CREATF#
' BODY-READF   LIB-PRIM-XT READF#
' BODY-WRITEF  LIB-PRIM-XT WRITEF#
' BODY-RDLINE  LIB-PRIM-XT RDLINE#
' BODY-WRLINE  LIB-PRIM-XT WRLINE#
' BODY-UNLINK  LIB-PRIM-XT UNLINK#
' BODY-RENAME  LIB-PRIM-XT RENAME#
' BODY-FSIZE   LIB-PRIM-XT FSIZE#
' BODY-FPOS    LIB-PRIM-XT FPOS#
' BODY-FLUSHF  LIB-PRIM-XT FLUSHF#
' BODY-REPOS   LIB-PRIM-XT REPOS#
' BODY-FTRUNC  LIB-PRIM-XT FTRUNC#
' BODY-FSTAT   LIB-PRIM-XT FSTAT#
' BODY-COMPARE LIB-PRIM-XT CMPSTR#
' BODY-SEARCH  LIB-PRIM-XT SEARCH#
' BODY-PARSE   LIB-PRIM-XT PARSE#
' BODY-WORD    LIB-PRIM-XT WORD#
' BODY-SRCSET  LIB-PRIM-XT SRCSET#
' BODY-SOURCE  LIB-PRIM-XT SOURCE#
' BODY-LTSHARP   LIB-PRIM-XT LTSHARP#
' BODY-HOLD      LIB-PRIM-XT HOLD#
' BODY-SIGN      LIB-PRIM-XT SIGN#
' BODY-SHARP     LIB-PRIM-XT SHARP#
' BODY-SHARPGT   LIB-PRIM-XT SHARPGT#
' BODY-CMOVE   LIB-PRIM-XT CMOVE#
' BODY-CMOVEUP LIB-PRIM-XT CMOVEUP#
' BODY-MOVE    LIB-PRIM-XT MOVE#
' BODY-DPLUS   LIB-PRIM-XT DPLUS#
' BODY-DNEG    LIB-PRIM-XT DNEG#
' BODY-DABS    LIB-PRIM-XT DABS#
' BODY-D2STAR  LIB-PRIM-XT D2STAR#
' BODY-MPLUS   LIB-PRIM-XT MPLUS#
' BODY-DEQ     LIB-PRIM-XT DEQ#
' BODY-DLT     LIB-PRIM-XT DLT#
' BODY-DMINUS  LIB-PRIM-XT DMINUS#
' BODY-STOD    LIB-PRIM-XT STOD#
' BODY-DTOS    LIB-PRIM-XT DTOS#
' BODY-UMSTAR  LIB-PRIM-XT UMSTAR#
' BODY-MSTAR   LIB-PRIM-XT MSTAR#
' BODY-UMMOD   LIB-PRIM-XT UMMOD#
' BODY-SMREM   LIB-PRIM-XT SMREM#
' BODY-FMMOD   LIB-PRIM-XT FMMOD#
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
  X1 X19 8 LDR-POST,                  \ X1 = x; [X19] = remaining TOS
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

\ TONE# ( freq dur -- ) host slot 12 — freq=Hz, dur=tenths of a second (F-PC TONE)
: BODY-TONE  ( -- )
  BTI,
  X0 X2 MOV-X-X,                      \ X2 = dur
  X1 X19 8 LDR-POST,                  \ X1 = freq
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
  0 X1 MOV-X-IMM64,
  10 HOST-CALL,                       \ X0 = n
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
