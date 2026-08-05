\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2)
\
\ Public domain. Requires 64HOST.fth. Load before GEN pack.
\ Names stored UPPERCASE; SYM-FIND and G' are case-insensitive.

TCOM-ANEW 64DIR

FORTH DEFINITIONS
DECIMAL

0 CONSTANT SYM-NONE
1 CONSTANT SYM-TARGET
2 CONSTANT SYM-LIBRARY
3 CONSTANT SYM-CODE
4 CONSTANT SYM-FORWARD

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

: SYM-UPC  ( c -- c' )
  DUP [CHAR] a [CHAR] z WITHIN IF  32 -  THEN
  ;

\ Store counted name UPPERCASE into slot i
: SYM-PUT-NAME  ( c-addr u i -- )
  >R
  31 MIN
  DUP R@ SYM-NBUF C!
  0 ?DO
    DUP I + C@ SYM-UPC
    R@ SYM-NBUF 1+ I + C!
  LOOP
  DROP R> DROP
  ;

: SYM-GET-NAME  ( i -- c-addr u )  SYM-NBUF COUNT ;

\ Case-insensitive string equality (ca1 u1) (ca2 u2)
: SYM-STR=  ( ca1 u1 ca2 u2 -- flag )
  \ Compare two strings case-insensitively
  ROT OVER <> IF                   \ ( ca1 ca2 u2 u1 ) then u1 u2 <>
    2DROP DROP FALSE EXIT          \ ( ca1 ca2 u2 ) after IF consumed flag
  THEN                             \ ( ca1 ca2 u )
  0 ?DO
    OVER I + C@ SYM-UPC
    OVER I + C@ SYM-UPC
    <> IF  2DROP UNLOOP FALSE EXIT  THEN
  LOOP
  2DROP TRUE
  ;

: SYM-NAME=  ( c-addr u i -- flag )
  SYM-GET-NAME SYM-STR=
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
: SYM-ADD
  PAD CELL+ !                      \ addr
  PAD !                            \ type
  2DUP SYM-FIND IF                 \ ca u i
    NIP NIP
    PAD @ OVER SYM-TYPE!
    PAD CELL+ @ OVER SYM-ADDR!
    EXIT
  THEN
  SYM-N @ SYM-MAX U>= IF
    2DROP S" Symbol table full" TCOM-ABORT
  THEN
  SYM-N @ SYM-PUT-NAME
  PAD @       SYM-N @ SYM-TYPE!
  PAD CELL+ @ SYM-N @ SYM-ADDR!
  0           SYM-N @ SYM-USES!
  SYM-N @
  1 SYM-N +!
  ;

: SYM-ADD-LAST  ( type addr -- i )
  LAST NAME>STRING 2SWAP SYM-ADD
  ;

: SYM-REG-LIB  ( cookie -- )
  SYM-LIBRARY SWAP
  SYM-ADD-LAST DROP
  ;

: .SYM-TYPE  ( type -- )
  DUP SYM-TARGET  = IF DROP S" TARGET" TYPE EXIT THEN
  DUP SYM-LIBRARY = IF DROP S" LIB" TYPE EXIT THEN
  DUP SYM-CODE    = IF DROP S" CODE" TYPE EXIT THEN
  DUP SYM-FORWARD = IF DROP S" FWD" TYPE EXIT THEN
  DROP S" ?" TYPE
  ;

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

: .SYMA  ( -- )
  S" SYMA raw (first 16):" TYPE CR
  SYM-N @ 0 MAX 16 MIN 0 ?DO
    I 3 .R S" : " TYPE
    I CELLS SYMA + @ SYM-HEX. CR
  LOOP
  ;

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
    TYPE S"  ?" TYPE CR
    S" unknown symbol" TCOM-ABORT
  THEN
  NIP NIP
  DUP SYM-USE+
  SYM-ADDR@ COMP-CALL
  ;

: LIB,  ( xt -- )
  EXECUTE                             ( cookie )
  DUP >R
  SYM-N @ 0 DO
    I SYM-ADDR@ R@ = IF  I SYM-USE+  LEAVE  THEN
  LOOP
  R> COMP-CALL
  ;

DEFER DIR-ON-TARGET-INIT
: (DIR-ON-TARGET-INIT-NOOP) ( -- )  ;
' (DIR-ON-TARGET-INIT-NOOP) IS DIR-ON-TARGET-INIT

: .DIR  ( -- )
  S" 64DIR Phase 1.2 — symbols + thin director" TYPE CR
  S"   T: ;T L: ;L GCODE G, GCALL GJMP G' LIB, .SYMBOLS" TYPE CR
  .SYMBOLS
  ;

: SYM-SMOKE  ( -- )
  SYM-CLEAR
  S" AAA" SYM-LIBRARY $8000 SYM-ADD DROP
  S" BBB" SYM-LIBRARY $8008 SYM-ADD DROP
  S" CCC" SYM-TARGET  $0001 SYM-ADD DROP
  0 SYM-ADDR@ $8000 <> IF S" SYM-SMOKE fail0" TYPE CR ABORT THEN
  1 SYM-ADDR@ $8008 <> IF S" SYM-SMOKE fail1" TYPE CR ABORT THEN
  2 SYM-ADDR@ $0001 <> IF S" SYM-SMOKE fail2" TYPE CR ABORT THEN
  \ case-insensitive find
  S" aaa" SYM-FIND 0= IF S" SYM-SMOKE casefail" TYPE CR ABORT THEN DROP
  S" SYM-SMOKE: OK" TYPE CR
  SYM-CLEAR
  ;

FORTH DEFINITIONS
SYM-CLEAR
SYM-SMOKE
S" 64DIR loaded (symbol table + director)." TYPE CR
