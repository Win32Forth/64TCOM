\ arith.fth — signed / MOD /MOD */ */MOD M* UM* UM/MOD SM/REM FM/MOD
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/arith.fth
\   ./samples/arith ; echo $?
\
\ / /MOD MOD */ */MOD use SM/REM (toward zero), like C.

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
  S" / " TYPE
  10 3 /
  3 EXPECT
  -10 3 /
  -3 EXPECT

  S" MOD " TYPE
  10 3 MOD
  1 EXPECT
  -10 3 MOD
  -1 EXPECT

  S" /MOD " TYPE
  10 3 /MOD
  3 EXPECT
  1 EXPECT

  S" UM* " TYPE
  3 5 UM*
  0 EXPECT
  15 EXPECT

  S" M* " TYPE
  -3 5 M*
  -1 EXPECT
  -15 EXPECT

  S" UM/MOD " TYPE
  10 0 3 UM/MOD
  3 EXPECT
  1 EXPECT

  S" SM/REM " TYPE
  -10 S>D 3 SM/REM
  -3 EXPECT
  -1 EXPECT

  S" FM/MOD " TYPE
  -10 S>D 3 FM/MOD
  -4 EXPECT
  2 EXPECT

  S" */ " TYPE
  7 3 2 */
  10 EXPECT

  S" */MOD " TYPE
  7 3 2 */MOD
  10 EXPECT
  1 EXPECT

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
