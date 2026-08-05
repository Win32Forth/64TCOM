\ LIBGEN.fth — Stub target library for 64TCOM GEN
\
\ Public domain.
\ Classic analogue: tcom25/TCOMGEN/LIBGEN.FTH
\
\ LIB-PRIM creates a host word that returns a unique cookie address (not
\ dependent on the target image). TARGET-INIT may clear the image without
\ invalidating cookies. LIB, / LIB-CALL emit a GEN CALL tag via COMP-CALL.
\
\ Prim names end with # so they never shadow FORTH EXIT DUP @ etc.
\
\ Requires: 64HOST.fth, ASMGEN.fth, OPTGEN.fth

ANEW LIBGEN

FORTH DEFINITIONS
DECIMAL

\ Cookies are host-side IDs in a high range (not real image offsets).
$8000 VALUE LIB-COOKIE-NEXT

: LIB-CREATE  ( cookie -- )
  CREATE ,  DOES> @
  ;

: LIB-PRIM  ( "<spaces>name" -- )
  HOST-DEFS
  LIB-COOKIE-NEXT
  ?2CR
  ?QUIET 0= IF  ." Library cookie " DUP H.  THEN
  LIB-CREATE                   \ parses name
  LIB-COOKIE-NEXT T-CELL + TO LIB-COOKIE-NEXT
  FORTH-DEFS
  ;

: LIB-CALL  ( cookie -- )  COMP-CALL ;

: LIB,  ( xt -- )
  EXECUTE  COMP-CALL
  ;

\ --- Standard GEN library cookies -------------------------------------------

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
  CR ." LIBGEN: host-side library cookies (names end with #)" CR
  ."   Example:  T: FOO  $AA G,  ' DUP# LIB,  ;T" CR
  ."   Next cookie=" LIB-COOKIE-NEXT H. CR
  ;

FORTH DEFINITIONS
>FORTH
CR ." LIBGEN loaded." CR
