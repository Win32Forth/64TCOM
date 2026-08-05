\ LIBARM64.fth — Minimal ARM64 target library (real code addresses)
\
\ Public domain. Requires 64HOST, 64DIR, ASMARM64, OPTARM64.
\ Each LIB-PRIM emits a small A64 stub at HERE-T and registers that
\ address as the library cookie (not a fake $8000 range).

TCOM-ANEW LIBARM64

FORTH DEFINITIONS
DECIMAL

\ Stubs are real bytes in the target image — need a buffer before prims.
T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN

\ Do NOT redefine LIB-CODE-END here — OPTARM64 owns it. A second VARIABLE
\ would shadow OPT's; TARGET-INIT is compiled against OPT's (would stay 0).

VARIABLE LIB-PRIM-COUNT
0 LIB-PRIM-COUNT !

FALSE VALUE LIB-VERBOSE
: LIB-VERBOSE-ON   ( -- )  TRUE  TO LIB-VERBOSE ;
: LIB-VERBOSE-OFF  ( -- )  FALSE TO LIB-VERBOSE ;

VARIABLE LIB-I
VARIABLE LIB-CA
VARIABLE LIB-U
VARIABLE LIB-CK

\ Default stub body: RET (safe no-op callable)
: LIB-STUB-BODY  ( -- )
  ALIGN4-T
  RET,
  ;

\ Optional: slightly different stubs later (DUP# etc.)
: LIB-PRIM  ( "<spaces>name" -- )
  HOST-DEFS
  ALIGN4-T
  HERE-T LIB-CK !
  LIB-STUB-BODY
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

\ Same names as GEN so demos can share source style
LIB-PRIM LIT#
LIB-PRIM EXIT#
LIB-PRIM UNNEST#
LIB-PRIM BRANCH#
LIB-PRIM ZBRANCH#
LIB-PRIM FETCH#
LIB-PRIM STORE#
LIB-PRIM DUP#
LIB-PRIM DROP#
LIB-PRIM SWAP#
LIB-PRIM OVER#
LIB-PRIM PLUS#
LIB-PRIM MINUS#
LIB-PRIM EXEC#
LIB-PRIM NOOP#

\ Preserve stubs across TARGET-INIT (VARIABLE is in OPTARM64)
HERE-T LIB-CODE-END !
?QUIET 0= IF
  S" LIB-CODE-END=" TYPE LIB-CODE-END @ SYM-HEX. CR
THEN

: .LIBARM64  ( -- )
  S" LIBARM64: " TYPE LIB-PRIM-COUNT @ 0 .R
  S"  stubs (RET each). LIB-CODE-END=" TYPE LIB-CODE-END @ SYM-HEX. CR
  ;

FORTH DEFINITIONS
>FORTH
S" LIBARM64: " TYPE LIB-PRIM-COUNT @ 0 .R S"  library stubs ready." TYPE CR
