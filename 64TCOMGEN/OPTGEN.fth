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

TCOM-ANEW OPTGEN

FORTH DEFINITIONS
DECIMAL

\ -----------------------------------------------------------------------------
\ Logging helpers  (newline at end of each message — no leading blank lines)
\ -----------------------------------------------------------------------------

: GEN.     ( c-addr u -- )  ?QUIET IF 2DROP EXIT THEN  TYPE ;
: GEN."    ( -- )  POSTPONE S"  POSTPONE GEN. ; IMMEDIATE
: GEN-CR   ( -- )  ?QUIET 0= IF CR THEN ;   \ end of a log line only

\ -----------------------------------------------------------------------------
\ Version / endian / cold entry
\ -----------------------------------------------------------------------------

: (TVER-GEN)  ( -- )  ." 64TCOM GEN Version 0.1" ;
' (TVER-GEN) IS TVERSION

/LOW-HIGH
' (DATA-SEG-FIX-NOOP) IS DATA-SEG-FIX

: (%SET-COLD)  ( -- )
  HERE-T TO COLD-START
  ?QUIET 0= IF  ." SET-COLD-ENTRY at " COLD-START . CR  THEN
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
  ?QUIET 0= IF  ." (LIT) " DUP . CR  THEN
  GEN-LIT,
  ;
' (%COMP-SINGLE) IS COMP-SINGLE

: (%COMP-CALL)  ( addr|sym -- )
  ?QUIET 0= IF  ." CALL " DUP H. CR  THEN
  GEN-CALL,
  ;
' (%COMP-CALL) IS COMP-CALL

: (%COMP-JMP-IMM)  ( addr -- )
  ?QUIET 0= IF  ." JMP " DUP H. CR  THEN
  GEN-JMP,
  ;
' (%COMP-JMP-IMM) IS COMP-JMP-IMM

: (%COMP-FETCH)   ( -- )  ?QUIET 0= IF ." @" CR THEN  GEN-NOP, ;
: (%COMP-STORE)   ( -- )  ?QUIET 0= IF ." !" CR THEN  GEN-NOP, ;
: (%COMP-PERFORM) ( -- )  ?QUIET 0= IF ." PERFORM" CR THEN  GEN-NOP, ;
: (%COMP-ON)      ( -- )  ?QUIET 0= IF ." ON" CR THEN  GEN-NOP, ;
: (%COMP-OFF)     ( -- )  ?QUIET 0= IF ." OFF" CR THEN  GEN-NOP, ;
: (%COMP-INCR)    ( -- )  ?QUIET 0= IF ." INCR" CR THEN  GEN-NOP, ;
: (%COMP-DECR)    ( -- )  ?QUIET 0= IF ." DECR" CR THEN  GEN-NOP, ;
: (%COMP-PSTORE)  ( -- )  ?QUIET 0= IF ." +!" CR THEN  GEN-NOP, ;
: (%COMP-SAVE)    ( -- )  ?QUIET 0= IF ." SAVE>" CR THEN  GEN-NOP, ;
: (%COMP-SAVEST)  ( -- )  ?QUIET 0= IF ." SAVE!>" CR THEN  GEN-NOP, ;
: (%COMP-REST)    ( -- )  ?QUIET 0= IF ." REST>" CR THEN  GEN-NOP, ;
: (%COMP-FPUSH)   ( -- )  ?QUIET 0= IF ." FPUSH" CR THEN  GEN-NOP, ;

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
  ?QUIET 0= IF ." ;T" CR THEN  GEN-RET,
  ;
' (%END-T:) IS END-T:

: (%END-L:)  ( -- )
  ?QUIET 0= IF ." ;L" CR THEN  GEN-RET,
  ;
' (%END-L:) IS END-L:

: (%END-LM:)  ( -- )
  ?QUIET 0= IF ." END-LM:" CR THEN
  ;
' (%END-LM:) IS END-LM:

: (%END-MACRO)  ( -- )
  ?QUIET 0= IF ." END-MACRO" CR THEN  END-CODE
  ;
' (%END-MACRO) IS END-MACRO
' (%END-MACRO) IS END-LMACRO

: (%END-LCODE)  ( -- )
  ?QUIET 0= IF ." END-LCODE" CR THEN  END-CODE
  ;
' (%END-LCODE) IS END-LCODE

