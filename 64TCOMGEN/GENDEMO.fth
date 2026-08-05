\ GENDEMO.fth — interpret-time GEN smoke (loaded by GEN-DEMO)
\ Public domain. Requires TARGETGEN already loaded.
\ Use S" … TYPE at interpret time (." can be compile-only / awkward).

TARGET-INIT
/SHOW

T: HI
  $1234 G,
  ' DUP# LIB,
;T

GEN-FINISH

CR
S" GEN-DEMO done. HERE-T=" TYPE HERE-T . CR
S" First bytes: " TYPE
HERE-T 0 MAX 32 MIN 0
BEGIN 2DUP < WHILE
  DUP C@-T H2.
  1+
REPEAT
2DROP CR
.SYMBOLS
S" GEN-DEMO: OK" TYPE CR
