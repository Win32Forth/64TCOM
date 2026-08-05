\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2)
\
\ Public domain.
\
\ Requires: 64HOST.fth
\ Load before GEN pack (ASMGEN/OPTGEN/LIBGEN).
\
\ Symbol table: name → type, addr/cookie, use count
\ Director (interpret-only): T: ;T L: ;L GCODE G, GCALL GJMP G' LIB,

TCOM-ANEW 64DIR

FORTH DEFINITIONS
DECIMAL

\ =============================================================================
\ Symbol types
\ =============================================================================

0 CONSTANT SYM-NONE
1 CONSTANT SYM-TARGET
2 CONSTANT SYM-LIBRARY
3 CONSTANT SYM-CODE
4 CONSTANT SYM-FORWARD

\ =============================================================================
\ Table
\ =============================================================================

256 CONSTANT SYM-MAX
32  CONSTANT SYM-NAME-SIZE

CREATE SYM-NAMES  SYM-MAX SYM-NAME-SIZE * ALLOT
CREATE SYM-TYPE   SYM-MAX CELLS ALLOT
CREATE SYM-ADDR   SYM-MAX CELLS ALLOT
CREATE SYM-USES   SYM-MAX CELLS ALLOT

0 VALUE SYM-COUNT

: SYM-NAME  ( i -- c-addr )  SYM-NAME-SIZE * SYM-NAMES + ;
: SYM-TYPE! ( x i -- )  CELLS SYM-TYPE + ! ;
: SYM-TYPE@ ( i -- x )  CELLS SYM-TYPE + @ ;
: SYM-ADDR! ( x i -- )  CELLS SYM-ADDR + ! ;
: SYM-ADDR@ ( i -- x )  CELLS SYM-ADDR + @ ;
: SYM-USES! ( x i -- )  CELLS SYM-USES + ! ;
: SYM-USES@ ( i -- x )  CELLS SYM-USES + @ ;

: SYM-CLEAR  ( -- )
  0 TO SYM-COUNT
  SYM-NAMES SYM-MAX SYM-NAME-SIZE * ERASE
  SYM-TYPE  SYM-MAX CELLS ERASE
  SYM-ADDR  SYM-MAX CELLS ERASE
  SYM-USES  SYM-MAX CELLS ERASE
  ;

: SYM-NAME=  ( c-addr u i -- flag )
  SYM-NAME COUNT COMPARE 0=
  ;

: SYM-FIND  ( c-addr u -- i true | false )
  SYM-COUNT 0= IF  2DROP FALSE EXIT  THEN
  SYM-COUNT 0 DO
    2DUP I SYM-NAME=
    IF  2DROP I TRUE UNLOOP EXIT  THEN
  LOOP
  2DROP FALSE
  ;

: SYM-USE+  ( i -- )  DUP SYM-USES@ 1+ SWAP SYM-USES! ;

\ SYM-ADD ( c-addr u type addr -- i )
\ No VALUE/TO temps — keep type/addr on the return stack only.
: SYM-ADD  ( c-addr u type addr -- i )
  2SWAP                                 ( type addr ca u )
  2DUP SYM-FIND IF                      ( type addr ca u i )
    >R 2DROP                            ( type addr ) ( R: i )
    OVER R@ SYM-TYPE!                   ( type addr )
    NIP R@ SYM-ADDR!                    ( )
    R> EXIT                             ( i )
  THEN                                  ( type addr ca u )
  SYM-COUNT SYM-MAX U>= IF
    2DROP 2DROP
    S" Symbol table full" TCOM-ABORT
  THEN
  2SWAP                                 ( ca u type addr )
  >R >R                                 ( ca u ) ( R: addr type )
  SYM-COUNT SYM-NAME PLACE
  R> SYM-COUNT SYM-TYPE!
  R> SYM-COUNT SYM-ADDR!
  0 SYM-COUNT SYM-USES!
  SYM-COUNT
  SYM-COUNT 1+ TO SYM-COUNT
  ;

: SYM-ADD-LAST  ( type addr -- i )
  LAST NAME>STRING 2SWAP SYM-ADD
  ;

\ Register LAST (a LIB-CREATE word) using the cookie in its data field
: SYM-REG-LAST-LIB  ( -- )
  LAST >BODY CELL+ @                    ( cookie )
  SYM-LIBRARY SWAP                      ( type cookie )
  SYM-ADD-LAST DROP
  ;

