\ OPTGEN.fth — GEN target interface / “optimizer” hooks for 64TCOM
\
\ Public domain.
\ Classic analogue: tcom25/TCOMGEN/OPTGEN.FTH
\
\ Installs logging implementations of the deferred words declared in 64HOST.
\ Also defines a tiny GEN tag stream written into the target CODE image so
\ HERE-T moves and .GEN / dumps can show real buffer activity (not ARM64).
\
\ GEN tag stream (byte codes in target CODE space):
\   $01  LIT     + T-CELL bytes (little-endian cell)
\   $02  CALL    + T-CELL bytes (target address / symbol cookie)
\   $03  RET
\   $04  NOP
\   $05  JMP     + T-CELL bytes
\   $06  0BRANCH + T-CELL bytes
\   $10  HEADER marker + counted name in following bytes (optional)
\
\ Requires: 64HOST.fth, ASMGEN.fth

ANEW OPTGEN

FORTH DEFINITIONS
DECIMAL

\ -----------------------------------------------------------------------------
\ Logging helpers
\ -----------------------------------------------------------------------------

: GEN-CR?  ( -- )  ?QUIET 0= IF CR THEN ;
: GEN.     ( c-addr u -- )  ?QUIET IF 2DROP EXIT THEN  TYPE ;
: GEN."    ( -- )  POSTPONE S"  POSTPONE GEN. ; IMMEDIATE

: ?1CR  ( -- )  ?QUIET 0= IF CR THEN ;
: ?2CR  ( -- )  ?QUIET 0= IF CR CR THEN ;

\ -----------------------------------------------------------------------------
\ Version / endian / cold entry
\ -----------------------------------------------------------------------------

: (TVER-GEN)  ( -- )  ."  64TCOM GEN Version 0.1 " ;
' (TVER-GEN) IS TVERSION

/LOW-HIGH
' (DATA-SEG-FIX-NOOP) IS DATA-SEG-FIX

: (%SET-COLD)  ( -- )
  HERE-T TO COLD-START
  ?QUIET 0= IF  CR ." SET-COLD-ENTRY at " COLD-START .  THEN
  ;
' (%SET-COLD) IS SET-COLD-ENTRY

S" BIN" IMAGE.EXT PLACE

\ -----------------------------------------------------------------------------
\ GEN tag emitters (use 64HOST target memory)
\ -----------------------------------------------------------------------------

$01 CONSTANT GEN-TAG-LIT
$02 CONSTANT GEN-TAG-CALL
$03 CONSTANT GEN-TAG-RET
$04 CONSTANT GEN-TAG-NOP
$05 CONSTANT GEN-TAG-JMP
$06 CONSTANT GEN-TAG-0BR
$10 CONSTANT GEN-TAG-HDR

: GEN-TAG,   ( b -- )  C,-T ;
: GEN-CELL,  ( x -- )  ,-T  ;

: GEN-LIT,   ( n -- )
  GEN-TAG-LIT GEN-TAG,  GEN-CELL,
  ;

: GEN-CALL,  ( addr -- )
  GEN-TAG-CALL GEN-TAG,  GEN-CELL,
  ;

: GEN-RET,   ( -- )  GEN-TAG-RET GEN-TAG, ;
: GEN-NOP,   ( -- )  GEN-TAG-NOP GEN-TAG, ;

: GEN-JMP,   ( addr -- )
  GEN-TAG-JMP GEN-TAG,  GEN-CELL,
  ;

: GEN-0BR,   ( addr -- )
  GEN-TAG-0BR GEN-TAG,  GEN-CELL,
  ;

\ -----------------------------------------------------------------------------
\ Install deferred COMP_* / END-* / START-* hooks
\ -----------------------------------------------------------------------------

: (%COMP-SINGLE)  ( n -- )
  ?1CR  ?QUIET 0= IF  ." (LIT) " DUP .  THEN
  GEN-LIT,
  ;
' (%COMP-SINGLE) IS COMP-SINGLE

: (%COMP-CALL)  ( addr|sym -- )
  ?1CR  ?QUIET 0= IF  ." CALL " DUP H.  THEN
  GEN-CALL,
  ;
' (%COMP-CALL) IS COMP-CALL

: (%COMP-JMP-IMM)  ( addr -- )
  ?1CR  ?QUIET 0= IF  ." JMP " DUP H.  THEN
  GEN-JMP,
  ;
' (%COMP-JMP-IMM) IS COMP-JMP-IMM

