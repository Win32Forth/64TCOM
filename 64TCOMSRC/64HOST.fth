\ 64HOST.fth — Host support layer for 64TCOM on 64Forth
\
\ Public domain.
\
\ Purpose
\   Phase 1 host substrate for the 64TCOM director. Assumes 64Forth already
\   provides Core/Search-Order essentials (VOCABULARY, ALSO, ONLY, PREVIOUS,
\   ORDER, DEFINITIONS, GET-CURRENT, SET-CURRENT, DEFER, IS, ALIAS, VALUE, TO,
\   ALLOCATE, FREE, CELL, CELLS, ANEW, …).
\
\ This file adds:
\   • 64TCOM vocabularies HOST, COMPILER, TARGET, HTARGET (+ immediate [names])
\   • Search-order / definition helpers (>FORTH >HOST >COMPILER >TARGET, H: C:)
\   • Error helpers and CSP stack-check helpers
\   • Target image buffers and deferred memory operators (c@-t @-t c!-t !-t
\     c,-t ,-t allot-t s,-t …) sized for native 8-byte cells (T-CELL)
\   • Compile-mode flags and common DEFERs the director/GEN will install into
\
\ Load (from 64TCOMSRC, or any path):
\   INCLUDE 64HOST.fth
\ Reload-safe via TCOM-ANEW (quiet; no "Loading module" banner).
\
\ Status: Phase 1 scaffold — not a full director.

FORTH DEFINITIONS
DECIMAL

\ Quiet counterpart to 64Forth ANEW — same FORGET/CREATE reload semantics,
\ without printing "Loading module:" (nested INCLUDE of pack files stays tidy).
[UNDEFINED] TCOM-ANEW [IF]
: TCOM-ANEW  ( "<spaces>name" -- )
  >IN @ >R
  BL WORD FIND IF
    DROP  R@ >IN !  FORGET
  ELSE
    DROP
  THEN
  R> >IN !  CREATE
  ;
[THEN]

TCOM-ANEW 64HOST

FORTH DEFINITIONS
DECIMAL

\ =============================================================================
\ Compatibility extras (missing or handy on 64Forth; candidates for the kernel)
\ =============================================================================
\
\ 64Forth already has U< U> >= <= <> 0<> 0> WITHIN, etc.
\ These fill gaps used by 64TCOM (and common in F-PC / ANS practice).
\ Prefer [UNDEFINED] so a later 64Forth built-in wins without redefinition.

\ --- Unsigned comparisons ---
[UNDEFINED] U>= [IF]
: U>=  ( u1 u2 -- flag )  U< 0= ;   \ u1 >= u2 (unsigned)
[THEN]

[UNDEFINED] U<= [IF]
: U<=  ( u1 u2 -- flag )  U> 0= ;   \ u1 <= u2 (unsigned)
[THEN]

[UNDEFINED] UMIN [IF]
: UMIN  ( u1 u2 -- u )  2DUP U< IF DROP ELSE NIP THEN ;
[THEN]

[UNDEFINED] UMAX [IF]
: UMAX  ( u1 u2 -- u )  2DUP U< IF NIP ELSE DROP THEN ;
[THEN]

\ --- Address / string helpers ---
[UNDEFINED] BOUNDS [IF]
: BOUNDS  ( addr len -- addr+len addr )  OVER + SWAP ;
[THEN]

[UNDEFINED] -ROT [IF]
: -ROT  ( x1 x2 x3 -- x3 x1 x2 )  ROT ROT ;
[THEN]

