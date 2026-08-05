\ GENDEMO.fth — interpret-time GEN smoke (loaded by GEN-DEMO)
\ Public domain. Requires TARGETGEN already loaded.

TARGET-INIT
/SHOW

T: HI
  $1234 G,
  ' DUP# LIB,
;T

GEN-FINISH

CR ." GEN-DEMO done. HERE-T=" HERE-T . CR
." First bytes: "
HERE-T 0 MAX 32 MIN 0
BEGIN 2DUP < WHILE
  DUP C@-T H2.
  1+
REPEAT
2DROP CR
.SYMBOLS
." GEN-DEMO: OK" CR
