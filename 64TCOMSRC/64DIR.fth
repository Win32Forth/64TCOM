\ 64DIR.fth — Thin 64TCOM director + host symbol table (Phase 1.2 / 1.3)
\
\ Public domain. Requires 64HOST.fth. Load before GEN pack.
\
\ Prefer ANS locals over >R/R@ (avoids DO LOOP collisions).
\ 64Forth style that works reliably:
\   {: in1 in2 | temp1 temp2 :}   \ inputs + zeroed temps
\   leave results on the data stack explicitly
\ Avoid mixing  "{: in | temp -- out :}"  (failed as "undefined: out").
\
\ Phase 1.3:
\   • Forward references via G' (SYM-FORWARD + fixup chain in target image)
\   • SYM-DEFINE resolves chain when T:/L:/GCODE defines the name
\   • .UNRES / SYM-CHECK-UNRES at finish; options in 64HOST (.OPTIONS)
\   • LIB-AUTO-INCLUDE hook (default none; packs may install)

TCOM-ANEW 64DIR

FORTH DEFINITIONS
DECIMAL

0 CONSTANT SYM-NONE
1 CONSTANT SYM-TARGET
2 CONSTANT SYM-LIBRARY
3 CONSTANT SYM-CODE
4 CONSTANT SYM-FORWARD

\ Empty fixup chain sentinel (0 is a valid target offset — do not use 0)
-1 CONSTANT SYM-NO-CHAIN

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
  FALSE TO ?UNRES
  ;

: SYM-COUNT  ( -- n )  SYM-N @ ;

: SYM-TYPE@  ( i -- n )
  {: i :}  i CELLS SYMT + @ ;
: SYM-ADDR@  ( i -- n )
  {: i :}  i CELLS SYMA + @ ;
: SYM-USES@  ( i -- n )
  {: i :}  i CELLS SYMU + @ ;

: SYM-TYPE!  ( n i -- )
  {: n i :}  n i CELLS SYMT + ! ;
: SYM-ADDR!  ( n i -- )
  {: n i :}  n i CELLS SYMA + ! ;
: SYM-USES!  ( n i -- )
  {: n i :}  n i CELLS SYMU + ! ;

: SYM-USE+  ( i -- )
  {: i | v :}
  i SYM-USES@ 1+ TO v
  v i SYM-USES!
  ;

: SYM-NBUF  ( i -- a )
  {: i :}  i /SNAME * SYMN + ;

: SYM-UPC  ( c -- c2 )
  {: c | c2 :}
  c [CHAR] a >= c [CHAR] z <= AND IF
    c 32 - TO c2
  ELSE
    c TO c2
  THEN
  c2
  ;

: SYM-PUT-NAME  ( src u i -- )
  {: src u i | dest lim k ch :}
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

: SYM-GET-NAME  ( i -- addr len )
  {: i | addr len :}
  i SYM-NBUF COUNT TO len TO addr
  addr len
  ;

: SYM-STR=  ( a1 u1 a2 u2 -- flag )
  {: a1 u1 a2 u2 | k c1 c2 :}
  u1 u2 <> IF FALSE EXIT THEN
  0 TO k
  BEGIN k u1 < WHILE
    a1 k + C@ SYM-UPC TO c1
    a2 k + C@ SYM-UPC TO c2
    c1 c2 <> IF FALSE EXIT THEN
    k 1+ TO k
  REPEAT
  TRUE
  ;

: SYM-NAME=  ( ca u i -- flag )
  {: ca u i | a2 u2 :}
  i SYM-GET-NAME TO u2 TO a2
  ca u a2 u2 SYM-STR=
  ;

\ Returns ix and found-flag on stack for callers that IF.
\ Important: do not EXIT early from a locals word with items on the stack —
\ 64Forth locals cleanup can scramble ix/true order (broke FWD-DEMO checks).
: SYM-FIND  ( c-addr u -- ix true | false )
  {: ca u | i found :}
  FALSE TO found
  0 TO i
  BEGIN i SYM-N @ < found 0= AND WHILE
    ca u i SYM-NAME= IF
      TRUE TO found
    ELSE
      i 1+ TO i
    THEN
  REPEAT
  found IF i TRUE ELSE FALSE THEN
  ;

