\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2 / 1.3)
\
\ Public domain. Requires 64HOST.fth. Load before GEN pack.
\
\ No {: :} locals (unreliable on this 64Forth). No >R.
\ Scratch VARIABLEs are partitioned so nested calls never clobber
\ a caller's loop index (SYM-FIND vs SYM-STR= hung the system).

S" [64DIR] start" TYPE CR

TCOM-ANEW 64DIR

FORTH DEFINITIONS
DECIMAL

S" [64DIR] tables..." TYPE CR

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

\ --- scratch: SYM-FIND (must not overlap SYM-STR= / SYM-PUT-NAME) ---
VARIABLE F-CA
VARIABLE F-U
VARIABLE F-I

\ --- scratch: SYM-STR= ---
VARIABLE S-A1
VARIABLE S-U1
VARIABLE S-A2
VARIABLE S-U2
VARIABLE S-I

\ --- scratch: SYM-PUT-NAME ---
VARIABLE P-SRC
VARIABLE P-U
VARIABLE P-I
VARIABLE P-DST
VARIABLE P-K

\ --- scratch: define / resolve / compile / misc ---
VARIABLE D-CA
VARIABLE D-U
VARIABLE D-TYP
VARIABLE D-ADR
VARIABLE D-IX
VARIABLE R-IX
VARIABLE R-FIN
VARIABLE R-TYP
VARIABLE R-SITE
VARIABLE R-NEXT
VARIABLE C-IX
VARIABLE C-SITE
VARIABLE C-OLD
VARIABLE M-I
VARIABLE M-N
VARIABLE M-BASE
VARIABLE M-TMP

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
  P-I !                            \ i
  31 MIN P-U !                     \ u
  P-SRC !                          \ src
  P-I @ SYM-NBUF P-DST !
  P-U @ P-DST @ C!
  0 P-K !
  BEGIN P-K @ P-U @ < WHILE
    P-SRC @ P-K @ + C@ SYM-UPC
    P-DST @ 1+ P-K @ + C!
    1 P-K +!
  REPEAT
  ;

: SYM-GET-NAME  ( i -- addr len )
  SYM-NBUF COUNT
  ;

: SYM-STR=  ( a1 u1 a2 u2 -- tf )
  S-U2 !
  S-A2 !
  S-U1 !
  S-A1 !
  S-U1 @ S-U2 @ <> IF FALSE EXIT THEN
  0 S-I !
  BEGIN S-I @ S-U1 @ < WHILE
    S-A1 @ S-I @ + C@ SYM-UPC
    S-A2 @ S-I @ + C@ SYM-UPC
    <> IF FALSE EXIT THEN
    1 S-I +!
  REPEAT
  TRUE
  ;

: SYM-NAME=  ( ca u i -- tf )
  SYM-GET-NAME SYM-STR=
  ;

: SYM-FIND  ( c-addr u -- ix true | false )
  F-U !
  F-CA !
  SYM-N @ 0= IF FALSE EXIT THEN
  0 F-I !
  BEGIN F-I @ SYM-N @ < WHILE
    F-CA @ F-U @ F-I @ SYM-NAME= IF
      F-I @ TRUE EXIT
    THEN
    1 F-I +!
  REPEAT
  FALSE
  ;

: SYM-FIND-IX  ( c-addr u -- ix )
  SYM-FIND IF EXIT THEN
  S" symbol not found in table" TCOM-ABORT
  ;

: SYM-ADD  ( c-addr u type addr -- ix )
  D-ADR !
  D-TYP !
  D-U !
  D-CA !
  D-CA @ D-U @ SYM-FIND IF         \ ix
    DUP D-TYP @ SWAP SYM-TYPE!
    DUP D-ADR @ SWAP SYM-ADDR!
    EXIT
  THEN
  SYM-N @ SYM-MAX U>= IF
    S" Symbol table full" TCOM-ABORT
  THEN
  SYM-N @                          \ new ix
  D-CA @ D-U @ 2 PICK SYM-PUT-NAME
  DUP D-TYP @ SWAP SYM-TYPE!
  DUP D-ADR @ SWAP SYM-ADDR!
  DUP 0 SWAP SYM-USES!
  1 SYM-N +!
  ;

