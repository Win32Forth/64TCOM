\ GENDEMO.fth — interpret-time GEN smoke (loaded by GEN-DEMO)
\ Public domain. Requires TARGETGEN already loaded.
\ Dump loop is a colon def (interpret BEGIN/WHILE is unreliable).

TARGET-INIT
/SHOW

T: HI
  $1234 G,
  ' DUP# LIB,
;T

GEN-FINISH

CR
S" GEN-DEMO done. HERE-T=" TYPE HERE-T . CR

VARIABLE GD-N
VARIABLE GD-I

: GEN-DEMO-DUMP  ( -- )
  S" First bytes: " TYPE
  HERE-T 32 UMIN GD-N !
  0 GD-I !
  BEGIN GD-I @ GD-N @ < WHILE
    GD-I @ C@-T H2.
    1 GD-I +!
  REPEAT
  CR
  .SYMBOLS
  S" GEN-DEMO: OK" TYPE CR
  ;

GEN-DEMO-DUMP
