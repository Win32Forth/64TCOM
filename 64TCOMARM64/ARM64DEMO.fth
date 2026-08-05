\ ARM64DEMO.fth — sample compile under ARM64 pack
\ Public domain. Loaded by ARM64-DEMO.

TARGET-INIT
/SHOW

T: HI
  $1234 G,
  ' DUP# LIB,
;T

ARM64-FINISH

CR
S" ARM64-DEMO done. HERE-T=" TYPE HERE-T . CR
ARM64-DUMP
S" ARM64-DEMO: OK" TYPE CR