[UNDEFINED] CELL- [IF]
: CELL-  ( a-addr -- a-addr' )  CELL - ;
[THEN]

[UNDEFINED] CHAR- [IF]
: CHAR-  ( c-addr -- c-addr' )  1- ;
[THEN]

\ Logical NOT (flag invert). Bitwise complement remains INVERT.
[UNDEFINED] NOT [IF]
: NOT  ( x -- flag )  0= ;
[THEN]

\ Inclusive range: lo <= n <= hi  (uses WITHIN: lo <= n < hi+1)
[UNDEFINED] BETWEEN [IF]
: BETWEEN  ( n lo hi -- flag )  1+ WITHIN ;
[THEN]

\ --- Double / stack sugar used often in ports ---
[UNDEFINED] 2NIP [IF]
: 2NIP  ( x1 x2 x3 x4 -- x3 x4 )  2SWAP 2DROP ;
[THEN]

[UNDEFINED] 3DUP [IF]
: 3DUP  ( x1 x2 x3 -- x1 x2 x3 x1 x2 x3 )
  2 PICK  2 PICK  2 PICK ;
[THEN]

\ --- Display ---
[UNDEFINED] H. [IF]
: H.  ( u -- )  \ unsigned in hex with trailing space, BASE restored
  BASE @ >R  HEX  U.  R> BASE ! ;
[THEN]

\ =============================================================================
\ Identification
\ =============================================================================

: 64HOST-VER  ( -- )
  ." 64HOST for 64TCOM on 64Forth — Phase 1 host layer" cr
  ." Native 64-bit cells; target image buffers; HOST/COMPILER/TARGET vocs." cr
  ;

\ =============================================================================
\ Vocabularies
\ =============================================================================
\
\ Classic TCOM used HOST / COMPILER / TARGET / HTARGET (and ASSEMBLER from the
\ host Forth). 64Forth already has ASSEMBLER, EDITOR, FP, BIG-INTEGER.
\
\ Usage pattern (typical):
\   ONLY FORTH ALSO HOST DEFINITIONS
\   or the helpers >HOST >COMPILER >TARGET >FORTH below.

VOCABULARY HOST
VOCABULARY COMPILER
VOCABULARY TARGET
VOCABULARY HTARGET

\ Immediate vocabulary switches — classic [HOST] [FORTH] [TARGET] style.
\ Each word executes the vocabulary (pushes it onto the search order).

: [HOST]       ( -- )  HOST       ; IMMEDIATE
: [FORTH]      ( -- )  FORTH      ; IMMEDIATE
: [COMPILER]   ( -- )  COMPILER   ; IMMEDIATE
: [TARGET]     ( -- )  TARGET     ; IMMEDIATE
: [HTARGET]    ( -- )  HTARGET    ; IMMEDIATE
: [ASSEMBLER]  ( -- )  ASSEMBLER  ; IMMEDIATE

\ Definition-context helpers (vocabulary only — do not change TCOM-MODE):
\ ONLY FORTH, then ALSO the named voc, DEFINITIONS.

: HOST-DEFS      ( -- )  ONLY FORTH ALSO HOST DEFINITIONS ;
: COMPILER-DEFS  ( -- )  ONLY FORTH ALSO COMPILER DEFINITIONS ;
: TARGET-DEFS    ( -- )  ONLY FORTH ALSO TARGET DEFINITIONS ;
: HTARGET-DEFS   ( -- )  ONLY FORTH ALSO HTARGET DEFINITIONS ;
: FORTH-DEFS     ( -- )  ONLY FORTH DEFINITIONS ;

\ Recommended full TCOM search order for interactive work:
\   ONLY FORTH ALSO ASSEMBLER ALSO COMPILER ALSO HOST ALSO TARGET

: TCOM-ORDER  ( -- )
  ONLY FORTH
  ALSO ASSEMBLER
  ALSO COMPILER
  ALSO HOST
  ALSO TARGET
  DEFINITIONS
  ;

\ H:  C:  — start a colon definition whose *header* is linked into HOST or
\ COMPILER, then restore CURRENT so compilation semantics stay predictable.
\ (Body still goes at HERE in the shared dictionary.)

: H:  ( "<spaces>name" -- )
  GET-CURRENT >R
  HOST DEFINITIONS
  :
  R> SET-CURRENT
  ;

: C:  ( "<spaces>name" -- )
  GET-CURRENT >R
  COMPILER DEFINITIONS
  :
  R> SET-CURRENT
  ;

\ =============================================================================
\ Compile / library mode (classic >FORTH >LIBRARY >TARGET)
\ =============================================================================

0 CONSTANT TCOM-MODE-FORTH
1 CONSTANT TCOM-MODE-LIBRARY
2 CONSTANT TCOM-MODE-TARGET

TCOM-MODE-FORTH VALUE TCOM-MODE

\ Mode + search order (classic TCOM names)
\ Important: do NOT use ONLY TARGET alone — that hides HOST (library cookies
\ like DUP# live in HOST). Keep the full TCOM order; only CURRENT changes.

: >FORTH  ( -- )
  TCOM-MODE-FORTH TO TCOM-MODE
  ONLY FORTH DEFINITIONS
  ;

: >LIBRARY  ( -- )
  TCOM-MODE-LIBRARY TO TCOM-MODE
  ONLY FORTH
  ALSO ASSEMBLER
  ALSO COMPILER
  ALSO TARGET
  ALSO HOST
  DEFINITIONS                 \ CURRENT = HOST; TARGET still searchable
  ;

: >TARGET  ( -- )
  TCOM-MODE-TARGET TO TCOM-MODE
  TCOM-ORDER                  \ FORTH ASSEM COMPILER HOST TARGET; CURRENT=TARGET
  ;

\ Aliases
: TCOM>FORTH    ( -- )  >FORTH ;
: TCOM>LIBRARY  ( -- )  >LIBRARY ;
: TCOM>TARGET   ( -- )  >TARGET ;

\ Vocab helpers without mode change (explicit names)
: >HOST      ( -- )  HOST-DEFS ;
: >COMPILER  ( -- )  COMPILER-DEFS ;
: >HTARGET   ( -- )  HTARGET-DEFS ;

\ Convenience flags (classic TCOM had many; start with a useful core)

FALSE VALUE ?LIB          \ true while defining library (L:) material
FALSE VALUE ?OPT          \ optimizer enabled
FALSE VALUE ?SHOW         \ show symbols as defined
FALSE VALUE ?CODE         \ /CODE listing style
FALSE VALUE ?INTERPRETIVE \ interpretive compile path
FALSE VALUE ?NOSAVE       \ do not write image file
FALSE VALUE ?UNRES        \ unresolved forward refs remain
FALSE VALUE ?QUIET        \ quiet messages

: NOSAVE  ( -- )  TRUE  TO ?NOSAVE ;
: /OPT    ( -- )  TRUE  TO ?OPT ;
: /NOOPT  ( -- )  FALSE TO ?OPT ;
: /SHOW   ( -- )  TRUE  TO ?SHOW ;
: /QUIET  ( -- )  TRUE  TO ?QUIET ;

\ =============================================================================
\ Error helpers and CSP
\ =============================================================================

VARIABLE CSP

: !CSP  ( -- )  DEPTH CSP ! ;
: ?CSP  ( -- )
  DEPTH CSP @ <>
  IF  -22 THROW  THEN   \ classic control-structure style; see also ?TCOMCSP
  ;

\ Soft message + abort for compiler errors (string from counted or c-addr u)

DEFER "ERRMSG
: (%"ERRMSG)  ( c-addr u -- )
  CR ." 64TCOM: " TYPE CR
  -2 THROW
  ;
' (%"ERRMSG) IS "ERRMSG

: TCOM-ABORT  ( c-addr u -- )  "ERRMSG ;
: TCOM-ERROR  ( c-addr u -- )  CR ." 64TCOM: " TYPE CR ;

\ Stack-change check used by classic TCOM ; paths
: ?TCOMCSP  ( -- )
  DEPTH CSP @ <>
  IF  S" Stack Changed" TCOM-ABORT  THEN
  ;

: ?COMPILING  ( -- )
  STATE @ 0=
  IF  S" Not Compiling!" TCOM-ABORT  THEN
  ;

: ?EXECUTING  ( -- )
  STATE @
  IF  S" Not Interpreting!" TCOM-ABORT  THEN
  ;

\ =============================================================================
\ Host dictionary convenience
\ =============================================================================

\ fhere — host HERE (classic TCOM used fhere when target stole the name HERE)
: FHERE  ( -- addr )  HERE ;

\ Optional: silence redefinition noise while loading large packs
: TCOM-WARN-OFF  ( -- )  REDEF-WARNING OFF ;
: TCOM-WARN-ON   ( -- )  REDEF-WARNING ON ;

\ =============================================================================
\ Target cell / endianness
\ =============================================================================
\
\ Phase 0: GEN and native ARM64 intent use 8-byte target cells.
\ Cross-targets that need 2-byte cells will set T-CELL in their OPT pack later.

8 CONSTANT T-CELL-DEFAULT
T-CELL-DEFAULT VALUE T-CELL     \ bytes per target cell for ,-t / @-t / !-t

\ Byte order for multi-byte target stores/fetches (within T-CELL).
\ /LOW-HIGH = little-endian (default). /HIGH-LOW = reverse bytes on store/fetch.

DEFER T-SWAP-BYTES   \ ( x -- x' ) optional transform of a T-CELL value
: (T-SWAP-NONE)  ( x -- x )  ;
' (T-SWAP-NONE) IS T-SWAP-BYTES

: /LOW-HIGH  ( -- )  ['] (T-SWAP-NONE) IS T-SWAP-BYTES ;

\ Full 64-bit byte swap (for /HIGH-LOW when T-CELL = 8)
: (T-BSWAP64)  ( u -- u' )
  >R
  0
  8 0 DO
    8 LSHIFT
    R@ $FF AND OR
    R> 8 RSHIFT >R
  LOOP
  R> DROP
  ;
: /HIGH-LOW  ( -- )  ['] (T-BSWAP64) IS T-SWAP-BYTES ;

/LOW-HIGH

\ =============================================================================
\ Target image buffers (flat host memory; no segments)
\ =============================================================================

0 VALUE T-CODE-BASE     \ host address of code image (0 = none)
0 VALUE T-DATA-BASE     \ host address of data image
0 VALUE T-CODE-MAX      \ size in bytes
0 VALUE T-DATA-MAX

VARIABLE DP-T           \ target code dictionary pointer (offset)
VARIABLE DP-D           \ target data dictionary pointer (offset)

0 VALUE CODE-START      \ initial DP-T after init
0 VALUE DATA-START      \ initial DP-D after init
0 VALUE TARGET-ORIGIN   \ relocation bias for THERE (usually 0)
0 VALUE DATA-ORIGIN
0 VALUE COLD-START      \ offset of cold entry (pack-defined)
0 VALUE FINAL-EXIT

\ Default image sizes (bytes) — generous for GEN logs / small ITC images
$40000 CONSTANT T-CODE-DEFAULT-SIZE    \ 256 KiB
$40000 CONSTANT T-DATA-DEFAULT-SIZE    \ 256 KiB

: T-FREE-BUF  ( addr -- )
  DUP IF  FREE DROP  ELSE  DROP  THEN
  ;

: TCOM-FREE-MEM  ( -- )
  T-CODE-BASE T-FREE-BUF  0 TO T-CODE-BASE
  T-DATA-BASE T-FREE-BUF  0 TO T-DATA-BASE
  0 TO T-CODE-MAX  0 TO T-DATA-MAX
  0 DP-T !  0 DP-D !
  ;

: TCOM-ALLOC1  ( u -- addr )
  DUP ALLOCATE
  IF  DROP CR ." 64HOST: ALLOCATE failed for " . ." bytes" CR
      S" Target memory allocation failed" TCOM-ABORT
  THEN
  SWAP DROP
  ;

: TCOM-INIT-MEM  ( code-bytes data-bytes -- )
  TCOM-FREE-MEM
  DUP TO T-DATA-MAX
  SWAP DUP TO T-CODE-MAX
  TCOM-ALLOC1 TO T-CODE-BASE
  TCOM-ALLOC1 TO T-DATA-BASE
  T-CODE-BASE T-CODE-MAX ERASE
  T-DATA-BASE T-DATA-MAX ERASE
  CODE-START DP-T !
  DATA-START DP-D !
  ;

: TCOM-INIT-MEM-DEFAULT  ( -- )
  T-CODE-DEFAULT-SIZE T-DATA-DEFAULT-SIZE TCOM-INIT-MEM
  ;

\ Map target offsets to host addresses
: THERE   ( taddr -- addr )  TARGET-ORIGIN + T-CODE-BASE + ;
: DTHERE  ( daddr -- addr )  DATA-ORIGIN  + T-DATA-BASE + ;

: HERE-T  ( -- taddr )  DP-T @ ;
: HERE-D  ( -- daddr )  DP-D @ ;

\ Bounds checks (soft abort)
: ?T-CODE-RANGE  ( taddr -- taddr )
  DUP 0< OVER T-CODE-MAX U>= OR
  IF  DROP S" Target CODE address out of range" TCOM-ABORT  THEN
  ;
: ?T-DATA-RANGE  ( daddr -- daddr )
  DUP 0< OVER T-DATA-MAX U>= OR
  IF  DROP S" Target DATA address out of range" TCOM-ABORT  THEN
  ;

\ -----------------------------------------------------------------------------
\ Deferred target memory API (packs / director may re-IS these)
\ -----------------------------------------------------------------------------

DEFER C@-T
DEFER @-T
DEFER C!-T
DEFER !-T
DEFER C,-T
DEFER ,-T
DEFER ALLOT-T
DEFER S,-T
DEFER O!            \ resolve-store (default: same as !-T)

DEFER ALLOT-D
DEFER C!-D
DEFER !-D
DEFER C,-D
DEFER ,-D
DEFER S,-D

DEFER DATA-SEG-FIX  \ classic segmented fixup; NOOP on flat targets
DEFER TVERSION
DEFER SET-COLD-ENTRY

: (DATA-SEG-FIX-NOOP)  ( -- )  ;
' (DATA-SEG-FIX-NOOP) IS DATA-SEG-FIX

: (TVERSION-DEFAULT)  ( -- )  ."  64TCOM host / GEN-ready " ;
' (TVERSION-DEFAULT) IS TVERSION

: (SET-COLD-DEFAULT)  ( -- )  HERE-T TO COLD-START ;
' (SET-COLD-DEFAULT) IS SET-COLD-ENTRY

\ -----------------------------------------------------------------------------
\ Default flat little-endian implementations (T-CELL wide for cell ops)
\ -----------------------------------------------------------------------------

: (%C@-T)  ( taddr -- char )
  ?T-CODE-RANGE THERE C@
  ;
: (%C!-T)  ( char taddr -- )
  ?T-CODE-RANGE THERE C!
  ;

\ Cell fetch/store: T-CELL bytes, low address = low byte after T-SWAP-BYTES
: (%@-T)  ( taddr -- x )
  ?T-CODE-RANGE
  THERE 0
  T-CELL 0 DO
    OVER I + C@  I 8 * LSHIFT OR
  LOOP
  NIP
  T-SWAP-BYTES
  ;

: (%!-T)  ( x taddr -- )
  ?T-CODE-RANGE
  SWAP T-SWAP-BYTES SWAP
  THERE
  T-CELL 0 DO
    OVER $FF AND  OVER I + C!
    SWAP 8 RSHIFT SWAP
  LOOP
  2DROP
  ;

: (%ALLOT-T)  ( n -- )
  DP-T @ + DUP T-CODE-MAX U>
  IF  DROP S" Target CODE space exhausted" TCOM-ABORT  THEN
  DP-T !
  ;

: (%C,-T)  ( char -- )  HERE-T (%C!-T)  1 (%ALLOT-T) ;
: (%,-T)   ( x -- )     HERE-T (%!-T)   T-CELL (%ALLOT-T) ;

: (%S,-T)  ( c-addr u -- )
  0 MAX  0 ?DO  DUP C@ (%C,-T)  CHAR+  LOOP  DROP
  ;

' (%C@-T)   IS C@-T
' (%@-T)    IS @-T
' (%C!-T)   IS C!-T
' (%!-T)    IS !-T
' (%ALLOT-T) IS ALLOT-T
' (%C,-T)   IS C,-T
' (%,-T)    IS ,-T
' (%S,-T)   IS S,-T
' (%!-T)    IS O!

\ Data space (separate buffer)
: (%C@-D)  ( daddr -- char )  ?T-DATA-RANGE DTHERE C@ ;
: (%C!-D)  ( char daddr -- )  ?T-DATA-RANGE DTHERE C! ;

: (%@-D)  ( daddr -- x )
  ?T-DATA-RANGE
  DTHERE 0
  T-CELL 0 DO  OVER I + C@  I 8 * LSHIFT OR  LOOP
  NIP T-SWAP-BYTES
  ;

: (%!-D)  ( x daddr -- )
  ?T-DATA-RANGE
  SWAP T-SWAP-BYTES SWAP
  DTHERE
  T-CELL 0 DO  OVER $FF AND OVER I + C!  SWAP 8 RSHIFT SWAP  LOOP
  2DROP
  ;

: (%ALLOT-D)  ( n -- )
  DP-D @ + DUP T-DATA-MAX U>
  IF  DROP S" Target DATA space exhausted" TCOM-ABORT  THEN
  DP-D !
  ;

: (%C,-D)  ( char -- )  HERE-D (%C!-D)  1 (%ALLOT-D) ;
: (%,-D)   ( x -- )     HERE-D (%!-D)   T-CELL (%ALLOT-D) ;
: (%S,-D)  ( c-addr u -- )
  0 MAX  0 ?DO  DUP C@ (%C,-D)  CHAR+  LOOP  DROP
  ;

' (%ALLOT-D) IS ALLOT-D
' (%C!-D)    IS C!-D
' (%!-D)     IS !-D
' (%C,-D)    IS C,-D
' (%,-D)     IS ,-D
' (%S,-D)    IS S,-D

: ERASE-T  ( taddr u -- )
  0 ?DO  0 OVER C!-T  1+  LOOP  DROP
  ;

: ERASE-D  ( daddr u -- )
  0 ?DO  0 OVER C!-D  1+  LOOP  DROP
  ;

\ Align data DP
: EVEN-ALIGN-D  ( -- )  HERE-D 1 AND ALLOT-D ;
: CELL-ALIGN-T  ( -- )
  HERE-T T-CELL 1- + T-CELL NEGATE AND  HERE-T -  ALLOT-T
  ;
: CELL-ALIGN-D  ( -- )
  HERE-D T-CELL 1- + T-CELL NEGATE AND  HERE-D -  ALLOT-D
  ;

\ =============================================================================
\ Deferred director / pack hooks (stubs until COMPILE / OPTGEN install)
\ =============================================================================

DEFER COMP-CALL       \ ( sym -- ) compile call/reference to symbol
DEFER COMP-JMP-IMM    \ ( addr -- )
DEFER COMP-SINGLE     \ ( n -- ) compile literal
DEFER COMP-FETCH
DEFER COMP-STORE
DEFER COMP-PERFORM
DEFER COMP-ON
DEFER COMP-OFF
DEFER COMP-INCR
DEFER COMP-DECR
DEFER COMP-PSTORE
DEFER COMP-SAVE
DEFER COMP-SAVEST
DEFER COMP-REST
DEFER COMP-FPUSH

DEFER END-T:
DEFER END-L:
DEFER END-LM:
DEFER END-MACRO
DEFER END-LMACRO
DEFER END-LCODE
DEFER START-T:
DEFER START-L:
DEFER START-LM:
DEFER MACRO-START
DEFER LCODE-START
DEFER TCODE-START
DEFER COMP-HEADER
DEFER RESOLVE-1
DEFER SUB-RET

: (STUB-DROP)   ( x -- )  DROP ;
: (STUB-2DROP)  ( x y -- )  2DROP ;
: (STUB-NOOP)   ( -- )  ;
: (STUB-SYM)    ( sym -- )
  ?SHOW IF  ." [stub] symbol ref " . CR  THEN  DROP
  ;

' (STUB-SYM)   IS COMP-CALL
' (STUB-DROP)  IS COMP-JMP-IMM
' (STUB-DROP)  IS COMP-SINGLE
' (STUB-NOOP)  IS COMP-FETCH
' (STUB-NOOP)  IS COMP-STORE
' (STUB-NOOP)  IS COMP-PERFORM
' (STUB-NOOP)  IS COMP-ON
' (STUB-NOOP)  IS COMP-OFF
' (STUB-NOOP)  IS COMP-INCR
' (STUB-NOOP)  IS COMP-DECR
' (STUB-NOOP)  IS COMP-PSTORE
' (STUB-NOOP)  IS COMP-SAVE
' (STUB-NOOP)  IS COMP-SAVEST
' (STUB-NOOP)  IS COMP-REST
' (STUB-NOOP)  IS COMP-FPUSH
' (STUB-NOOP)  IS END-T:
' (STUB-NOOP)  IS END-L:
' (STUB-NOOP)  IS END-LM:
' (STUB-NOOP)  IS END-MACRO
' (STUB-NOOP)  IS END-LMACRO
' (STUB-NOOP)  IS END-LCODE
' (STUB-NOOP)  IS START-T:
' (STUB-NOOP)  IS START-L:
' (STUB-NOOP)  IS START-LM:
' (STUB-NOOP)  IS MACRO-START
' (STUB-NOOP)  IS LCODE-START
' (STUB-NOOP)  IS TCODE-START
' (STUB-DROP)  IS COMP-HEADER
' (STUB-DROP)  IS RESOLVE-1
' (STUB-NOOP)  IS SUB-RET

\ Image extension name (classic image.ext)
CREATE IMAGE.EXT  8 ALLOT
S" BIN" IMAGE.EXT PLACE

\ =============================================================================
\ Status / self-test helpers
\ =============================================================================

: .64HOST  ( -- )
  CR 64HOST-VER
  ." T-CELL=" T-CELL . ." bytes" CR
  BASE @ >R HEX
  ." CODE image: base=" T-CODE-BASE U. ."  max=" DECIMAL T-CODE-MAX . ."  HERE-T=" HERE-T . CR
  HEX
  ." DATA image: base=" T-DATA-BASE U. ."  max=" DECIMAL T-DATA-MAX . ."  HERE-D=" HERE-D . CR
  R> BASE !
  ." Mode=" TCOM-MODE .
  TCOM-MODE TCOM-MODE-LIBRARY = IF ." (LIBRARY)" THEN
  TCOM-MODE TCOM-MODE-TARGET  = IF ." (TARGET)"  THEN
  TCOM-MODE TCOM-MODE-FORTH   = IF ." (FORTH)"   THEN
  CR
  ." Vocabularies: HOST COMPILER TARGET HTARGET (plus 64Forth ASSEMBLER)" CR
  ." Mode: >FORTH >LIBRARY >TARGET   Voc only: HOST-DEFS COMPILER-DEFS …" CR
  ." Also: TCOM-ORDER  H:  C:  64HOST-SMOKE" CR
  ORDER
  ;

\ Smoke: write a few cells/bytes into a fresh image and read them back
: 64HOST-SMOKE  ( -- )
  TCOM-INIT-MEM-DEFAULT
  $41 C,-T
  $42 C,-T
  $1234567890ABCDEF ,-T
  0 C@-T $41 <> IF  S" 64HOST-SMOKE C@-T fail" TCOM-ABORT  THEN
  1 C@-T $42 <> IF  S" 64HOST-SMOKE C@-T(1) fail" TCOM-ABORT  THEN
  2 @-T  $1234567890ABCDEF <> IF  S" 64HOST-SMOKE @-T fail" TCOM-ABORT  THEN
  CR ." 64HOST-SMOKE: OK  HERE-T=" HERE-T . CR
  ;

\ Allocate default target memory on load so HERE-T / ,-t are usable immediately
TCOM-INIT-MEM-DEFAULT

FORTH DEFINITIONS
." 64HOST loaded.  (.64HOST  64HOST-SMOKE)" CR