\ Found → ix only; missing → message + abort
: SYM-FIND-IX  ( c-addr u -- ix )
  {: ca u | ix :}
  ca u SYM-FIND IF
    TO ix
  ELSE
    S" symbol not found in table" TCOM-ABORT
  THEN
  ix
  ;

: SYM-ADD  ( c-addr u type addr -- ix )
  {: ca u typ adr | i :}
  ca u SYM-FIND IF
    TO i
    typ i SYM-TYPE!
    adr i SYM-ADDR!
  ELSE
    SYM-N @ SYM-MAX U>= IF
      S" Symbol table full" TCOM-ABORT
    THEN
    SYM-N @ TO i
    ca u i SYM-PUT-NAME
    typ i SYM-TYPE!
    adr i SYM-ADDR!
    0 i SYM-USES!
    1 SYM-N +!
  THEN
  i
  ;

\ -----------------------------------------------------------------------------
\ Phase 1.3 — forward reference fixup chains
\
\ For SYM-FORWARD entries, SYMA holds the head of a linked list of patch
\ sites in the target CODE image (each site is the address cell of a GEN
\ CALL tag).  Each site stores the previous head (or SYM-NO-CHAIN).
\ When the name is defined, walk the chain and RESOLVE-1 each site to the
\ final address, then set type+addr to the real definition.
\ -----------------------------------------------------------------------------

: SYM-RESOLVE-TO  ( ix final typ -- )
  {: ix final typ | site next :}
  ix SYM-TYPE@ SYM-FORWARD = IF
    ix SYM-ADDR@ TO site
    BEGIN site SYM-NO-CHAIN <> WHILE
      site @-T TO next
      site final RESOLVE-1
      next TO site
    REPEAT
  THEN
  final ix SYM-ADDR!
  typ ix SYM-TYPE!
  ;

\ Define or redefine: resolve FWD chain if present
: SYM-DEFINE  ( c-addr u type addr -- ix )
  {: ca u typ adr | i :}
  ca u SYM-FIND IF
    TO i
    i SYM-TYPE@ SYM-FORWARD = IF
      i adr typ SYM-RESOLVE-TO
    ELSE
      typ i SYM-TYPE!
      adr i SYM-ADDR!
    THEN
  ELSE
    ca u typ adr SYM-ADD TO i
  THEN
  i
  ;

: SYM-DEFINE-LAST  ( type addr -- ix )
  {: typ adr | ca u :}
  LAST NAME>STRING TO u TO ca
  ca u typ adr SYM-DEFINE
  ;

: SYM-ADD-LAST  ( type addr -- ix )
  SYM-DEFINE-LAST
  ;

: SYM-REG-LIB  ( cookie -- )
  {: cookie :}
  SYM-LIBRARY cookie SYM-ADD-LAST DROP
  ;

: SYM-HEX.  ( u -- )
  {: u | old :}
  BASE @ TO old
  HEX
  u 0 <# #S #> TYPE SPACE
  old BASE !
  ;

\ Compile a call/ref to symbol ix.  Forward: emit CALL + link fixup site.
: SYM-COMPILE-REF  ( ix -- )
  {: ix | site old :}
  ix SYM-USE+
  ix SYM-TYPE@ SYM-FORWARD = IF
    0 COMP-CALL                    \ tag + placeholder cell
    HERE-T T-CELL - TO site        \ address cell of that CALL
    ix SYM-ADDR@ TO old            \ previous chain head
    old site !-T                   \ link
    site ix SYM-ADDR!              \ new head
    ?SHOW IF
      S"   [fwd fixup @" TYPE site SYM-HEX. S" ]" TYPE CR
    THEN
  ELSE
    ix SYM-ADDR@ COMP-CALL
  THEN
  ;

