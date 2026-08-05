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
  HELLO GCALL       \ HELLO returns cookie; CALL it
  0 G,
;T

GEN-FINISH

CR ." TESTGEN complete." CR
." HERE-T=" HERE-T .  ."  COLD-START=" COLD-START . CR
." HELLO cookie=" HELLO .  ."  MAIN cookie=" MAIN . CR
." Dump (up to 64 bytes):" CR
HERE-T 64 MIN  0 ?DO
  I C@-T
  BASE @ >R HEX  0 <# # # #> TYPE SPACE  R> BASE !
  I 15 AND 15 = IF CR THEN
LOOP
CR
." TESTGEN: OK (GEN log + image tags only)" CR