: (%COMP-FETCH)   ( -- )  ?1CR  GEN." @ "      GEN-NOP, ;
: (%COMP-STORE)   ( -- )  ?1CR  GEN." ! "      GEN-NOP, ;
: (%COMP-PERFORM) ( -- )  ?1CR  GEN." PERFORM " GEN-NOP, ;
: (%COMP-ON)      ( -- )  ?1CR  GEN." ON "      GEN-NOP, ;
: (%COMP-OFF)     ( -- )  ?1CR  GEN." OFF "     GEN-NOP, ;
: (%COMP-INCR)    ( -- )  ?1CR  GEN." INCR "    GEN-NOP, ;
: (%COMP-DECR)    ( -- )  ?1CR  GEN." DECR "    GEN-NOP, ;
: (%COMP-PSTORE)  ( -- )  ?1CR  GEN." +! "      GEN-NOP, ;
: (%COMP-SAVE)    ( -- )  ?1CR  GEN." SAVE> "   GEN-NOP, ;
: (%COMP-SAVEST)  ( -- )  ?1CR  GEN." SAVE!> "  GEN-NOP, ;
: (%COMP-REST)    ( -- )  ?1CR  GEN." REST> "   GEN-NOP, ;
: (%COMP-FPUSH)   ( -- )  ?1CR  GEN." FPUSH "   GEN-NOP, ;

' (%COMP-FETCH)   IS COMP-FETCH
' (%COMP-STORE)   IS COMP-STORE
' (%COMP-PERFORM) IS COMP-PERFORM
' (%COMP-ON)      IS COMP-ON
' (%COMP-OFF)     IS COMP-OFF
' (%COMP-INCR)    IS COMP-INCR
' (%COMP-DECR)    IS COMP-DECR
' (%COMP-PSTORE)  IS COMP-PSTORE
' (%COMP-SAVE)    IS COMP-SAVE
' (%COMP-SAVEST)  IS COMP-SAVEST
' (%COMP-REST)    IS COMP-REST
' (%COMP-FPUSH)   IS COMP-FPUSH

: (%END-T:)  ( -- )
  ?1CR  GEN." ;T / END-T: "  GEN-RET,
  ;
' (%END-T:) IS END-T:

: (%END-L:)  ( -- )
  ?1CR  GEN." ;L / END-L: "  GEN-RET,
  ;
' (%END-L:) IS END-L:

: (%END-LM:)  ( -- )
  ?1CR  GEN." END-LM: "
  ;
' (%END-LM:) IS END-LM:

: (%END-MACRO)  ( -- )
  ?1CR  GEN." END-MACRO "  END-CODE
  ;
' (%END-MACRO) IS END-MACRO
' (%END-MACRO) IS END-LMACRO

: (%END-LCODE)  ( -- )
  ?1CR  GEN." END-LCODE "  END-CODE
  ;
' (%END-LCODE) IS END-LCODE

: (%START-T:)  ( -- )
  ?2CR  GEN." Defining-: "
  ;
' (%START-T:) IS START-T:

: (%START-L:)  ( -- )
  ?2CR  GEN." Including-: "
  ;
' (%START-L:) IS START-L:
' (%START-L:) IS START-LM:

: (%MACRO-START)  ( -- )
  ?1CR  GEN." Performing-MACRO "
  SETASSEM
  ;
' (%MACRO-START) IS MACRO-START

: (%LCODE-START)  ( -- )
  ?2CR  GEN." Including-CODE "
  SETASSEM
  ;
' (%LCODE-START) IS LCODE-START

: (%TCODE-START)  ( -- )
  ?2CR  GEN." Defining-CODE "
  SETASSEM
  ;
' (%TCODE-START) IS TCODE-START

: (%COMP-HEADER)  ( c-addr -- )
  \ c-addr = counted string
  ?2CR  GEN." Compiling a header for: "
  COUNT  2DUP GEN.
  GEN-TAG-HDR GEN-TAG,
  DUP C,-T                    \ length byte
  BOUNDS ?DO  I C@ C,-T  LOOP
  ;
' (%COMP-HEADER) IS COMP-HEADER

: (%RESOLVE-1)  ( addr -- )
  ?1CR  GEN." Resolving forward ref at "  DUP H.  GEN." -> HERE-T "
  DROP
  ;
' (%RESOLVE-1) IS RESOLVE-1

: (%SUB-RET)  ( -- )
  ?1CR  GEN." (tail) remove prior RET "
  \ GEN: if last tag was RET, back up one byte
  HERE-T 1 U>= IF
    HERE-T 1- C@-T GEN-TAG-RET = IF  -1 ALLOT-T  THEN
  THEN
  ;
' (%SUB-RET) IS SUB-RET

