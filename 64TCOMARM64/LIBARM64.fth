\ LIBARM64.fth — ARM64 target library with real primitive bodies
\
\ Public domain. Requires 64HOST, 64DIR, ASMARM64, OPTARM64.
\ ABI: X0 = TOS, X19 = DSP. Cells = 8 bytes. Prims end with RET.

TCOM-ANEW LIBARM64

FORTH DEFINITIONS
DECIMAL

T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN

VARIABLE LIB-PRIM-COUNT
0 LIB-PRIM-COUNT !

\ How many SYM slots are library (for TARGET-INIT trim)
VARIABLE LIB-SYM-N
0 LIB-SYM-N !

FALSE VALUE LIB-VERBOSE
: LIB-VERBOSE-ON   ( -- )  TRUE  TO LIB-VERBOSE ;
: LIB-VERBOSE-OFF  ( -- )  FALSE TO LIB-VERBOSE ;

VARIABLE LIB-I
VARIABLE LIB-CA
VARIABLE LIB-U
VARIABLE LIB-CK
VARIABLE LIB-BODY-XT

: LIB-PRIM-XT  ( body-xt "<spaces>name" -- )
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

: (BODY-NOOP)   ( -- )  ;
: (BODY-EXIT)   ( -- )  ;

: (BODY-DUP)    ( -- )
  X0 X19 -8 STR-PRE,
  ;

: (BODY-DROP)   ( -- )
  X0 X19 8 LDR-POST,
  ;

: (BODY-SWAP)   ( -- )
  X1 X19 0 LDR-X0,
  X0 X19 0 STR-X0,
  X1 X0 MOV-X-X,
  ;

: (BODY-OVER)   ( -- )
  X1 X19 0 LDR-X0,
  X0 X19 -8 STR-PRE,
  X1 X0 MOV-X-X,
  ;

: (BODY-PLUS)   ( -- )
  X1 X19 8 LDR-POST,
  X0 X1 X0 ADD-X-X,
  ;

: (BODY-MINUS)  ( -- )
  X1 X19 8 LDR-POST,
  X0 X1 X0 SUB-X-X,
  ;

: (BODY-FETCH)  ( -- )
  X0 X0 LDR-X0,
  ;

: (BODY-STORE)  ( -- )
  X1 X19 8 LDR-POST,
  X1 X0 STR-X0,
  X0 X19 8 LDR-POST,
  ;

\ BRANCH#  ( taddr -- )  tail-branch to target offset (no return)
: (BODY-BRANCH)  ( -- )
  T-CODE-BASE X16 MOV-X-IMM64,
  X0 X16 X16 ADD-X-X,
  X16 BR-X,
  ;

\ ZBRANCH#  ( flag dest-taddr -- )  if flag=0 branch to dest, else drop both
\ Layout after flag load:
\   CBNZ X1, +7     ; 6 insn branch path + fall to untaken? 
\ Taken (flag==0): use CBZ X1, taken_path... easier:
\   X1 = flag, X0 = dest
\   CBNZ X1, #7     ; if flag != 0 skip 7 insns to untaken
\   MOV X16, base   ; 4
\   ADD X16,X16,X0  ; 1
\   BR  X16         ; 1   total 6 after CBNZ → imm19=7 for untaken at +7 words
\ untaken:
\   LDR X0,[X19],#8 ; drop dest, new TOS
\
: (BODY-ZBRANCH)  ( -- )
  X1 X19 8 LDR-POST,              \ x1=flag, x0=dest
  X1 7 CBNZ-X,                    \ if flag!=0 goto untaken (+7 insns)
  T-CODE-BASE X16 MOV-X-IMM64,    \ 4 insns
  X0 X16 X16 ADD-X-X,             \ 1
  X16 BR-X,                       \ 1  → 6 insns; +1 = 7th is untaken
  X0 X19 8 LDR-POST,              \ untaken: discard dest
  ;

: (BODY-STUB)  ( -- )  ;

' (BODY-STUB)    LIB-PRIM-XT LIT#
' (BODY-EXIT)    LIB-PRIM-XT EXIT#
' (BODY-EXIT)    LIB-PRIM-XT UNNEST#
' (BODY-BRANCH)  LIB-PRIM-XT BRANCH#
' (BODY-ZBRANCH) LIB-PRIM-XT ZBRANCH#
' (BODY-FETCH)   LIB-PRIM-XT FETCH#
' (BODY-STORE)   LIB-PRIM-XT STORE#
' (BODY-DUP)     LIB-PRIM-XT DUP#
' (BODY-DROP)    LIB-PRIM-XT DROP#
' (BODY-SWAP)    LIB-PRIM-XT SWAP#
' (BODY-OVER)    LIB-PRIM-XT OVER#
' (BODY-PLUS)    LIB-PRIM-XT PLUS#
' (BODY-MINUS)   LIB-PRIM-XT MINUS#
' (BODY-STUB)    LIB-PRIM-XT EXEC#
' (BODY-NOOP)    LIB-PRIM-XT NOOP#

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
