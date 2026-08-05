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

TCOM-ANEW LIBGEN

FORTH DEFINITIONS
DECIMAL

\ Cookies are host-side IDs in a high range (not real image offsets).
\ See comment block at end of this file / 64DESIGN notes: a "library cookie"
\ is just a unique ID for a stub library word (e.g. DUP# → $8038), used by
\ CALL tags until a real target has real addresses.
$8000 VALUE LIB-COOKIE-NEXT
0 VALUE LIB-PRIM-COUNT          \ how many LIB-PRIM names this load

FALSE VALUE LIB-VERBOSE         \ TRUE → print each cookie line
: LIB-VERBOSE-ON   ( -- )  TRUE  TO LIB-VERBOSE ;
: LIB-VERBOSE-OFF  ( -- )  FALSE TO LIB-VERBOSE ;

: LIB-CREATE  ( cookie -- )
  CREATE ,  DOES> @
  ;

: LIB-PRIM  ( "<spaces>name" -- )
  HOST-DEFS
  LIB-COOKIE-NEXT >R           ( R: cookie )
  R@ LIB-CREATE                \ parses name; host word returns cookie
  LIB-VERBOSE IF
    ." Library cookie " LAST NAME>STRING TYPE SPACE R@ H. CR
  THEN
  R> DROP
  LIB-COOKIE-NEXT T-CELL + TO LIB-COOKIE-NEXT
  LIB-PRIM-COUNT 1+ TO LIB-PRIM-COUNT
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
  ." LIBGEN: " LIB-PRIM-COUNT . ." library cookies (IDs for stub prims like DUP#)." CR
  ."   Example:  T: FOO  $AA G,  ' DUP# LIB,  ;T" CR
  ."   Next cookie id=" LIB-COOKIE-NEXT H. CR
  ."   LIB-VERBOSE-ON  to list each cookie at define time." CR
  ;

FORTH DEFINITIONS
>FORTH
." LIBGEN: " LIB-PRIM-COUNT . ." library cookies ready (DUP# EXIT# …)." CR
