\ OPTARM64.fth — ARM64 target interface hooks for 64TCOM
\
\ Public domain. Requires 64HOST, ASMARM64.
\ Installs COMP-* that emit real AArch64 into T-CODE-BASE.

TCOM-ANEW OPTARM64

FORTH DEFINITIONS
DECIMAL

: (TVER-ARM64)  ( -- )  ." 64TCOM ARM64 Version 0.2" ;
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

\ Default output leaf name (cwd-relative; 64Forth may remap bundle paths)
CREATE IMAGE-FILENAME  128 ALLOT
S" tcomarm64.bin" IMAGE-FILENAME PLACE

CREATE IMAGE-MAPNAME  128 ALLOT
S" tcomarm64.map" IMAGE-MAPNAME PLACE

\ End of library stubs / lib symbol count (LIBARM64 sets these).
\ Must live here: OPT is compiled before LIB is loaded.
VARIABLE LIB-CODE-END
0 LIB-CODE-END !
VARIABLE LIB-SYM-N
0 LIB-SYM-N !

FALSE VALUE ?SAVE-MAP     \ also write .map text alongside .bin
: /MAP    ( -- )  TRUE  TO ?SAVE-MAP ;
: /NOMAP  ( -- )  FALSE TO ?SAVE-MAP ;

\ Optional 32-byte header before raw code (off by default = pure flat A64)
FALSE VALUE ?IMAGE-HDR
: /HDR    ( -- )  TRUE  TO ?IMAGE-HDR ;
: /NOHDR  ( -- )  FALSE TO ?IMAGE-HDR ;

32 CONSTANT /A64-HDR
CREATE A64-HDR  32 ALLOT

: (A64-FILL-HDR)  ( -- )
  A64-HDR /A64-HDR ERASE
  \ magic "64TCOMA" at bytes 0..6
  [CHAR] 6 A64-HDR C!
  [CHAR] 4 A64-HDR 1 + C!
  [CHAR] T A64-HDR 2 + C!
  [CHAR] C A64-HDR 3 + C!
  [CHAR] O A64-HDR 4 + C!
  [CHAR] M A64-HDR 5 + C!
  [CHAR] A A64-HDR 6 + C!
  1 A64-HDR 8 + !                 \ version
  HERE-T A64-HDR 16 + !           \ code size
  A64-COLD @ A64-HDR 24 + !       \ cold offset
  ;

\ -----------------------------------------------------------------------------
\ Compile hooks → A64
\ -----------------------------------------------------------------------------

: (%COMP-SINGLE)  ( n -- )
  ?QUIET 0= IF  ." (LIT) " DUP H. CR  THEN
  LIT-PUSH-X0,                     \ push old TOS; X0 = n
  ;
' (%COMP-SINGLE) IS COMP-SINGLE

: (%COMP-CALL)  ( taddr -- )
  ?QUIET 0= IF  ." CALL " DUP H. CR  THEN
  CALL-ABS,                        \ .quad = THERE (host) for BLR
  ;
' (%COMP-CALL) IS COMP-CALL

: (%COMP-JMP-IMM)  ( taddr -- )
  ?QUIET 0= IF  ." JMP " DUP H. CR  THEN
  JMP-ABS,
  ;
' (%COMP-JMP-IMM) IS COMP-JMP-IMM