: SYM-RESOLVE-TO  ( ix final typ -- )
  R-TYP !
  R-FIN !
  R-IX !
  R-IX @ SYM-TYPE@ SYM-FORWARD = IF
    R-IX @ SYM-ADDR@ R-SITE !
    BEGIN R-SITE @ SYM-NO-CHAIN <> WHILE
      R-SITE @ @-T R-NEXT !
      R-SITE @ R-FIN @ RESOLVE-1
      R-NEXT @ R-SITE !
    REPEAT
  THEN
  R-FIN @ R-IX @ SYM-ADDR!
  R-TYP @ R-IX @ SYM-TYPE!
  ;

: SYM-DEFINE  ( c-addr u type addr -- ix )
  D-ADR !
  D-TYP !
  2DUP SYM-FIND IF                 \ ca u ix
    D-IX !
    2DROP
    D-IX @ SYM-TYPE@ SYM-FORWARD = IF
      D-IX @ D-ADR @ D-TYP @ SYM-RESOLVE-TO
    ELSE
      D-TYP @ D-IX @ SYM-TYPE!
      D-ADR @ D-IX @ SYM-ADDR!
    THEN
    D-IX @
  ELSE                             \ ca u
    D-TYP @ D-ADR @ SYM-ADD
  THEN
  ;

: SYM-DEFINE-LAST  ( type addr -- ix )
  D-ADR ! D-TYP !
  LAST NAME>STRING
  D-TYP @ D-ADR @ SYM-DEFINE
  ;

: SYM-ADD-LAST  ( type addr -- ix )  SYM-DEFINE-LAST ;

: SYM-REG-LIB  ( cookie -- )
  SYM-LIBRARY SWAP SYM-ADD-LAST DROP
  ;

: SYM-HEX.  ( u -- )
  BASE @ M-BASE !
  HEX
  0 <# #S #> TYPE SPACE
  M-BASE @ BASE !
  ;

: SYM-COMPILE-REF  ( ix -- )
  DUP SYM-USE+
  DUP SYM-TYPE@ SYM-FORWARD = IF
    0 COMP-CALL
    HERE-T T-CELL - C-SITE !
    DUP SYM-ADDR@ C-OLD !
    C-OLD @ C-SITE @ !-T
    C-SITE @ SWAP SYM-ADDR!
    ?SHOW IF
      S"   [fwd fixup @" TYPE C-SITE @ SYM-HEX. S" ]" TYPE CR
    THEN
  ELSE
    SYM-ADDR@ COMP-CALL
  THEN
  ;

: SYM-UNRES-COUNT  ( -- n )
  0
  0 M-I !
  BEGIN M-I @ SYM-N @ < WHILE
    M-I @ SYM-TYPE@ SYM-FORWARD = IF 1+ THEN
    1 M-I +!
  REPEAT
  ;

: .UNRES  ( -- )
  S" Unresolved forward references:" TYPE CR
  0 M-N !
  0 M-I !
  BEGIN M-I @ SYM-N @ < WHILE
    M-I @ SYM-TYPE@ SYM-FORWARD = IF
      S"   " TYPE M-I @ SYM-GET-NAME TYPE
      S"  uses=" TYPE M-I @ SYM-USES@ 0 .R
      S"  chain@" TYPE M-I @ SYM-ADDR@ SYM-HEX. CR
      1 M-N +!
    THEN
    1 M-I +!
  REPEAT
  M-N @ 0= IF S"   (none)" TYPE CR THEN
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
  0 M-I !
  BEGIN M-I @ SYM-COUNT < WHILE
    M-I @ 3 .R SPACE
    M-I @ SYM-GET-NAME TYPE
    16 M-I @ SYM-NBUF C@ - 0 MAX SPACES
    M-I @ SYM-TYPE@ .SYM-TYPE
    S"  @ " TYPE
    M-I @ SYM-ADDR@ SYM-HEX.
    S" uses=" TYPE M-I @ SYM-USES@ 0 .R CR
    1 M-I +!
  REPEAT
  ;

: .SYMA  ( -- )
  S" SYMA raw (first 16):" TYPE CR
  0 M-I !
  BEGIN M-I @ SYM-N @ < M-I @ 16 < AND WHILE
    M-I @ 3 .R S" : " TYPE
    M-I @ SYM-ADDR@ SYM-HEX. CR
    1 M-I +!
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
  HERE-T M-TMP !
  M-TMP @ (T-COOKIE)
  LAST NAME>STRING
  ?QUIET 0= IF 2DUP TYPE CR THEN
  2DUP PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  2DROP
  SYM-TARGET M-TMP @ SYM-DEFINE-LAST DROP
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
  HERE-T M-TMP !
  M-TMP @ (T-COOKIE)
  LAST NAME>STRING
  ?QUIET 0= IF 2DUP TYPE CR THEN
  2DUP PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  2DROP
  SYM-LIBRARY M-TMP @ SYM-DEFINE-LAST DROP
  ;

