\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2)
\
\ Public domain. Requires 64HOST.fth. Load before GEN pack.
\
\ Prefer ANS locals {: name -- out :} over >R/R@ (avoids DO LOOP collisions).

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

: SYM-TYPE@  {: i -- n :}  i CELLS SYMT + @ TO n ;
: SYM-ADDR@  {: i -- n :}  i CELLS SYMA + @ TO n ;
: SYM-USES@  {: i -- n :}  i CELLS SYMU + @ TO n ;

: SYM-TYPE!  {: n i :}  n i CELLS SYMT + ! ;
: SYM-ADDR!  {: n i :}  n i CELLS SYMA + ! ;
: SYM-USES!  {: n i :}  n i CELLS SYMU + ! ;

: SYM-USE+  {: i | v :}
  i SYM-USES@ 1+ TO v
  v i SYM-USES!
  ;

: SYM-NBUF  {: i -- a :}  i /SNAME * SYMN + TO a ;

: SYM-UPC  {: c -- c2 :}
  c [CHAR] a >= c [CHAR] z <= AND IF
    c 32 - TO c2
  ELSE
    c TO c2
  THEN
  ;

: SYM-PUT-NAME  {: src u i | dest lim k ch :}
  u 31 MIN TO lim
  i SYM-NBUF TO dest
  lim dest C!
  0 TO k
  BEGIN k lim < WHILE
    src k + C@ SYM-UPC TO ch
    ch dest 1+ k + C!
    k 1+ TO k
  REPEAT
  ;

: SYM-GET-NAME  {: i -- addr len :}
  i SYM-NBUF COUNT TO len TO addr
  ;

: SYM-STR=  {: a1 u1 a2 u2 | k c1 c2 -- flag :}
  u1 u2 <> IF FALSE TO flag EXIT THEN
  0 TO k
  BEGIN k u1 < WHILE
    a1 k + C@ SYM-UPC TO c1
    a2 k + C@ SYM-UPC TO c2
    c1 c2 <> IF FALSE TO flag EXIT THEN
    k 1+ TO k
  REPEAT
  TRUE TO flag
  ;

: SYM-NAME=  {: ca u i | a2 u2 -- flag :}
  i SYM-GET-NAME TO u2 TO a2
  ca u a2 u2 SYM-STR= TO flag
  ;

\ Returns ix and found-flag on stack (not only locals) for callers that IF
: SYM-FIND  ( c-addr u -- ix true | false )
  {: ca u | i :}
  SYM-N @ 0= IF FALSE EXIT THEN
  0 TO i
  BEGIN i SYM-N @ < WHILE
    ca u i SYM-NAME= IF i TRUE EXIT THEN
    i 1+ TO i
  REPEAT
  FALSE
  ;

: SYM-ADD  ( c-addr u type addr -- ix )
  {: ca u typ adr | i :}
  ca u SYM-FIND IF                     \ ix true
    TO i                               \ ix -> i  (flag already consumed by IF)
    typ i SYM-TYPE!
    adr i SYM-ADDR!
    i EXIT
  THEN
  \ not found — flag false was consumed; nothing else on stack from FIND
  SYM-N @ SYM-MAX U>= IF
    S" Symbol table full" TCOM-ABORT
  THEN
  SYM-N @ TO i
  ca u i SYM-PUT-NAME
  typ i SYM-TYPE!
  adr i SYM-ADDR!
  0 i SYM-USES!
  1 SYM-N +!
  i
  ;

: SYM-ADD-LAST  ( type addr -- ix )
  {: typ adr | ca u :}
  LAST NAME>STRING TO u TO ca
  ca u typ adr SYM-ADD
  ;

: SYM-REG-LIB  ( cookie -- )
  {: cookie :}
  SYM-LIBRARY cookie SYM-ADD-LAST DROP
  ;

: .SYM-TYPE  {: typ :}
  typ SYM-TARGET  = IF S" TARGET" TYPE EXIT THEN
  typ SYM-LIBRARY = IF S" LIB" TYPE EXIT THEN
  typ SYM-CODE    = IF S" CODE" TYPE EXIT THEN
  typ SYM-FORWARD = IF S" FWD" TYPE EXIT THEN
  S" ?" TYPE
  ;

: SYM-HEX.  {: u | old :}
  BASE @ TO old
  HEX
  u 0 <# #S #> TYPE SPACE
  old BASE !
  ;

: .SYMBOLS  ( -- )
  {: i :}
  S" Symbols: " TYPE SYM-COUNT 0 .R S"  / " TYPE SYM-MAX 0 .R CR
  SYM-COUNT 0= IF S"   (none)" TYPE CR EXIT THEN
  0 TO i
  BEGIN i SYM-COUNT < WHILE
    i 3 .R SPACE
    i SYM-GET-NAME TYPE
    16 i SYM-NBUF C@ - 0 MAX SPACES
    i SYM-TYPE@ .SYM-TYPE
    S"  @ " TYPE
    i SYM-ADDR@ SYM-HEX.
    S" uses=" TYPE i SYM-USES@ 0 .R CR
    i 1+ TO i
  REPEAT
  ;