\ Lookup prim cookie by name at runtime (FETCH#/STORE# exist after LIBARM64).
: (LIB-CALL-NAME)  ( ca u -- )
  2DUP SYM-FIND IF
    NIP NIP SYM-ADDR@ COMP-CALL
  ELSE
    TYPE S"  ? (need LIBARM64 prim)" TYPE CR TCOM-ABORT
  THEN
  ;

: (%COMP-FETCH)   ( -- )
  ?QUIET 0= IF ." @" CR THEN
  S" FETCH#" (LIB-CALL-NAME)
  ;
: (%COMP-STORE)   ( -- )
  ?QUIET 0= IF ." !" CR THEN
  S" STORE#" (LIB-CALL-NAME)
  ;
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

: (A64-ENTRY-LANDING)  ( -- )  ;      \ no pad; entry = first real insn
' (A64-ENTRY-LANDING) IS ENTRY-LANDING

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

: (%RESOLVE-1)  ( site final-taddr -- )
  \ site = .quad after LDR/BLR/B; store target taddr (offset, not host)
  ?QUIET 0= IF
    ." Resolving call @" SPACE OVER H. ." -> t" DUP H. CR
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

\ Write raw CODE bytes [0, HERE-T) to file (c-addr u = name)
\ Use a VARIABLE for fid — not >R — so INCLUDE's return stack stays intact.
VARIABLE SAVE-FID

: SAVE-IMAGE-AS  ( c-addr u -- )
  W/O BIN CREATE-FILE  ( fid ior )
  IF
    DROP
    S" SAVE-IMAGE: CREATE-FILE failed for " TYPE TYPE CR
    EXIT
  THEN
  SAVE-FID !
  ?IMAGE-HDR IF
    (A64-FILL-HDR)
    A64-HDR /A64-HDR SAVE-FID @ WRITE-FILE
    IF  S" SAVE-IMAGE: header WRITE-FILE failed" TYPE CR  THEN
  THEN
  T-CODE-BASE HERE-T SAVE-FID @ WRITE-FILE  ( ior )
  IF  S" SAVE-IMAGE: code WRITE-FILE failed" TYPE CR  THEN
  SAVE-FID @ CLOSE-FILE DROP
  0 SAVE-FID !
  ?QUIET 0= IF
    S" SAVE-IMAGE: wrote " TYPE HERE-T 0 .R
    S"  code bytes" TYPE
    ?IMAGE-HDR IF S"  (+32-byte hdr)" TYPE THEN
    S"  -> " TYPE
    CR
  THEN
  ;

: SAVE-IMAGE-FILE  ( -- )
  IMAGE-FILENAME COUNT SAVE-IMAGE-AS
  ?QUIET 0= IF
    S"   file: " TYPE IMAGE-FILENAME COUNT TYPE CR
  THEN
  ;

VARIABLE MAP-BASE
VARIABLE MAP-FID

: (MAP-NL)  ( -- )
  10 PAD C!  PAD 1 MAP-FID @ WRITE-FILE DROP
  ;

: (MAP-S)  ( c-addr u -- )  MAP-FID @ WRITE-FILE DROP ;

: (MAP-U.)  ( u -- )
  0 <# #S #> (MAP-S)
  ;

: SAVE-MAP-FILE  ( -- )
  IMAGE-MAPNAME COUNT W/O CREATE-FILE  ( fid ior )
  IF DROP S" SAVE-MAP: CREATE-FILE failed" TYPE CR EXIT THEN
  MAP-FID !
  S" 64TCOM ARM64 image map" (MAP-S) (MAP-NL)
  S" HERE-T=" (MAP-S)
  BASE @ MAP-BASE !
  HEX
  HERE-T (MAP-U.) (MAP-NL)
  S" COLD=" (MAP-S)  A64-COLD @ (MAP-U.) (MAP-NL)
  S" LIB-END=" (MAP-S)  LIB-CODE-END @ (MAP-U.) (MAP-NL)
  (MAP-NL) S" Symbols:" (MAP-S) (MAP-NL)
  0
  BEGIN DUP SYM-N @ < WHILE
    DUP (MAP-U.)  S"  " (MAP-S)
    DUP SYM-GET-NAME (MAP-S)
    S"  type=" (MAP-S)  DUP SYM-TYPE@ (MAP-U.)
    S"  @" (MAP-S)  DUP SYM-ADDR@ (MAP-U.)
    (MAP-NL)
    1+
  REPEAT DROP
  MAP-BASE @ BASE !
  MAP-FID @ CLOSE-FILE DROP
  ?QUIET 0= IF
    S" SAVE-MAP: " TYPE IMAGE-MAPNAME COUNT TYPE CR
  THEN
  ;

: (SAVE-IMAGE-A64)  ( -- )
  ?QUIET 0= IF
    ." ARM64: image in memory  HERE-T=" HERE-T .
    ."  COLD=" A64-COLD @ .
    ."  LIB-END=" LIB-CODE-END @ . CR
  THEN
  SAVE-IMAGE-FILE
  ?SAVE-MAP IF  SAVE-MAP-FILE  THEN
  [DEFINED] ?SAVE-MACHO [IF]
    ?SAVE-MACHO IF
      [DEFINED] SAVE-MACHO-FILE [IF] SAVE-MACHO-FILE [THEN]
    THEN
  [THEN]
  ;
' (SAVE-IMAGE-A64) IS SAVE-IMAGE

: SYM-CLEAR-APP  ( -- )
  \ Keep library symbol slots only (LIB-SYM-N set by LIBARM64)
  LIB-SYM-N @ SYM-N !
  ;

\ Data-address relocs for Mach-O (daddr in SYM-DATA; emit host via DTHERE + record)
64 CONSTANT #DATA-RELOC
CREATE DATA-RELOC-OFF  #DATA-RELOC CELLS ALLOT   \ taddr of MOVZ of lit sequence
CREATE DATA-RELOC-D    #DATA-RELOC CELLS ALLOT   \ daddr
VARIABLE DATA-RELOC-N
0 DATA-RELOC-N !

: DATA-RELOC-CLEAR  ( -- )  0 DATA-RELOC-N ! ;

: (COMP-DATA-ADDR-A64)  ( daddr -- )
  \ LIT-PUSH = STR-PRE + MOVZ/MOVK×3; reloc points at MOVZ (HERE+4).
  DATA-RELOC-N @ #DATA-RELOC U>= IF
    S" too many data address relocs" TCOM-ABORT
  THEN
  HERE-T 4 + DATA-RELOC-N @ CELLS DATA-RELOC-OFF + !
  DUP  DATA-RELOC-N @ CELLS DATA-RELOC-D + !
  1 DATA-RELOC-N +!
  DTHERE COMP-SINGLE
  ;
' (COMP-DATA-ADDR-A64) IS COMP-DATA-ADDR

\ Target VARIABLE: one cell in T-DATA; SYM-DATA = daddr.
: TVARIABLE  ( "<spaces>name" -- )
  CELL-ALIGN-D
  HERE-D
  0 OVER !-D
  T-CELL ALLOT-D
  >R
  BL WORD COUNT
  SYM-DATA R@ SYM-ADD DROP
  ?QUIET 0= IF  S" TVARIABLE daddr=" TYPE R@ . CR  THEN
  R> DROP
  ;

: G@  ( -- )  COMP-FETCH ;
: G!  ( -- )  COMP-STORE ;

\ ----- CLI args (Layer 2): fixed daddrs in T-DATA, filled by Mach-O main -----
\ Layout:  daddr 0: ARGCOUNT cell
\          daddr 8: 16 × 256-byte counted strings (user argv[1]..)
0 CONSTANT TCOM-ARGC-DADDR
8 CONSTANT TCOM-ARGS-DADDR
16 CONSTANT #TCOM-ARGS
256 CONSTANT /TCOM-ARG
8 16 256 * + CONSTANT TCOM-ARGS-END   \ 4104

\ Compile-time words (TSRC host-exec): leave c-addr u or n at runtime
: ARGCOUNT  ( -- )  TCOM-ARGC-DADDR COMP-DATA-ADDR COMP-FETCH ;
: ARG#  ( -- )
  \ runtime stack has n; push table base then call ARG## ( n base -- c-addr u )
  TCOM-ARGS-DADDR COMP-DATA-ADDR
  S" ARG##" SYM-FIND IF
    SYM-ADDR@ COMP-CALL
  ELSE
    S" ARG## prim missing" TCOM-ABORT
  THEN
  ;
: ARG1  ( -- )  1 COMP-SINGLE ARG# ;
: ARG2  ( -- )  2 COMP-SINGLE ARG# ;

: TCOM-ARGS-RESERVE  ( -- )
  \ Always pin arg block at daddr 0..TCOM-ARGS-END-1 (zeros from ERASE)
  0 DP-D !
  TCOM-ARGS-END ALLOT-D
  ;

: TARGET-INIT  ( -- )
  ?LIB IF  S" Can't use TARGET-INIT in a library routine" TCOM-ABORT  THEN
  LIB-CODE-END @ 0= IF
    S" TARGET-INIT: LIB-CODE-END=0 — FLOAD TARGETARM64.fth (library not loaded)" TYPE CR
    TCOM-ABORT
  THEN
  T-CODE-BASE 0= IF  TCOM-INIT-MEM-DEFAULT  THEN
  SYM-CLEAR-APP
  LIB-CODE-END @ DUP A64-CODE-START ! DP-T !
  DATA-START DP-D !
  T-DATA-BASE T-DATA-MAX ERASE
  DATA-RELOC-CLEAR
  TCOM-ARGS-RESERVE
  TCOM-ORDER
  >TARGET
  [DEFINED] DIR-ON-TARGET-INIT [IF] DIR-ON-TARGET-INIT [THEN]
  ?QUIET 0= IF
    ." TARGET-INIT: ARM64 app CODE at " A64-CODE-START @ . CR
  THEN
  SET-COLD-ENTRY
  T-DATA-BASE T-DATA-MAX + 64 -
  DSP-INIT,
  ;

: ARM64-FINISH  ( -- )
  TARGET-FINISH
  ?NOSAVE 0= IF  SAVE-IMAGE  THEN
  >FORTH
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
  S" Lib region 0.." TYPE LIB-CODE-END @ SYM-HEX. S" (real prims + RET)" TYPE CR
  [DEFINED] .SYMBOLS [IF] .SYMBOLS [THEN]
  ;

: ARM64-DEMO  ( -- )
  S" ARM64DEMO.fth" INCLUDED
  ;

: FWD-ARM64  ( -- )
  S" FWDARM64.fth" INCLUDED
  ;

: RUN-ARM64-DEMO  ( -- )
  ARM64-DEMO
  [DEFINED] .RUN-ANS [IF] .RUN-ANS [THEN]
  [DEFINED] .RUN-ANS-N [IF] .RUN-ANS-N [THEN]
  ;

: ASM-DEMO  ( -- )
  S" ASMDEMO.fth" INCLUDED
  ;

: IF-DEMO  ( -- )
  S" IFDEMO.fth" INCLUDED
  ;

: NEST-DEMO  ( -- )
  S" NESTDEMO.fth" INCLUDED
  ;

: VAR-DEMO  ( -- )
  S" VARDEMO.fth" INCLUDED
  ;

: SRC-DEMO  ( -- )
  S" SRCDEMO.fth" INCLUDED
  ;

: PRINT-DEMO  ( -- )
  S" PRINTDEMO.fth" INCLUDED
  ;

: .ARM64  ( -- )
  TVERSION CR
  .64HOST
  .ASMARM64
  [DEFINED] .NATARM64 [IF] .NATARM64 [THEN]
  S" Image: " TYPE IMAGE-FILENAME COUNT TYPE
  S"   map: " TYPE IMAGE-MAPNAME COUNT TYPE CR
  [DEFINED] MACHO-FILENAME [IF]
    S"   macho: " TYPE MACHO-FILENAME COUNT TYPE S" .c (+ build.sh)" TYPE CR
  [THEN]
  S"   /MAP /NOMAP  /HDR /NOHDR  /MACHO /NOMACHO  NOSAVE /SAVE" TYPE CR
  S"   /MACHO-BUILD /NOMACHO-BUILD  (auto-cc via SYSTEM; default on)" TYPE CR
  S"   SAVE-IMAGE-FILE  SAVE-MACHO-FILE  MACHO-ENTRY-SET" TYPE CR
  S" Try: ARM64-DEMO IF-DEMO NEST-DEMO VAR-DEMO SRC-DEMO PRINT-DEMO" TYPE CR
  [DEFINED] .DIR [IF] .DIR [THEN]
  ;

FORTH DEFINITIONS
S" OPTARM64 loaded." TYPE CR
