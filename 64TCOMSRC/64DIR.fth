\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2 / 1.3)
\
\ Public domain. Requires 64HOST.fth. Load before GEN pack.
\
\ NO {: :} locals in this file. 64Forth locals have been unreliable here
\ (undefined: out / flag / ix; results not returned). Use data stack +
\ VARIABLEs only. Also no >R (corrupts DO LOOP / I).
\
\ Phase 1.3: forward refs, resolve chains, .UNRES, options, LIB-AUTO-INCLUDE

TCOM-ANEW 64DIR

FORTH DEFINITIONS
DECIMAL

0 CONSTANT SYM-NONE
1 CONSTANT SYM-TARGET
2 CONSTANT SYM-LIBRARY
3 CONSTANT SYM-CODE
4 CONSTANT SYM-FORWARD

-1 CONSTANT SYM-NO-CHAIN

256 CONSTANT SYM-MAX
32  CONSTANT /SNAME

CREATE SYMT  SYM-MAX CELLS ALLOT
CREATE SYMA  SYM-MAX CELLS ALLOT
CREATE SYMU  SYM-MAX CELLS ALLOT
CREATE SYMN  SYM-MAX /SNAME * ALLOT
VARIABLE SYM-N
0 SYM-N !

\ Scratch (never live across public API calls that re-enter)
VARIABLE SYM-I
VARIABLE SYM-K
VARIABLE SYM-A
VARIABLE SYM-B
VARIABLE SYM-C
VARIABLE SYM-T
VARIABLE SYM-U
VARIABLE SYM-X
VARIABLE SYM-Y
VARIABLE SYM-Z

: SYM-CLEAR  ( -- )
  0 SYM-N !
  SYMT SYM-MAX CELLS ERASE
  SYMA SYM-MAX CELLS ERASE
  SYMU SYM-MAX CELLS ERASE
  SYMN SYM-MAX /SNAME * ERASE
  FALSE TO ?UNRES
  ;

: SYM-COUNT  ( -- n )  SYM-N @ ;

: SYM-TYPE@  ( i -- n )  CELLS SYMT + @ ;
: SYM-ADDR@  ( i -- n )  CELLS SYMA + @ ;
: SYM-USES@  ( i -- n )  CELLS SYMU + @ ;

: SYM-TYPE!  ( n i -- )  CELLS SYMT + ! ;
: SYM-ADDR!  ( n i -- )  CELLS SYMA + ! ;
: SYM-USES!  ( n i -- )  CELLS SYMU + ! ;

: SYM-USE+  ( i -- )
  DUP SYM-USES@ 1+ SWAP SYM-USES!
  ;

: SYM-NBUF  ( i -- a )  /SNAME * SYMN + ;

: SYM-UPC  ( c -- c2 )
  DUP [CHAR] a >= OVER [CHAR] z <= AND IF  32 -  THEN
  ;

: SYM-PUT-NAME  ( src u i -- )
  SYM-X !                          \ i
  31 MIN SYM-U !                   \ u clamped
  SYM-A !                          \ src
  SYM-X @ SYM-NBUF SYM-B !         \ dest
  SYM-U @ SYM-B @ C!
  0 SYM-I !
  BEGIN SYM-I @ SYM-U @ < WHILE
    SYM-A @ SYM-I @ + C@ SYM-UPC
    SYM-B @ 1+ SYM-I @ + C!
    1 SYM-I +!
  REPEAT
  ;

: SYM-GET-NAME  ( i -- addr len )
  SYM-NBUF COUNT
  ;

: SYM-STR=  ( a1 u1 a2 u2 -- tf )
  SYM-U !                          \ u2
  SYM-B !                          \ a2
  SYM-K !                          \ u1
  SYM-A !                          \ a1
  SYM-K @ SYM-U @ <> IF FALSE EXIT THEN
  0 SYM-I !
  BEGIN SYM-I @ SYM-K @ < WHILE
    SYM-A @ SYM-I @ + C@ SYM-UPC
    SYM-B @ SYM-I @ + C@ SYM-UPC
    <> IF FALSE EXIT THEN
    1 SYM-I +!
  REPEAT
  TRUE
  ;

