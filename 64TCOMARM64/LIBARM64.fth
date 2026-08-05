\ LIBARM64.fth — ARM64 target library with real primitive bodies
\
\ Public domain. Requires 64HOST, 64DIR, ASMARM64, OPTARM64.
\
\ ABI: X0 = TOS, X19 = DSP (push: STR X0,[X19,#-8]!). Cells = 8 bytes.
\ Each prim ends with RET (subroutine-threaded).

TCOM-ANEW LIBARM64

FORTH DEFINITIONS
DECIMAL

T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN

VARIABLE LIB-PRIM-COUNT
0 LIB-PRIM-COUNT !

FALSE VALUE LIB-VERBOSE
: LIB-VERBOSE-ON   ( -- )  TRUE  TO LIB-VERBOSE ;
: LIB-VERBOSE-OFF  ( -- )  FALSE TO LIB-VERBOSE ;

VARIABLE LIB-I
VARIABLE LIB-CA
VARIABLE LIB-U
VARIABLE LIB-CK
VARIABLE LIB-BODY-XT

\ body-xt ( -- ) emits machine code for the primitive (no RET; we add it)
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

\ --- primitive bodies (no RET) ---

: (BODY-NOOP)   ( -- )  ;                          \ fall into RET,

: (BODY-DUP)    ( -- )  \ ( x -- x x )
  X0 X19 -8 STR-PRE,
  ;

: (BODY-DROP)   ( -- )  \ ( x -- )
  X0 X19 8 LDR-POST,
  ;

: (BODY-SWAP)   ( -- )  \ ( a b -- b a )  TOS=b, [DSP]=a
  X1 X19 0 LDR-X0,                                 \ x1 = a
  X0 X19 0 STR-X0,                                 \ [DSP] = b
  X1 X0 MOV-X-X,                                   \ TOS = a
  ;

: (BODY-OVER)   ( -- )  \ ( a b -- a b a )  TOS=b, [DSP]=a
  X1 X19 0 LDR-X0,                                 \ x1 = a
  X0 X19 -8 STR-PRE,                               \ push b
  X1 X0 MOV-X-X,                                   \ TOS = a
  ;

: (BODY-PLUS)   ( -- )  \ ( a b -- a+b )
  X1 X19 8 LDR-POST,                               \ x1 = a, pop
  X0 X1 X0 ADD-X-X,                                \ x0 = a + b  (xm xn xd)
  ;

: (BODY-MINUS)  ( -- )  \ ( a b -- a-b )
  X1 X19 8 LDR-POST,
  X0 X1 X0 SUB-X-X,                                \ x0 = a - b
  ;

: (BODY-FETCH)  ( -- )  \ ( a -- n )
  X0 X0 LDR-X0,
  ;

: (BODY-STORE)  ( -- )  \ ( n a -- )
  X1 X19 8 LDR-POST,                               \ x1 = n
  X1 X0 STR-X0,                                    \ [a] = n
  X0 X19 8 LDR-POST,                               \ new TOS
  ;

: (BODY-EXIT)   ( -- )  ;                          \ RET only

\ BRANCH/ZBRANCH/EXEC/LIT# left as NOOP/RET for now (need full control model)
: (BODY-STUB)   ( -- )  ;

' (BODY-STUB)  LIB-PRIM-XT LIT#
' (BODY-EXIT)  LIB-PRIM-XT EXIT#
' (BODY-EXIT)  LIB-PRIM-XT UNNEST#
' (BODY-STUB)  LIB-PRIM-XT BRANCH#
' (BODY-STUB)  LIB-PRIM-XT ZBRANCH#
' (BODY-FETCH) LIB-PRIM-XT FETCH#
' (BODY-STORE) LIB-PRIM-XT STORE#
' (BODY-DUP)   LIB-PRIM-XT DUP#
' (BODY-DROP)  LIB-PRIM-XT DROP#
' (BODY-SWAP)  LIB-PRIM-XT SWAP#
' (BODY-OVER)  LIB-PRIM-XT OVER#
' (BODY-PLUS)  LIB-PRIM-XT PLUS#
' (BODY-MINUS) LIB-PRIM-XT MINUS#
' (BODY-STUB)  LIB-PRIM-XT EXEC#
' (BODY-NOOP)  LIB-PRIM-XT NOOP#

HERE-T LIB-CODE-END !
?QUIET 0= IF
  S" LIB-CODE-END=" TYPE LIB-CODE-END @ SYM-HEX. CR
THEN

: .LIBARM64  ( -- )
  S" LIBARM64: " TYPE LIB-PRIM-COUNT @ 0 .R
  S"  prims (X0=TOS X19=DSP). LIB-CODE-END=" TYPE LIB-CODE-END @ SYM-HEX. CR
  ;

FORTH DEFINITIONS
>FORTH
S" LIBARM64: " TYPE LIB-PRIM-COUNT @ 0 .R S"  real prims ready." TYPE CR
