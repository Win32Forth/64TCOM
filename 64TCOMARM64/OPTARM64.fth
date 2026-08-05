\ OPTARM64.fth — ARM64 target interface hooks for 64TCOM
\
\ Public domain. Requires 64HOST, ASMARM64.
\ Installs COMP-* that emit real AArch64 into T-CODE-BASE.

TCOM-ANEW OPTARM64

FORTH DEFINITIONS
DECIMAL

: (TVER-ARM64)  ( -- )  ." 64TCOM ARM64 Version 0.1" ;
' (TVER-ARM64) IS TVERSION

/LOW-HIGH
' (DATA-SEG-FIX-NOOP) IS DATA-SEG-FIX

: (%SET-COLD)  ( -- )
  HERE-T TO COLD-START
  ?QUIET 0= IF  ." SET-COLD-ENTRY at " COLD-START . CR  THEN
  ;
' (%SET-COLD) IS SET-COLD-ENTRY

S" BIN" IMAGE.EXT PLACE

\ End of library stubs in target image (LIBARM64 sets this after prims).
\ Must live here (or 64HOST): OPT is compiled *before* LIB is loaded, so
\ [DEFINED] LIB-CODE-END at OPT compile time is always false.
VARIABLE LIB-CODE-END
0 LIB-CODE-END !

\ -----------------------------------------------------------------------------
\ Compile hooks → A64
\ -----------------------------------------------------------------------------

: (%COMP-SINGLE)  ( n -- )
  ?QUIET 0= IF  ." (LIT-X0) " DUP H. CR  THEN
  LIT-X0,
  ;
' (%COMP-SINGLE) IS COMP-SINGLE

: (%COMP-CALL)  ( addr -- )
  ?QUIET 0= IF  ." CALL-ABS " DUP H. CR  THEN
  CALL-ABS,
  ;
' (%COMP-CALL) IS COMP-CALL

: (%COMP-JMP-IMM)  ( addr -- )
  ?QUIET 0= IF  ." JMP-ABS " DUP H. CR  THEN
  ALIGN4-T
  X16 LDR64-PC+8,
  X16 BR-X,
  ,-T
  ;
' (%COMP-JMP-IMM) IS COMP-JMP-IMM

: (%COMP-FETCH)   ( -- )  ?QUIET 0= IF ." @" CR THEN  NOP, ;
: (%COMP-STORE)   ( -- )  ?QUIET 0= IF ." !" CR THEN  NOP, ;
: (%COMP-PERFORM) ( -- )  ?QUIET 0= IF ." PERFORM" CR THEN  NOP, ;
: (%COMP-ON)      ( -- )  NOP, ;
: (%COMP-OFF)     ( -- )  NOP, ;
: (%COMP-INCR)    ( -- )  NOP, ;
: (%COMP-DECR)    ( -- )  NOP, ;
: (%COMP-PSTORE)  ( -- )  NOP, ;
: (%COMP-SAVE)    ( -- )  NOP, ;
: (%COMP-SAVEST)  ( -- )  NOP, ;
: (%COMP-REST)    ( -- )  NOP, ;
: (%COMP-FPUSH)   ( -- )  NOP, ;

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
  ?QUIET 0= IF ." ;T RET," CR THEN
  RET,
  ;
' (%END-T:) IS END-T:

: (%END-L:)  ( -- )
  ?QUIET 0= IF ." ;L RET," CR THEN
  RET,
  ;
' (%END-L:) IS END-L:

: (%END-LM:)  ( -- )  ;
' (%END-LM:) IS END-LM:

: (%END-MACRO)  ( -- )  END-CODE ;
' (%END-MACRO) IS END-MACRO
' (%END-MACRO) IS END-LMACRO

: (%END-LCODE)  ( -- )  END-CODE ;
' (%END-LCODE) IS END-LCODE

: (%START-T:)  ( -- )
  ?QUIET 0= IF ." Defining-: " THEN
  ALIGN4-T
  ;
' (%START-T:) IS START-T:

: (%START-L:)  ( -- )
  ?QUIET 0= IF ." Including-: " THEN
  ALIGN4-T
  ;
' (%START-L:) IS START-L:
' (%START-L:) IS START-LM:

: (%MACRO-START)  ( -- )  SETASSEM ;
' (%MACRO-START) IS MACRO-START

