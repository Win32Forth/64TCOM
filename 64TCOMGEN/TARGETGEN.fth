\ TARGETGEN.fth — Load 64TCOM GEN configuration
\
\ Public domain.
\ Classic analogue: tcom25/TCOMGEN/TARGGEN.FTH
\
\ Load order:
\   1. ../64TCOMSRC/64HOST.fth   — host layer
\   2. ../64TCOMSRC/64DIR.fth    — symbol table + thin director (Phase 1.2)
\   3. ASMGEN.fth                — stub assembler
\   4. OPTGEN.fth                — GEN deferred hooks + tag stream
\   5. LIBGEN.fth                — library cookies (+ SYM registration)
\
\ How to load (from 64Forth):
\   CHDIR to the 64TCOMGEN directory, then:
\     FLOAD TARGETGEN.fth
\   Or INCLUDE with a full path to this file (nested relatives resolve
\   next to each included file on 64Forth).
\
\ After load:
\   .GEN          status
\   GEN-DEMO      short self-test
\   FLOAD TESTGEN.fth

\ Need TCOM-ANEW before the pack marker (defined in 64HOST; bootstrap copy here)
FORTH DEFINITIONS DECIMAL
[UNDEFINED] TCOM-ANEW [IF]
: TCOM-ANEW  ( "<spaces>name" -- )
  >IN @ >R
  BL WORD FIND IF  DROP R@ >IN ! FORGET  ELSE  DROP  THEN
  R> >IN !  CREATE
  ;
[THEN]

TCOM-ANEW TARGETGEN

FORTH DEFINITIONS
DECIMAL

." 64TCOM GEN: loading…" CR

\ --- Host layer (parent directory) ------------------------------------------
\ 64Forth nested INCLUDE sets logical cwd to this file's directory, so
\ ../64TCOMSRC/64HOST.fth resolves correctly when this file is loaded.

INCLUDE ../64TCOMSRC/64HOST.fth
INCLUDE ../64TCOMSRC/64DIR.fth

\ --- GEN pack ---------------------------------------------------------------

INCLUDE ASMGEN.fth
INCLUDE OPTGEN.fth
INCLUDE LIBGEN.fth

\ --- Ready ------------------------------------------------------------------

TCOM-ORDER
TCOM-WARN-ON

." 64TCOM GEN ready — " TVERSION CR
." Try:  .GEN  .DIR  .SYMBOLS  GEN-DEMO  FLOAD TESTGEN.fth" CR