: .SYMA  ( -- )
  {: i :}
  S" SYMA raw (first 16):" TYPE CR
  0 TO i
  BEGIN i SYM-N @ < i 16 < AND WHILE
    i 3 .R S" : " TYPE
    i SYM-ADDR@ SYM-HEX. CR
    i 1+ TO i
  REPEAT
  ;

: ?INTERPRET-ONLY  {: ca u :}
  STATE @ IF ca u TCOM-ABORT THEN
  ;

: (T-COOKIE)  ( taddr -- )
  CREATE , DOES> @
  ;

: T:  ( "<spaces>name" -- )
  {: | tadr ca u :}
  S" T: is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  START-T:
  HERE-T TO tadr
  tadr (T-COOKIE)
  LAST NAME>STRING TO u TO ca
  ?QUIET 0= IF ca u TYPE CR THEN
  ca u PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  SYM-TARGET tadr SYM-ADD-LAST DROP
  TRUE TO ?INTERPRETIVE
  ;

: ;T  ( -- )
  END-T:
  FALSE TO ?INTERPRETIVE
  ; IMMEDIATE

: L:  ( "<spaces>name" -- )
  {: | tadr ca u :}
  S" L: is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  TRUE TO ?LIB
  START-L:
  HERE-T TO tadr
  tadr (T-COOKIE)
  LAST NAME>STRING TO u TO ca
  ?QUIET 0= IF ca u TYPE CR THEN
  ca u PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  SYM-LIBRARY tadr SYM-ADD-LAST DROP
  ;

: ;L  ( -- )
  END-L:
  FALSE TO ?LIB
  ; IMMEDIATE

: GCODE  ( "<spaces>name" -- )
  {: | tadr ca u :}
  S" GCODE is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  TCODE-START
  HERE-T TO tadr
  tadr (T-COOKIE)
  LAST NAME>STRING TO u TO ca
  ?QUIET 0= IF ca u TYPE CR THEN
  ca u PAD 2 CELLS + PLACE
  PAD 2 CELLS + COMP-HEADER
  SYM-CODE tadr SYM-ADD-LAST DROP
  SETASSEM
  ;

: G,    ( n -- )     COMP-SINGLE ;
: GCALL ( addr -- )  COMP-CALL ;
: GJMP  ( addr -- )  COMP-JMP-IMM ;

: G'  ( "<spaces>name" -- )
  {: | ca u ix :}
  BL WORD COUNT TO u TO ca
  ca u SYM-FIND 0= IF
    ca u TYPE S"  ?" TYPE CR
    S" unknown symbol" TCOM-ABORT
  THEN
  TO ix
  ix SYM-USE+
  ix SYM-ADDR@ COMP-CALL
  ;

: LIB,  ( xt -- )
  {: xt | cookie i :}
  xt EXECUTE TO cookie
  0 TO i
  BEGIN i SYM-N @ < WHILE
    i SYM-ADDR@ cookie = IF i SYM-USE+ THEN
    i 1+ TO i
  REPEAT
  cookie COMP-CALL
  ;

DEFER DIR-ON-TARGET-INIT
: (DIR-ON-TARGET-INIT-NOOP) ( -- )  ;
' (DIR-ON-TARGET-INIT-NOOP) IS DIR-ON-TARGET-INIT

: .DIR  ( -- )
  S" 64DIR Phase 1.2 — symbols + thin director (locals style)" TYPE CR
  S"   T: ;T L: ;L GCODE G, GCALL GJMP G' LIB, .SYMBOLS" TYPE CR
  .SYMBOLS
  ;

: SYM-SMOKE  ( -- )
  {: ix :}
  SYM-CLEAR
  S" AAA" SYM-LIBRARY $8000 SYM-ADD DROP
  S" BBB" SYM-LIBRARY $8008 SYM-ADD DROP
  S" CCC" SYM-TARGET  $0001 SYM-ADD DROP
  0 SYM-ADDR@ $8000 <> IF S" SYM-SMOKE fail0" TYPE CR ABORT THEN
  1 SYM-ADDR@ $8008 <> IF S" SYM-SMOKE fail1" TYPE CR ABORT THEN
  2 SYM-ADDR@ $0001 <> IF S" SYM-SMOKE fail2" TYPE CR ABORT THEN
  S"  slot0=[" TYPE 0 SYM-GET-NAME TYPE S" ]" TYPE CR
  S" aaa" SYM-FIND 0= IF S" SYM-SMOKE casefail" TYPE CR ABORT THEN DROP
  S" AaA" SYM-FIND 0= IF S" SYM-SMOKE casefail2" TYPE CR ABORT THEN DROP
  S" SYM-SMOKE: OK" TYPE CR
  SYM-CLEAR
  ;

FORTH DEFINITIONS
SYM-CLEAR
SYM-SMOKE
S" 64DIR loaded (symbol table + director)." TYPE CR
