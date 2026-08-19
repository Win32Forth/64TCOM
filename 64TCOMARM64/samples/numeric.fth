\ numeric.fth — <# # #S #> HOLD SIGN U. .R U.R HEX DECIMAL BASE
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/numeric.fth
\   ./samples/numeric ; echo $?

0 VALUE FAILS

: FAIL  ( -- )  FAILS 1+ TO FAILS ;

: EXPECT  ( got want -- )
  = IF
    S" ok
" TYPE
  ELSE
    S" FAIL
" TYPE
    FAIL
  THEN
  ;

: MAIN
  S" BASE " TYPE
  DECIMAL
  BASE @
  10 EXPECT
  HEX
  BASE @
  16 EXPECT
  DECIMAL

  S" #S dec " TYPE
  255 0 <# #S #>
  3 EXPECT
  DUP C@
  50 EXPECT
  DUP 1+ C@
  53 EXPECT
  2 + C@
  53 EXPECT

  S" #S hex " TYPE
  HEX
  255 0 <# #S #>
  2 EXPECT
  DUP C@
  70 EXPECT
  1+ C@
  70 EXPECT
  DECIMAL

  S" HOLD " TYPE
  0 0 <# 65 HOLD 66 HOLD #>
  2 EXPECT
  DUP C@
  66 EXPECT
  1+ C@
  65 EXPECT

  S" SIGN " TYPE
  -1 12 0 <# #S ROT SIGN #>
  3 EXPECT
  C@
  45 EXPECT

  S" U. " TYPE
  42 U.
  CR

  S" .R " TYPE
  7 4 .R
  CR

  S" U.R " TYPE
  HEX 255 4 U.R
  DECIMAL
  CR

  FAILS 0=
  IF
    S" ALL PASS
" TYPE
    0
  ELSE
    S" FAILS " TYPE FAILS . CR
    1
  THEN
;