: .SYM-TYPE  ( type -- )
  DUP SYM-TARGET  = IF DROP ." TARGET" EXIT THEN
  DUP SYM-LIBRARY = IF DROP ." LIB"    EXIT THEN
  DUP SYM-CODE    = IF DROP ." CODE"   EXIT THEN
  DUP SYM-FORWARD = IF DROP ." FWD"    EXIT THEN
  DROP ." ?"
  ;

: .SYMBOLS  ( -- )
  ." Symbols: " SYM-COUNT . ." / " SYM-MAX . CR
  SYM-COUNT 0= IF ."   (none)" CR EXIT THEN
  SYM-COUNT 0 DO
    I 3 .R SPACE
    I SYM-NAME COUNT TYPE
    16 I SYM-NAME C@ - 0 MAX SPACES
    I SYM-TYPE@ .SYM-TYPE
    ."  @ "
    BASE @ >R HEX I SYM-ADDR@ U. R> BASE !
    ." uses=" I SYM-USES@ . CR
  LOOP
  ;

\ =============================================================================
\ Director (interpret-only)
\ =============================================================================

: ?INTERPRET-ONLY  ( c-addr u -- )
  STATE @ IF TCOM-ABORT ELSE 2DROP THEN
  ;

: (T-COOKIE)  ( taddr -- )
  CREATE , DOES> @
  ;

: T:  ( "<spaces>name" -- )
  S" T: is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  START-T:
  HERE-T >R
  R@ (T-COOKIE)
  \ START-T: (OPTGEN) already prints "Defining-: "; only add the name here
  ?QUIET 0= IF LAST NAME>STRING TYPE CR THEN
  LAST NAME>STRING PAD PLACE PAD COMP-HEADER
  SYM-TARGET R@ SYM-ADD-LAST DROP
  R> DROP
  TRUE TO ?INTERPRETIVE
  ;

: ;T  ( -- )
  END-T:
  FALSE TO ?INTERPRETIVE
  ; IMMEDIATE

: L:  ( "<spaces>name" -- )
  S" L: is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  TRUE TO ?LIB
  START-L:
  HERE-T >R
  R@ (T-COOKIE)
  ?QUIET 0= IF LAST NAME>STRING TYPE CR THEN
  LAST NAME>STRING PAD PLACE PAD COMP-HEADER
  SYM-LIBRARY R@ SYM-ADD-LAST DROP
  R> DROP
  ;

: ;L  ( -- )
  END-L:
  FALSE TO ?LIB
  ; IMMEDIATE

: GCODE  ( "<spaces>name" -- )
  S" GCODE is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  TCODE-START
  HERE-T >R
  R@ (T-COOKIE)
  ?QUIET 0= IF LAST NAME>STRING TYPE CR THEN
  LAST NAME>STRING PAD PLACE PAD COMP-HEADER
  SYM-CODE R@ SYM-ADD-LAST DROP
  R> DROP
  SETASSEM
  ;

: G,    ( n -- )     COMP-SINGLE ;
: GCALL ( addr -- )  COMP-CALL ;
: GJMP  ( addr -- )  COMP-JMP-IMM ;

: G'  ( "<spaces>name" -- )
  BL WORD COUNT
  2DUP SYM-FIND 0= IF
    TYPE ."  ?" CR
    S" unknown symbol" TCOM-ABORT
  THEN
  NIP NIP
  DUP SYM-USE+
  SYM-ADDR@ COMP-CALL
  ;

: LIB,  ( xt -- )  EXECUTE COMP-CALL ;

DEFER DIR-ON-TARGET-INIT
: (DIR-ON-TARGET-INIT-NOOP) ( -- )  ;
' (DIR-ON-TARGET-INIT-NOOP) IS DIR-ON-TARGET-INIT

: .DIR  ( -- )
  ." 64DIR Phase 1.2 — symbols + thin director" CR
  ."   T: ;T L: ;L GCODE G, GCALL GJMP G' LIB, .SYMBOLS SYM-CLEAR" CR
  .SYMBOLS
  ;

FORTH DEFINITIONS
SYM-CLEAR
." 64DIR loaded (symbol table + director)." CR
