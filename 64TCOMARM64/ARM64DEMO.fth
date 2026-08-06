\ ARM64DEMO.fth — Phase 3.0c: lit + DUP + PLUS under real prims
\ Public domain. Loaded by ARM64-DEMO.
\
\ Compiles roughly:  2  3  +   with TOS/DSP ABI
\   T: ANS  2 G,  3 G,  ' PLUS# LIB,  ;T

TARGET-INIT
/SHOW

T: ANS
  2 G,
  3 G,
  ' PLUS# LIB,
;T

T: HI
  $1234 G,
  ' DUP# LIB,
;T

ARM64-FINISH

CR
S" ARM64-DEMO done. HERE-T=" TYPE HERE-T . CR
S" ANS @ " TYPE S" ANS" SYM-FIND-IX SYM-ADDR@ SYM-HEX. CR
S" HI  @ " TYPE S" HI"  SYM-FIND-IX SYM-ADDR@ SYM-HEX. CR
ARM64-DUMP
S" ARM64-DEMO: OK (real prims; ABI X0=TOS X19=DSP)" TYPE CR
S" Next: .RUN-ANS   (sim ANS => 5)   .RUN-ANS-N  (native BLR => 5)" TYPE CR
