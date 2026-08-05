\ TESTGEN.fth — Sample “compile” for 64TCOM GEN
\
\ Public domain.
\ Requires: FLOAD TARGETGEN.fth  first (or load this only after GEN is up).
\
\   FLOAD TARGETGEN.fth
\   FLOAD TESTGEN.fth

TCOM-ANEW TESTGEN

FORTH DEFINITIONS
DECIMAL

." TESTGEN: compiling sample under GEN..." CR

TARGET-INIT
/SHOW

L: HELLO-MSG
  $0048 G,          \ demo literal
  $0069 G,
;L

T: HELLO
  $0048 G,          \ 'H'
  $0065 G,          \ 'e'
  ['] DUP#  LIB,
  ['] DROP# LIB,
  ['] NOOP# LIB,
;T

T: MAIN
  G' HELLO          \ name lookup (works even if order were reversed)
  0 G,
;T

GEN-FINISH

CR ." TESTGEN complete." CR
." HERE-T=" HERE-T .  ."  COLD-START=" COLD-START . CR
." HELLO cookie=" HELLO .  ."  MAIN cookie=" MAIN . CR
." Dump (up to 64 bytes):" CR
: (TESTGEN-DUMP)  ( -- )
  {: | n i :}
  HERE-T 64 MIN TO n
  0 TO i
  BEGIN i n < WHILE
    i C@-T H2.
    i 15 AND 15 = IF CR THEN
    i 1+ TO i
  REPEAT
  ;
(TESTGEN-DUMP)
CR
." TESTGEN: OK (GEN log + image tags only)" CR