: SYM-NAME=  ( ca u i -- tf )
  SYM-GET-NAME SYM-STR=
  ;

: SYM-FIND  ( c-addr u -- ix true | false )
  SYM-U !                          \ u
  SYM-A !                          \ ca
  SYM-N @ 0= IF FALSE EXIT THEN
  0 SYM-I !
  BEGIN SYM-I @ SYM-N @ < WHILE
    SYM-A @ SYM-U @ SYM-I @ SYM-NAME= IF
      SYM-I @ TRUE EXIT
    THEN
    1 SYM-I +!
  REPEAT
  FALSE
  ;

: SYM-FIND-IX  ( c-addr u -- ix )
  SYM-FIND IF EXIT THEN
  S" symbol not found in table" TCOM-ABORT
  ;

: SYM-ADD  ( c-addr u type addr -- ix )
  SYM-Z !                          \ addr
  SYM-T !                          \ type
  SYM-U !                          \ u
  SYM-A !                          \ ca
  SYM-A @ SYM-U @ SYM-FIND IF      \ ix
    DUP SYM-T @ SWAP SYM-TYPE!
    DUP SYM-Z @ SWAP SYM-ADDR!
    EXIT
  THEN
  SYM-N @ SYM-MAX U>= IF
    S" Symbol table full" TCOM-ABORT
  THEN
  SYM-N @                          \ new ix
  SYM-A @ SYM-U @  2 PICK  SYM-PUT-NAME
  DUP SYM-T @ SWAP SYM-TYPE!
  DUP SYM-Z @ SWAP SYM-ADDR!
  DUP 0 SWAP SYM-USES!
  1 SYM-N +!
  ;

: SYM-RESOLVE-TO  ( ix final typ -- )
  SYM-T !                          \ typ
  SYM-Y !                          \ final
  SYM-X !                          \ ix
  SYM-X @ SYM-TYPE@ SYM-FORWARD = IF
    SYM-X @ SYM-ADDR@ SYM-A !      \ site = chain head
    BEGIN SYM-A @ SYM-NO-CHAIN <> WHILE
      SYM-A @ @-T SYM-B !          \ next
      SYM-A @ SYM-Y @ RESOLVE-1
      SYM-B @ SYM-A !
    REPEAT
  THEN
  SYM-Y @ SYM-X @ SYM-ADDR!
  SYM-T @ SYM-X @ SYM-TYPE!
  ;

: SYM-DEFINE  ( c-addr u type addr -- ix )
  SYM-Z !                          \ addr
  SYM-T !                          \ type
  2DUP SYM-FIND IF                 \ ca u ix
    SYM-X !                        \ ix
    2DROP
    SYM-X @ SYM-TYPE@ SYM-FORWARD = IF
      SYM-X @ SYM-Z @ SYM-T @ SYM-RESOLVE-TO
    ELSE
      SYM-T @ SYM-X @ SYM-TYPE!
      SYM-Z @ SYM-X @ SYM-ADDR!
    THEN
    SYM-X @
  ELSE
    SYM-T @ SYM-Z @ SYM-ADD
  THEN
  ;

: SYM-DEFINE-LAST  ( type addr -- ix )
  SYM-Z ! SYM-T !
  LAST NAME>STRING
  SYM-T @ SYM-Z @ SYM-DEFINE
  ;

: SYM-ADD-LAST  ( type addr -- ix )  SYM-DEFINE-LAST ;

: SYM-REG-LIB  ( cookie -- )
  SYM-LIBRARY SWAP SYM-ADD-LAST DROP
  ;

: SYM-HEX.  ( u -- )
  BASE @ SYM-A !
  HEX
  0 <# #S #> TYPE SPACE
  SYM-A @ BASE !
  ;