: (%START-T:)  ( -- )
  ?QUIET 0= IF ." Defining-: " THEN
  ;
' (%START-T:) IS START-T:

: (%START-L:)  ( -- )
  ?QUIET 0= IF ." Including-: " THEN
  ;
' (%START-L:) IS START-L:
' (%START-L:) IS START-LM:

: (%MACRO-START)  ( -- )
  ?QUIET 0= IF ." Performing-MACRO " THEN
  SETASSEM
  ;
' (%MACRO-START) IS MACRO-START

: (%LCODE-START)  ( -- )
  ?QUIET 0= IF ." Including-CODE " THEN
  SETASSEM
  ;
' (%LCODE-START) IS LCODE-START

: (%TCODE-START)  ( -- )
  ?QUIET 0= IF ." Defining-CODE " THEN
  SETASSEM
  ;
' (%TCODE-START) IS TCODE-START

: (%COMP-HEADER)  ( c-addr -- )
  \ c-addr = counted string
  COUNT
  ?QUIET 0= IF  ." Compiling a header for: " 2DUP TYPE CR  THEN
  GEN-TAG-HDR GEN-TAG,
  DUP C,-T                    \ length byte
  BOUNDS ?DO  I C@ C,-T  LOOP
  ;
' (%COMP-HEADER) IS COMP-HEADER

: (%RESOLVE-1)  ( addr -- )
  ?QUIET 0= IF  ." Resolving forward ref at " DUP H. ." -> HERE-T" CR  THEN
  DROP
  ;
' (%RESOLVE-1) IS RESOLVE-1

: (%SUB-RET)  ( -- )
  ?QUIET 0= IF ." (tail) remove prior RET" CR THEN
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

: ?INTERPRET-ONLY  ( c-addr u -- )
  \ Abort if used while compiling a colon definition (name must be parsed now)
  STATE @ IF  TCOM-ABORT  ELSE  2DROP  THEN
  ;

: T:  ( "<spaces>name" -- )
  S" T: is interpret-only (not inside a colon def)" ?INTERPRET-ONLY
  ?EXECUTING
  START-T:
  HERE-T >R
  R@ (T-COOKIE)                 \ parses name
  GEN-LOG-LAST  GEN-CR          \ "Defining-: NAME"
  LAST NAME>STRING PAD PLACE  PAD COMP-HEADER
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
  GEN-LOG-LAST  GEN-CR
  LAST NAME>STRING PAD PLACE  PAD COMP-HEADER
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
  GEN-LOG-LAST  GEN-CR
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
  ?QUIET 0= IF ." Performing cleanup after compile completion" CR THEN
  DATA-SEG-FIX
  ;
' (TARGET-FINISH-GEN) IS TARGET-FINISH

: (SAVE-IMAGE-GEN)  ( -- )
  ?QUIET 0= IF
    ." GEN: image in memory only (no file save yet)  HERE-T=" HERE-T . CR
  THEN
  ;
' (SAVE-IMAGE-GEN) IS SAVE-IMAGE

: TARGET-INIT  ( -- )
  ?LIB IF  S" Can't use TARGET-INIT in a library routine" TCOM-ABORT  THEN
  TCOM-INIT-MEM-DEFAULT
  0 TO CODE-START  0 TO DATA-START
  CODE-START DP-T !  DATA-START DP-D !
  TCOM-ORDER
  >TARGET
  ?QUIET 0= IF ." TARGET-INIT: CODE/DATA origin 0, image cleared" CR THEN
  SET-COLD-ENTRY
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

\ GEN-DEMO must not embed "T: HI" inside a colon definition — the text
\ interpreter would look up HI while compiling GEN-DEMO (undefined: HI).
\ Run the sample via EVALUATE so T: parses HI at interpret time.

: GEN-DEMO-DUMP  ( -- )
  CR ." GEN-DEMO done. HERE-T=" HERE-T . CR
  ." First bytes: "
  HERE-T 0 MAX  32 MIN  0 ?DO
    I C@-T  BASE @ >R HEX  0 <# # # #> TYPE SPACE  R> BASE !
  LOOP
  CR
  ;

: GEN-DEMO  ( -- )
  S" TARGET-INIT /SHOW T: HI $1234 G, ' DUP# LIB, ;T GEN-FINISH"
  EVALUATE
  GEN-DEMO-DUMP
  ;

FORTH DEFINITIONS
." OPTGEN loaded." CR
