\ TARGETGEN.fth — Load 64TCOM GEN configuration
\
\ Public domain.
\ Classic analogue: tcom25/TCOMGEN/TARGGEN.FTH
\
\ Load order:
\   1. ../64TCOMSRC/64HOST.fth   — host layer (vocabularies, image buffers)
\   2. ASMGEN.fth                — stub assembler
\   3. OPTGEN.fth                — deferred hooks + thin T:/;T director
\   4. LIBGEN.fth                — stub library cookies
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

ANEW TARGETGEN

FORTH DEFINITIONS
DECIMAL

." === 64TCOM GEN: loading ===" CR

\ --- Host layer (parent directory) ------------------------------------------
\ 64Forth nested INCLUDE sets logical cwd to this file's directory, so
\ ../64TCOMSRC/64HOST.fth resolves correctly when this file is loaded.

INCLUDE ../64TCOMSRC/64HOST.fth

\ --- GEN pack ---------------------------------------------------------------

INCLUDE ASMGEN.fth
INCLUDE OPTGEN.fth
INCLUDE LIBGEN.fth

\ --- Ready ------------------------------------------------------------------

TCOM-ORDER
TCOM-WARN-ON

." === 64TCOM GEN ready === " TVERSION CR
." Try:  .GEN   GEN-DEMO   FLOAD TESTGEN.fth" CR