: ;L  ( -- )
  END-L:
  FALSE TO ?LIB
  ; IMMEDIATE

: GCODE  ( "<spaces>name" -- )
  S" GCODE is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  TCODE-START
  HERE-T M-TMP !
  M-TMP @ (T-COOKIE)
  LAST NAME>STRING
  ?QUIET 0= IF 2DUP TYPE CR THEN
  2DUP PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  2DROP
  SYM-CODE M-TMP @ SYM-DEFINE-LAST DROP
  SETASSEM
  ;

: G,    ( n -- )     COMP-SINGLE ;
: GCALL ( addr -- )  COMP-CALL ;
: GJMP  ( addr -- )  COMP-JMP-IMM ;

: G'  ( "<spaces>name" -- )
  BL WORD COUNT
  2DUP SYM-FIND IF
    NIP NIP
  ELSE
    2DUP LIB-AUTO-INCLUDE IF
      NIP NIP
    ELSE
      ?LIB IF
        TYPE S"  ?" TYPE CR
        S" forward reference not allowed in library" TCOM-ABORT
      THEN
      2DUP SYM-FORWARD SYM-NO-CHAIN SYM-ADD
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
  EXECUTE M-TMP !
  0 M-I !
  BEGIN M-I @ SYM-N @ < WHILE
    M-I @ SYM-ADDR@ M-TMP @ = IF M-I @ SYM-USE+ THEN
    1 M-I +!
  REPEAT
  M-TMP @ COMP-CALL
  ;

DEFER DIR-ON-TARGET-INIT
: (DIR-ON-TARGET-INIT-NOOP) ( -- )  ;
' (DIR-ON-TARGET-INIT-NOOP) IS DIR-ON-TARGET-INIT

DEFER DIR-ON-FINISH
: (DIR-ON-FINISH)  ( -- )  SYM-CHECK-UNRES ;
' (DIR-ON-FINISH) IS DIR-ON-FINISH

: .DIR  ( -- )
  S" 64DIR Phase 1.3 — symbols, forward refs, resolve" TYPE CR
  S"   T: ;T L: ;L GCODE G, GCALL GJMP G' LIB, .SYMBOLS .UNRES .OPTIONS" TYPE CR
  .SYMBOLS
  ;

: SYM-SMOKE  ( -- )
  S" [64DIR] SYM-SMOKE add..." TYPE CR
  SYM-CLEAR
  S" AAA" SYM-LIBRARY $8000 SYM-ADD DROP
  S" BBB" SYM-LIBRARY $8008 SYM-ADD DROP
  S" CCC" SYM-TARGET  $0001 SYM-ADD DROP
  0 SYM-ADDR@ $8000 <> IF S" SYM-SMOKE fail0" TYPE CR ABORT THEN
  1 SYM-ADDR@ $8008 <> IF S" SYM-SMOKE fail1" TYPE CR ABORT THEN
  2 SYM-ADDR@ $0001 <> IF S" SYM-SMOKE fail2" TYPE CR ABORT THEN
  S"  slot0=[" TYPE 0 SYM-GET-NAME TYPE S" ]" TYPE CR
  S" [64DIR] SYM-SMOKE find..." TYPE CR
  S" aaa" SYM-FIND-IX DROP
  S" AaA" SYM-FIND-IX DROP
  S" LATER" SYM-FORWARD SYM-NO-CHAIN SYM-ADD DROP
  S" later" SYM-FIND-IX DROP
  SYM-UNRES-COUNT 1 <> IF S" SYM-SMOKE unrescnt" TYPE CR ABORT THEN
  S" SYM-SMOKE: OK" TYPE CR
  SYM-CLEAR
  ;

FORTH DEFINITIONS
S" [64DIR] run SYM-SMOKE" TYPE CR
SYM-CLEAR
SYM-SMOKE
S" 64DIR loaded (Phase 1.3 director + forwards)." TYPE CR