: SYM-UNRES-COUNT  ( -- n )
  {: | i n :}
  0 TO n
  0 TO i
  BEGIN i SYM-N @ < WHILE
    i SYM-TYPE@ SYM-FORWARD = IF n 1+ TO n THEN
    i 1+ TO i
  REPEAT
  n
  ;

: .UNRES  ( -- )
  {: | i n :}
  0 TO n
  S" Unresolved forward references:" TYPE CR
  0 TO i
  BEGIN i SYM-N @ < WHILE
    i SYM-TYPE@ SYM-FORWARD = IF
      S"   " TYPE i SYM-GET-NAME TYPE
      S"  uses=" TYPE i SYM-USES@ 0 .R
      S"  chain@" TYPE i SYM-ADDR@ SYM-HEX. CR
      n 1+ TO n
    THEN
    i 1+ TO i
  REPEAT
  n 0= IF S"   (none)" TYPE CR THEN
  ;

: SYM-CHECK-UNRES  ( -- )
  {: | n :}
  SYM-UNRES-COUNT TO n
  n IF
    TRUE TO ?UNRES
    .UNRES
    ?FWDABORT IF
      S" Unresolved forward references" TCOM-ABORT
    THEN
  ELSE
    FALSE TO ?UNRES
  THEN
  ;

\ Optional: pack may auto-include library source for unknown names.
\ Stack: ( ca u -- ix true | false )
DEFER LIB-AUTO-INCLUDE
: (LIB-AUTO-NONE)  ( ca u -- false )  2DROP FALSE ;
' (LIB-AUTO-NONE) IS LIB-AUTO-INCLUDE

: .SYM-TYPE  ( typ -- )
  {: typ :}
  typ SYM-TARGET  = IF S" TARGET" TYPE EXIT THEN
  typ SYM-LIBRARY = IF S" LIB" TYPE EXIT THEN
  typ SYM-CODE    = IF S" CODE" TYPE EXIT THEN
  typ SYM-FORWARD = IF S" FWD" TYPE EXIT THEN
  S" ?" TYPE
  ;

: .SYMBOLS  ( -- )
  {: | i :}
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
  {: | i :}
  S" SYMA raw (first 16):" TYPE CR
  0 TO i
  BEGIN i SYM-N @ < i 16 < AND WHILE
    i 3 .R S" : " TYPE
    i SYM-ADDR@ SYM-HEX. CR
    i 1+ TO i
  REPEAT
  ;

: ?INTERPRET-ONLY  ( ca u -- )
  {: ca u :}
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
  SYM-TARGET tadr SYM-DEFINE-LAST DROP
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
  SYM-LIBRARY tadr SYM-DEFINE-LAST DROP
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
  SYM-CODE tadr SYM-DEFINE-LAST DROP
  SETASSEM
  ;

: G,    ( n -- )     COMP-SINGLE ;
: GCALL ( addr -- )  COMP-CALL ;
: GJMP  ( addr -- )  COMP-JMP-IMM ;

: G'  ( "<spaces>name" -- )
  {: | ca u ix :}
  BL WORD COUNT TO u TO ca
  ca u SYM-FIND IF
    TO ix
  ELSE
    ca u LIB-AUTO-INCLUDE IF
      TO ix
    ELSE
      \ create forward reference (not allowed inside L:)
      ?LIB IF
        ca u TYPE S"  ?" TYPE CR
        S" forward reference not allowed in library" TCOM-ABORT
      THEN
      ca u SYM-FORWARD SYM-NO-CHAIN SYM-ADD TO ix
      ?QUIET 0= IF
        S" Forward: " TYPE ca u TYPE CR
      THEN
    THEN
  THEN
  ix SYM-COMPILE-REF
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

DEFER DIR-ON-FINISH
: (DIR-ON-FINISH)  ( -- )  SYM-CHECK-UNRES ;
' (DIR-ON-FINISH) IS DIR-ON-FINISH

: .DIR  ( -- )
  S" 64DIR Phase 1.3 — symbols, forward refs, resolve, options" TYPE CR
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
  \ forward entry without image
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
