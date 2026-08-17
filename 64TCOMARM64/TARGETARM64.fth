\ TARGETARM64.fth — Load 64TCOM ARM64 configuration
\
\ Public domain.
\ Load from 64TCOMARM64/:
\   FLOAD TARGETARM64.fth
\
\ Then:  .ARM64  ARM64-DEMO  FWD-ARM64
\
\ Optional: FILE-ECHO ON  before FLOAD for a full line trace.

FORTH DEFINITIONS DECIMAL

[UNDEFINED] TCOM-ANEW [IF]
: TCOM-ANEW  ( "<spaces>name" -- )
  >IN @
  BL WORD FIND IF
    DROP OVER >IN ! FORGET
  ELSE
    DROP
  THEN
  >IN !  CREATE
  ;
[THEN]

TCOM-ANEW TARGETARM64

FORTH DEFINITIONS
DECIMAL

FILE-ECHO OFF

S" [TARGETARM64] loading..." TYPE CR
INCLUDE ../64TCOMSRC/64HOST.fth
INCLUDE ../64TCOMSRC/64DIR.fth
INCLUDE ASMARM64.fth
INCLUDE OPTARM64.fth
INCLUDE LIBARM64.fth
INCLUDE SIMARM64.fth
INCLUDE NATARM64.fth
INCLUDE MACHOARM64.fth
\ Generic .tfth loader (compiler) — after pack hooks/prims exist
INCLUDE ../64TCOMSRC/64SRC.fth

\ Pack wrapper: .tfth → image → Mach-O entry MAIN (after 64SRC is loaded)
: TSRC-BUILD  ( ca u -- )
  TARGET-INIT
  LL-INIT
  TSRC-INCLUDE
  ARM64-FINISH
  S" MAIN" MACHO-ENTRY-SET
  SAVE-MACHO-FILE
  ;

\ ----- TCOM path …  — parse filename, build next to source (MAIN entry) -----
\   TCOM samples/print.tfth     → samples/print  (+ .c .bin -build.sh)
\   TCOM "path with spaces/x.tfth"  → path with spaces/x
CREATE TCOM-SRC   256 ALLOT
CREATE TCOM-OUT   256 ALLOT
34 CONSTANT TCOM-QUOT

\ Skip blanks in the input stream
: TCOM-SKIP-BL  ( -- )
  BEGIN
    SOURCE NIP >IN @ U<= IF EXIT THEN
    SOURCE DROP >IN @ + C@
    DUP BL = OVER 9 = OR OVER 10 = OR OVER 13 = OR IF
      DROP 1 >IN +!
    ELSE DROP EXIT THEN
  AGAIN
  ;

\ Next path: bare word, or "quoted string" (spaces allowed)
: TCOM-PARSE-PATH  ( -- c-addr u )
  TCOM-SKIP-BL
  SOURCE NIP >IN @ U<= IF
    S" TCOM needs a source filename" TCOM-ABORT
  THEN
  SOURCE DROP >IN @ + C@ TCOM-QUOT = IF
    1 >IN +!
    TCOM-QUOT PARSE
  ELSE
    BL WORD COUNT
  THEN
  DUP 0= IF 2DROP S" TCOM needs a source filename" TCOM-ABORT THEN
  ;

\ True if (ca u) ends with .tfth or .TFTH (5 chars)
: TCOM-HAS-TFTH  ( c-addr u -- f )
  DUP 5 < IF 2DROP FALSE EXIT THEN
  + 5 -  ( ca' )
  DUP C@ [CHAR] . <> IF DROP FALSE EXIT THEN
  1+ DUP C@ 32 OR [CHAR] t <> IF DROP FALSE EXIT THEN
  1+ DUP C@ 32 OR [CHAR] f <> IF DROP FALSE EXIT THEN
  1+ DUP C@ 32 OR [CHAR] t <> IF DROP FALSE EXIT THEN
  1+     C@ 32 OR [CHAR] h =
  ;

\ Path → same dir, strip .tfth only (keep folder prefix; into TCOM-OUT)
: TCOM-MAKE-OUT-NAME  ( c-addr u -- )
  2DUP TCOM-HAS-TFTH IF 5 - THEN
  DUP 0= IF 2DROP S" TCOM: empty output name" TCOM-ABORT THEN
  250 UMIN TCOM-OUT PLACE
  ;

\ Set MACHO-FILENAME and IMAGE-FILENAME (.bin) from TCOM-OUT base path
: TCOM-SET-OUTPUT-NAMES  ( -- )
  TCOM-OUT COUNT MACHO-FILENAME PLACE
  TCOM-OUT COUNT 250 UMIN PAD PLACE
  PAD COUNT +
  [CHAR] . OVER C! 1+
  [CHAR] b OVER C! 1+
  [CHAR] i OVER C! 1+
  [CHAR] n SWAP C!
  PAD C@ 4 + PAD C!
  PAD COUNT IMAGE-FILENAME PLACE
  ;

\ Compile path → MAIN Mach-O beside the .tfth (same directory)
: (TCOM)  ( c-addr u -- )
  DUP 250 U> IF 2DROP S" TCOM: path too long" TCOM-ABORT THEN
  2DUP TCOM-SRC PLACE
  TCOM-MAKE-OUT-NAME
  TCOM-SET-OUTPUT-NAMES
  ?QUIET 0= IF
    S" TCOM: " TYPE TCOM-SRC COUNT TYPE
    S"  → " TYPE TCOM-OUT COUNT TYPE CR
  THEN
  TARGET-INIT
  LL-INIT
  TCOM-SRC COUNT TSRC-INCLUDE
  ARM64-FINISH
  S" MAIN" MACHO-ENTRY-SET
  SAVE-MACHO-FILE
  ;

: TCOM  ( "<spaces>path" | "<spaces>\"path with spaces\"" -- )
  /NOMACHO-GUI
  TCOM-PARSE-PATH (TCOM)
  ;

\ Layer 4 GUI build: same as TCOM but AppKit .m shell + run loop
: TCOM-GUI  ( "<spaces>path" | "<spaces>\"path with spaces\"" -- )
  /MACHO-GUI
  TCOM-PARSE-PATH (TCOM)
  /NOMACHO-GUI
  ;

TCOM-ORDER
TCOM-WARN-ON

: (A64-CLEAR-STACK)  ( -- )
  BEGIN DEPTH WHILE DROP REPEAT
  ;
(A64-CLEAR-STACK)

S" 64TCOM ARM64 ready — " TYPE TVERSION CR
S" HERE-T=" TYPE HERE-T . S"  LIB-CODE-END=" TYPE LIB-CODE-END @ . CR
S" Native: .RUN-ANS-N   Standalone: SAVE-MACHO-FILE (see .MACHOARM64)" TYPE CR
S" Try: TCOM samples/print.tfth  |  TCOM-GUI window/win.tfth" TYPE CR
