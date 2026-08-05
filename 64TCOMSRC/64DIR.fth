\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2)
\
\ Public domain. Requires 64HOST.fth. Load before GEN pack.

TCOM-ANEW 64DIR

FORTH DEFINITIONS
DECIMAL

0 CONSTANT SYM-NONE
1 CONSTANT SYM-TARGET
2 CONSTANT SYM-LIBRARY
3 CONSTANT SYM-CODE
4 CONSTANT SYM-FORWARD

\ Parallel arrays
256 CONSTANT SYM-MAX
32  CONSTANT /SNAME

CREATE SYMT  SYM-MAX CELLS ALLOT
CREATE SYMA  SYM-MAX CELLS ALLOT
CREATE SYMU  SYM-MAX CELLS ALLOT
CREATE SYMN  SYM-MAX /SNAME * ALLOT
VARIABLE SYM-N
0 SYM-N !

: SYM-CLEAR  ( -- )
  0 SYM-N !
  SYMT SYM-MAX CELLS ERASE
  SYMA SYM-MAX CELLS ERASE
  SYMU SYM-MAX CELLS ERASE
  SYMN SYM-MAX /SNAME * ERASE
  ;

: SYM-COUNT  ( -- n )  SYM-N @ ;

: SYM-TYPE@  ( i -- n )  CELLS SYMT + @ ;
: SYM-ADDR@  ( i -- n )  CELLS SYMA + @ ;
: SYM-USES@  ( i -- n )  CELLS SYMU + @ ;
: SYM-TYPE!  ( n i -- )  CELLS SYMT + ! ;
: SYM-ADDR!  ( n i -- )  CELLS SYMA + ! ;
: SYM-USES!  ( n i -- )  CELLS SYMU + ! ;
: SYM-USE+   ( i -- )    DUP SYM-USES@ 1+ SWAP SYM-USES! ;

: SYM-NBUF  ( i -- c-addr )  /SNAME * SYMN + ;

: SYM-PUT-NAME  ( c-addr u i -- )
  >R
  31 MIN
  DUP R@ SYM-NBUF C!
  R@ SYM-NBUF CHAR+ SWAP MOVE
  R> DROP
  ;

: SYM-GET-NAME  ( i -- c-addr u )  SYM-NBUF COUNT ;

: SYM-NAME=  ( c-addr u i -- flag )
  SYM-GET-NAME COMPARE 0=
  ;

: SYM-FIND  ( c-addr u -- i true | false )
  SYM-N @ 0= IF  2DROP FALSE EXIT  THEN
  SYM-N @ 0 DO
    2DUP I SYM-NAME=
    IF  2DROP I TRUE UNLOOP EXIT  THEN
  LOOP
  2DROP FALSE
  ;

\ ( c-addr u type addr -- i )
\ Hold type and addr in two cells at PAD (avoid R-stack confusion)
: SYM-ADD
  PAD CELL+ !                      \ addr at PAD+CELL
  PAD !                            \ type at PAD
  \ stack: ca u
  2DUP SYM-FIND IF                 \ ca u i
    NIP NIP                        \ i
    PAD @ OVER SYM-TYPE!
    PAD CELL+ @ OVER SYM-ADDR!
    EXIT
  THEN                             \ ca u
  SYM-N @ SYM-MAX U>= IF
    2DROP S" Symbol table full" TCOM-ABORT
  THEN
  SYM-N @ SYM-PUT-NAME             \ ca u i
  PAD @       SYM-N @ SYM-TYPE!
  PAD CELL+ @ SYM-N @ SYM-ADDR!
  0           SYM-N @ SYM-USES!
  SYM-N @
  1 SYM-N +!
  ;

: SYM-ADD-LAST  ( type addr -- i )
  \ type addr on stack; name from LAST
  LAST NAME>STRING                 \ type addr ca u
  2SWAP                            \ ca u type addr
  SYM-ADD
  ;

\ Register LAST host word: name from LAST, cookie from argument
: SYM-REG-LIB  ( cookie -- )
  SYM-LIBRARY SWAP                 \ type cookie
  SYM-ADD-LAST DROP
  ;

: .SYM-TYPE  ( type -- )
  DUP SYM-TARGET  = IF DROP ." TARGET" EXIT THEN
  DUP SYM-LIBRARY = IF DROP ." LIB"    EXIT THEN
  DUP SYM-CODE    = IF DROP ." CODE"   EXIT THEN
  DUP SYM-FORWARD = IF DROP ." FWD"    EXIT THEN
  DROP ." ?"
  ;

\ Print u in hex without using >R inside a DO LOOP (that corrupts I!)
: SYM-HEX.  ( u -- )
  BASE @ SWAP HEX 0 <# #S #> TYPE SPACE BASE !
  ;

: .SYMBOLS  ( -- )
  S" Symbols: " TYPE SYM-COUNT 0 .R S"  / " TYPE SYM-MAX 0 .R CR
  SYM-COUNT 0= IF S"   (none)" TYPE CR EXIT THEN
  SYM-COUNT 0 DO
    I 3 .R SPACE
    I SYM-GET-NAME TYPE
    16 I SYM-NBUF C@ - 0 MAX SPACES
    I SYM-TYPE@ .SYM-TYPE
    S"  @ " TYPE
    I SYM-ADDR@ SYM-HEX.
    S" uses=" TYPE I SYM-USES@ 0 .R CR
  LOOP
  ;

\ =============================================================================
\ Director
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
  ?QUIET 0= IF LAST NAME>STRING TYPE CR THEN
  LAST NAME>STRING PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
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
  LAST NAME>STRING PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
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
  LAST NAME>STRING PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
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

: .SYMA  ( -- )
  S" SYMA raw (first 16):" TYPE CR
  SYM-N @ 0 MAX 16 MIN 0 ?DO
    I 3 .R S" : " TYPE
    I CELLS SYMA + @ SYM-HEX.
    CR
  LOOP
  ;

: SYM-SMOKE  ( -- )
  SYM-CLEAR
  S" AAA" SYM-LIBRARY $8000 SYM-ADD DROP
  S" BBB" SYM-LIBRARY $8008 SYM-ADD DROP
  S" CCC" SYM-TARGET  $0001 SYM-ADD DROP
  0 SYM-ADDR@ $8000 <> IF S" SYM-SMOKE fail0 got " TYPE 0 SYM-ADDR@ H. CR ABORT THEN
  1 SYM-ADDR@ $8008 <> IF S" SYM-SMOKE fail1 got " TYPE 1 SYM-ADDR@ H. CR ABORT THEN
  2 SYM-ADDR@ $0001 <> IF S" SYM-SMOKE fail2 got " TYPE 2 SYM-ADDR@ H. CR ABORT THEN
  S" SYM-SMOKE: OK" TYPE CR
  SYM-CLEAR
  ;

FORTH DEFINITIONS
SYM-CLEAR
SYM-SMOKE
S" 64DIR loaded (symbol table + director)." TYPE CR
