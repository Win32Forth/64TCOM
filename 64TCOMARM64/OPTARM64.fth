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

\ Pack-local starts (avoid interpret TO on VALUEs — flaky on some 64Forth builds)
VARIABLE A64-CODE-START
VARIABLE A64-COLD
0 A64-CODE-START !
0 A64-COLD !

: (%SET-COLD)  ( -- )
  HERE-T A64-COLD !
  ?QUIET 0= IF  ." SET-COLD-ENTRY at " A64-COLD @ . CR  THEN
  ;
' (%SET-COLD) IS SET-COLD-ENTRY

S" BIN" IMAGE.EXT PLACE

\ End of library stubs (LIBARM64 sets after prims). Defined here because
\ OPT is loaded before LIB.
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
    ."  COLD=" A64-COLD @ .
    ."  LIB-END=" LIB-CODE-END @ . CR
  THEN
  ;
' (SAVE-IMAGE-A64) IS SAVE-IMAGE

: TARGET-INIT  ( -- )
  ?LIB IF  S" Can't use TARGET-INIT in a library routine" TCOM-ABORT  THEN
  \ Keep LIBARM64 stubs; do not wipe image. No TO on host VALUEs.
  T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN
  LIB-CODE-END @ DUP A64-CODE-START ! DP-T !
  0 DP-D !
  TCOM-ORDER
  >TARGET
  [DEFINED] DIR-ON-TARGET-INIT [IF] DIR-ON-TARGET-INIT [THEN]
  ?QUIET 0= IF
    ." TARGET-INIT: ARM64 app CODE at " A64-CODE-START @ . CR
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
  \ Dump from cold/app start (skip pure lib region in the listing)
  S" App bytes @ " TYPE A64-COLD @ SYM-HEX.
  S" ..HERE-T=" TYPE HERE-T . CR
  A64-COLD @ AD-I !
  HERE-T AD-I @ - 96 UMIN AD-I @ + AD-N !   \ up to 96 app bytes
  BEGIN AD-I @ AD-N @ < WHILE
    AD-I @ C@-T ARM64-H2.
    AD-I @ A64-COLD @ - 15 AND 15 = IF CR S"   " TYPE THEN
    1 AD-I +!
  REPEAT
  CR
  S" Lib stubs 0.." TYPE LIB-CODE-END @ SYM-HEX. S" (RET each)" TYPE CR
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