: (%LCODE-START)  ( -- )  SETASSEM ;
' (%LCODE-START) IS LCODE-START

: (%TCODE-START)  ( -- )
  ?QUIET 0= IF ." Defining-CODE " THEN
  SETASSEM
  ;
' (%TCODE-START) IS TCODE-START

: (%COMP-HEADER)  ( c-addr -- )
  COUNT
  ?QUIET 0= IF  ." Compiling a header for: " 2DUP TYPE CR  THEN
  2DROP
  \ v0.1: no in-image name blob (keeps code pure A64)
  ;
' (%COMP-HEADER) IS COMP-HEADER

: (%RESOLVE-1)  ( site final-addr -- )
  ?QUIET 0= IF
    ." Resolving @" SPACE OVER H. ." -> " DUP H. CR
  THEN
  SWAP !-T
  ;
' (%RESOLVE-1) IS RESOLVE-1

: (%SUB-RET)  ( -- )
  \ optional tail: strip prior RET if last insn is RET — skip in v0.1
  ;
' (%SUB-RET) IS SUB-RET

\ -----------------------------------------------------------------------------
\ Init / finish
\ -----------------------------------------------------------------------------

DEFER TARGET-FINISH
DEFER SAVE-IMAGE

: (TARGET-FINISH-A64)  ( -- )
  ?QUIET 0= IF ." Performing cleanup after compile completion" CR THEN
  DATA-SEG-FIX
  [DEFINED] DIR-ON-FINISH [IF] DIR-ON-FINISH [THEN]
  ;
' (TARGET-FINISH-A64) IS TARGET-FINISH

: (SAVE-IMAGE-A64)  ( -- )
  ?QUIET 0= IF
    ." ARM64: image in memory  HERE-T=" HERE-T .
    ."  COLD-START=" COLD-START . CR
  THEN
  ;
' (SAVE-IMAGE-A64) IS SAVE-IMAGE

: TARGET-INIT  ( -- )
  ?LIB IF  S" Can't use TARGET-INIT in a library routine" TCOM-ABORT  THEN
  \ Keep LIBARM64 stubs already in the image; only allocate if needed.
  T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN
  LIB-CODE-END @ TO CODE-START
  0 TO DATA-START
  CODE-START DP-T !
  DATA-START DP-D !
  TCOM-ORDER
  >TARGET
  [DEFINED] DIR-ON-TARGET-INIT [IF] DIR-ON-TARGET-INIT [THEN]
  ?QUIET 0= IF
    ." TARGET-INIT: ARM64 app CODE at " CODE-START . CR
  THEN
  SET-COLD-ENTRY
  NOP,                             \ cold pad at start of app
  ;

: ARM64-FINISH  ( -- )
  TARGET-FINISH
  ?NOSAVE 0= IF  SAVE-IMAGE  THEN
  >FORTH
  ;

: .ARM64  ( -- )
  TVERSION CR
  .64HOST
  S" ARM64: CALL-ABS = LDR X16,[PC+8]; BLR X16; .quad" TYPE CR
  S" Words: TARGET-INIT T: ;T G, G' LIB, ARM64-FINISH ARM64-DEMO FWD-ARM64" TYPE CR
  [DEFINED] .DIR [IF] .DIR [THEN]
  ;

VARIABLE AD-N
VARIABLE AD-I
VARIABLE AD-BASE

: ARM64-H2.  ( u -- )
  BASE @ AD-BASE !
  HEX  0 <# # # #> TYPE SPACE
  AD-BASE @ BASE !
  ;

: ARM64-DUMP  ( -- )
  S" First bytes: " TYPE
  HERE-T 64 UMIN AD-N !
  0 AD-I !
  BEGIN AD-I @ AD-N @ < WHILE
    AD-I @ C@-T ARM64-H2.
    AD-I @ 15 AND 15 = IF CR S"              " TYPE THEN
    1 AD-I +!
  REPEAT
  CR
  [DEFINED] .SYMBOLS [IF] .SYMBOLS [THEN]
  ;

: ARM64-DEMO  ( -- )
  S" ARM64DEMO.fth" INCLUDED
  ;

: FWD-ARM64  ( -- )
  S" FWDARM64.fth" INCLUDED
  ;

FORTH DEFINITIONS
S" OPTARM64 loaded." TYPE CR