: SYM-COMPILE-REF  ( ix -- )
  DUP SYM-USE+
  DUP SYM-TYPE@ SYM-FORWARD = IF
    0 COMP-CALL
    HERE-T T-CELL - SYM-A !        \ site
    DUP SYM-ADDR@ SYM-B !          \ old head  (ix still under)
    SYM-B @ SYM-A @ !-T
    SYM-A @ SWAP SYM-ADDR!         \ ix
    ?SHOW IF
      S"   [fwd fixup @" TYPE SYM-A @ SYM-HEX. S" ]" TYPE CR
    THEN
  ELSE
    SYM-ADDR@ COMP-CALL
  THEN
  ;

: SYM-UNRES-COUNT  ( -- n )
  0
  0 SYM-I !
  BEGIN SYM-I @ SYM-N @ < WHILE
    SYM-I @ SYM-TYPE@ SYM-FORWARD = IF 1+ THEN
    1 SYM-I +!
  REPEAT
  ;

: .UNRES  ( -- )
  S" Unresolved forward references:" TYPE CR
  0 SYM-A !
  0 SYM-I !
  BEGIN SYM-I @ SYM-N @ < WHILE
    SYM-I @ SYM-TYPE@ SYM-FORWARD = IF
      S"   " TYPE SYM-I @ SYM-GET-NAME TYPE
      S"  uses=" TYPE SYM-I @ SYM-USES@ 0 .R
      S"  chain@" TYPE SYM-I @ SYM-ADDR@ SYM-HEX. CR
      1 SYM-A +!
    THEN
    1 SYM-I +!
  REPEAT
  SYM-A @ 0= IF S"   (none)" TYPE CR THEN
  ;

: SYM-CHECK-UNRES  ( -- )
  SYM-UNRES-COUNT IF
    TRUE TO ?UNRES
    .UNRES
    ?FWDABORT IF
      S" Unresolved forward references" TCOM-ABORT
    THEN
  ELSE
    FALSE TO ?UNRES
  THEN
  ;

DEFER LIB-AUTO-INCLUDE
: (LIB-AUTO-NONE)  ( ca u -- false )  2DROP FALSE ;
' (LIB-AUTO-NONE) IS LIB-AUTO-INCLUDE

: .SYM-TYPE  ( typ -- )
  DUP SYM-TARGET  = IF DROP S" TARGET" TYPE EXIT THEN
  DUP SYM-LIBRARY = IF DROP S" LIB" TYPE EXIT THEN
  DUP SYM-CODE    = IF DROP S" CODE" TYPE EXIT THEN
  DUP SYM-FORWARD = IF DROP S" FWD" TYPE EXIT THEN
  DROP S" ?" TYPE
  ;

: .SYMBOLS  ( -- )
  S" Symbols: " TYPE SYM-COUNT 0 .R S"  / " TYPE SYM-MAX 0 .R CR
  SYM-COUNT 0= IF S"   (none)" TYPE CR EXIT THEN
  0 SYM-I !
  BEGIN SYM-I @ SYM-COUNT < WHILE
    SYM-I @ 3 .R SPACE
    SYM-I @ SYM-GET-NAME TYPE
    16 SYM-I @ SYM-NBUF C@ - 0 MAX SPACES
    SYM-I @ SYM-TYPE@ .SYM-TYPE
    S"  @ " TYPE
    SYM-I @ SYM-ADDR@ SYM-HEX.
    S" uses=" TYPE SYM-I @ SYM-USES@ 0 .R CR
    1 SYM-I +!
  REPEAT
  ;

: .SYMA  ( -- )
  S" SYMA raw (first 16):" TYPE CR
  0 SYM-I !
  BEGIN SYM-I @ SYM-N @ < SYM-I @ 16 < AND WHILE
    SYM-I @ 3 .R S" : " TYPE
    SYM-I @ SYM-ADDR@ SYM-HEX. CR
    1 SYM-I +!
  REPEAT
  ;

: ?INTERPRET-ONLY  ( ca u -- )
  STATE @ IF TCOM-ABORT ELSE 2DROP THEN
  ;

: (T-COOKIE)  ( taddr -- )
  CREATE , DOES> @
  ;

