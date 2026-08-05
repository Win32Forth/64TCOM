\ LIBGEN.fth — Stub target library for 64TCOM GEN
\
\ Public domain.
\ Requires: 64HOST.fth, 64DIR.fth (symbol table), ASMGEN, OPTGEN

TCOM-ANEW LIBGEN

FORTH DEFINITIONS
DECIMAL

VARIABLE LIB-NEXT
$8000 LIB-NEXT !
VARIABLE LIB-PRIM-COUNT
0 LIB-PRIM-COUNT !

FALSE VALUE LIB-VERBOSE
: LIB-VERBOSE-ON   ( -- )  TRUE  TO LIB-VERBOSE ;
: LIB-VERBOSE-OFF  ( -- )  FALSE TO LIB-VERBOSE ;

\ Define host CONSTANT <name> = cookie, and write symbol row directly
\ (does not use SYM-ADD — isolates table writes for reliability).
: LIB-PRIM  ( "<spaces>name" -- )
  HOST-DEFS
  LIB-NEXT @ CONSTANT                 \ cookie CONSTANT name
  \ index for new symbol row
  SYM-N @ >R                          ( R: i )
  LAST NAME>STRING R@ SYM-PUT-NAME
  SYM-LIBRARY R@ SYM-TYPE!
  LIB-NEXT @  R@ SYM-ADDR!            \ same cookie as CONSTANT
  0           R@ SYM-USES!
  R> DROP
  1 SYM-N +!
  LIB-VERBOSE IF
    ." Library cookie " LAST NAME>STRING TYPE SPACE LIB-NEXT @ H. CR
  THEN
  8 LIB-NEXT +!
  1 LIB-PRIM-COUNT +!
  FORTH-DEFS
  ;

: LIB-CALL  ( cookie -- )  COMP-CALL ;

: LIB,  ( xt -- )  EXECUTE COMP-CALL ;

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

: .LIBGEN  ( -- )
  S" LIBGEN: " TYPE LIB-PRIM-COUNT @ 0 .R
  S"  library cookies. Next=" TYPE
  BASE @ >R HEX LIB-NEXT @ U. R> BASE !
  CR
  ;

FORTH DEFINITIONS
>FORTH
S" LIBGEN: " TYPE LIB-PRIM-COUNT @ 0 .R S"  library cookies ready." TYPE CR