\ -----------------------------------------------------------------------------
\ Thin director slice — defining words usable before full COMPILE1/2
\ -----------------------------------------------------------------------------
\
\ T: name  creates host word "name" returning target entry cookie; then lay
\ tags with G, / LIB, until ;T.

: GEN-LOG-LAST  ( -- )
  ?QUIET IF EXIT THEN
  LAST NAME>STRING GEN.
  ;

: (T-COOKIE)  ( taddr -- )   \ CREATE name ; runtime leaves taddr
  CREATE ,  DOES> @
  ;

: T:  ( "<spaces>name" -- )
  ?EXECUTING
  START-T:
  HERE-T >R
  R@ (T-COOKIE)                 \ parses name
  GEN-LOG-LAST SPACE
  LAST NAME>STRING PAD PLACE  PAD COMP-HEADER
  R> DROP
  TRUE TO ?INTERPRETIVE
  ;

: ;T  ( -- )
  END-T:
  FALSE TO ?INTERPRETIVE
  ; IMMEDIATE

: L:  ( "<spaces>name" -- )
  ?EXECUTING
  TRUE TO ?LIB
  START-L:
  HERE-T >R
  R@ (T-COOKIE)
  GEN-LOG-LAST SPACE
  LAST NAME>STRING PAD PLACE  PAD COMP-HEADER
  R> DROP
  ;

: ;L  ( -- )
  END-L:
  FALSE TO ?LIB
  ; IMMEDIATE

: GCODE  ( "<spaces>name" -- )
  ?EXECUTING
  TCODE-START
  HERE-T >R
  R@ (T-COOKIE)
  GEN-LOG-LAST SPACE
  LAST NAME>STRING PAD PLACE  PAD COMP-HEADER
  R> DROP
  SETASSEM
  ;

: G,    ( n -- )     COMP-SINGLE ;
: GCALL ( addr -- )  COMP-CALL ;
: GJMP  ( addr -- )  COMP-JMP-IMM ;

\ -----------------------------------------------------------------------------
\ Target init / finish / save (GEN)
\ -----------------------------------------------------------------------------

DEFER TARGET-FINISH
DEFER SAVE-IMAGE

: (TARGET-FINISH-GEN)  ( -- )
  GEN-CR?  GEN." Performing cleanup after compile completion"
  DATA-SEG-FIX
  ;
' (TARGET-FINISH-GEN) IS TARGET-FINISH

: (SAVE-IMAGE-GEN)  ( -- )
  GEN-CR?  GEN." GEN: no binary save yet (image stays in T-CODE-BASE / T-DATA-BASE)"
  GEN-CR?  GEN." HERE-T="  HERE-T 0 <# #S #> GEN.
  ;
' (SAVE-IMAGE-GEN) IS SAVE-IMAGE

: TARGET-INIT  ( -- )
  ?LIB IF  S" Can't use TARGET-INIT in a library routine" TCOM-ABORT  THEN
  TCOM-INIT-MEM-DEFAULT
  0 TO CODE-START  0 TO DATA-START
  CODE-START DP-T !  DATA-START DP-D !
  TCOM-ORDER
  >TARGET
  GEN-CR?
  GEN." TARGET-INIT: CODE origin 0, DATA origin 0, image cleared"
  SET-COLD-ENTRY
  \ entry tag
  GEN-NOP,
  ;

: GEN-FINISH  ( -- )
  TARGET-FINISH
  ?NOSAVE 0= IF  SAVE-IMAGE  THEN
  >FORTH
  ;

\ -----------------------------------------------------------------------------
\ Status / demo
\ -----------------------------------------------------------------------------

: .GEN  ( -- )
  CR TVERSION CR
  .64HOST
  CR ." GEN tags: LIT=01 CALL=02 RET=03 NOP=04 JMP=05 0BR=06 HDR=10" CR
  ." Words: TARGET-INIT  T: ;T  L: ;L  G, GCALL GJMP  GEN-FINISH  GEN-DEMO" CR
  ;

: GEN-DEMO  ( -- )
  TARGET-INIT
  /SHOW
  T: HI
    $1234 G,
    ['] DUP# LIB,
  ;T
  GEN-FINISH
  CR ." GEN-DEMO done. HERE-T=" HERE-T . CR
  ." First bytes: "
  HERE-T 0 MAX  32 MIN  0 ?DO
    I C@-T  BASE @ >R HEX  0 <# # # #> TYPE SPACE  R> BASE !
  LOOP
  CR
  ;

FORTH DEFINITIONS
CR ." OPTGEN loaded (GEN hooks + thin T:/;T director)." CR