: T:  ( "<spaces>name" -- )
  S" T: is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  START-T:
  HERE-T SYM-A !
  SYM-A @ (T-COOKIE)
  LAST NAME>STRING
  ?QUIET 0= IF 2DUP TYPE CR THEN
  2DUP PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  SYM-TARGET SYM-A @ SYM-DEFINE-LAST DROP
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
  HERE-T SYM-A !
  SYM-A @ (T-COOKIE)
  LAST NAME>STRING
  ?QUIET 0= IF 2DUP TYPE CR THEN
  2DUP PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  SYM-LIBRARY SYM-A @ SYM-DEFINE-LAST DROP
  ;

: ;L  ( -- )
  END-L:
  FALSE TO ?LIB
  ; IMMEDIATE

: GCODE  ( "<spaces>name" -- )
  S" GCODE is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  TCODE-START
  HERE-T SYM-A !
  SYM-A @ (T-COOKIE)
  LAST NAME>STRING
  ?QUIET 0= IF 2DUP TYPE CR THEN
  2DUP PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  SYM-CODE SYM-A @ SYM-DEFINE-LAST DROP
  SETASSEM
  ;

: G,    ( n -- )     COMP-SINGLE ;
: GCALL ( addr -- )  COMP-CALL ;
: GJMP  ( addr -- )  COMP-JMP-IMM ;

: G'  ( "<spaces>name" -- )
  BL WORD COUNT                 \ ca u
  2DUP SYM-FIND IF              \ ca u ix
    NIP NIP                     \ ix
  ELSE
    2DUP LIB-AUTO-INCLUDE IF    \ ca u ix
      NIP NIP
    ELSE
      ?LIB IF
        TYPE S"  ?" TYPE CR
        S" forward reference not allowed in library" TCOM-ABORT
      THEN
      2DUP SYM-FORWARD SYM-NO-CHAIN SYM-ADD   \ ca u ix
      ?QUIET 0= IF
        S" Forward: " TYPE
        ROT ROT TYPE CR
      ELSE
        ROT ROT 2DROP
      THEN
    THEN
  THEN
  SYM-COMPILE-REF
  ;

: LIB,  ( xt -- )
  EXECUTE SYM-A !                  \ cookie
  0 SYM-I !
  BEGIN SYM-I @ SYM-N @ < WHILE
    SYM-I @ SYM-ADDR@ SYM-A @ = IF SYM-I @ SYM-USE+ THEN
    1 SYM-I +!
  REPEAT
  SYM-A @ COMP-CALL
  ;

DEFER DIR-ON-TARGET-INIT
: (DIR-ON-TARGET-INIT-NOOP) ( -- )  ;
' (DIR-ON-TARGET-INIT-NOOP) IS DIR-ON-TARGET-INIT

DEFER DIR-ON-FINISH
: (DIR-ON-FINISH)  ( -- )  SYM-CHECK-UNRES ;
' (DIR-ON-FINISH) IS DIR-ON-FINISH

: .DIR  ( -- )
  S" 64DIR Phase 1.3 — symbols, forward refs, resolve (no locals)" TYPE CR
  S"   T: ;T L: ;L GCODE G, GCALL GJMP G' LIB, .SYMBOLS .UNRES .OPTIONS" TYPE CR
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
  S"  slot0=[" TYPE 0 SYM-GET-NAME TYPE S" ]" TYPE CR
  S" aaa" SYM-FIND-IX DROP
  S" AaA" SYM-FIND-IX DROP
  S" LATER" SYM-FORWARD SYM-NO-CHAIN SYM-ADD DROP
  S" later" SYM-FIND-IX DROP
  SYM-UNRES-COUNT 1 <> IF S" SYM-SMOKE unrescnt" TYPE CR ABORT THEN
  S" SYM-SMOKE: OK" TYPE CR
  SYM-CLEAR
  ;

FORTH DEFINITIONS
SYM-CLEAR
SYM-SMOKE
S" 64DIR loaded (Phase 1.3 director + forwards)." TYPE CR
