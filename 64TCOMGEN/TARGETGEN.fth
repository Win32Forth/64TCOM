\ TARGETGEN.fth — Load 64TCOM GEN configuration
\
\ Public domain.
\ Classic analogue: tcom25/TCOMGEN/TARGGEN.FTH
\
\ Load order:
\   1. ../64TCOMSRC/64HOST.fth
\   2. ../64TCOMSRC/64DIR.fth
\   3. ASMGEN.fth  OPTGEN.fth  LIBGEN.fth
\
\ Debug hang / load position:
\   FILE-ECHO ON          \ echo each source line as it is interpreted
\   FLOAD TARGETGEN.fth
\   FILE-ECHO OFF         \ quiet again when done
\ Breadcrumbs also print [TARGETGEN] / [64DIR] markers via TYPE.

FORTH DEFINITIONS DECIMAL

\ Bootstrap TCOM-ANEW (no locals — keep load path simple)
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

TCOM-ANEW TARGETGEN

FORTH DEFINITIONS
DECIMAL

\ Echo loaded source lines (64Forth host extension)
FILE-ECHO ON

S" [TARGETGEN] loading..." TYPE CR

S" [TARGETGEN] 64HOST..." TYPE CR
INCLUDE ../64TCOMSRC/64HOST.fth
S" [TARGETGEN] 64HOST done" TYPE CR

S" [TARGETGEN] 64DIR..." TYPE CR
INCLUDE ../64TCOMSRC/64DIR.fth
S" [TARGETGEN] 64DIR done" TYPE CR

S" [TARGETGEN] ASMGEN..." TYPE CR
INCLUDE ASMGEN.fth
S" [TARGETGEN] OPTGEN..." TYPE CR
INCLUDE OPTGEN.fth
S" [TARGETGEN] LIBGEN..." TYPE CR
INCLUDE LIBGEN.fth
S" [TARGETGEN] pack done" TYPE CR

TCOM-ORDER
TCOM-WARN-ON

FILE-ECHO OFF

S" 64TCOM GEN ready — " TYPE TVERSION CR
S" Try:  .GEN  .DIR  .SYMBOLS  GEN-DEMO  FWD-DEMO" TYPE CR
