\ stackcmp.fth — 2SWAP 2OVER TUCK ?DUP ROLL DEPTH  0> 0<> <= >= U< U> WITHIN
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/stackcmp.fth
\   ./samples/stackcmp ; echo $?

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
  S" 2SWAP " TYPE
  1 2 3 4 2SWAP
  2 EXPECT
  1 EXPECT
  4 EXPECT
  3 EXPECT

  S" 2OVER " TYPE
  1 2 3 4 2OVER
  2 EXPECT
  1 EXPECT
  4 EXPECT
  3 EXPECT
  2 EXPECT
  1 EXPECT

  S" TUCK " TYPE
  1 2 TUCK
  2 EXPECT
  1 EXPECT
  2 EXPECT

  S" ?DUP " TYPE
  0 ?DUP DEPTH
  1 EXPECT
  DROP
  7 ?DUP
  7 EXPECT
  7 EXPECT

  S" ROLL " TYPE
  10 20 30 2 ROLL
  10 EXPECT
  30 EXPECT
  20 EXPECT
  99 0 ROLL
  99 EXPECT

  S" DEPTH " TYPE
  1 2 3 DEPTH
  3 EXPECT
  2DROP DROP

  S" 0> " TYPE
  3 0>
  -1 EXPECT
  0 0>
  0 EXPECT
  -1 0>
  0 EXPECT

  S" 0<> " TYPE
  4 0<>
  -1 EXPECT
  0 0<>
  0 EXPECT

  S" <= " TYPE
  3 8 <=
  -1 EXPECT
  8 3 <=
  0 EXPECT
  5 5 <=
  -1 EXPECT

  S" >= " TYPE
  8 3 >=
  -1 EXPECT
  3 8 >=
  0 EXPECT

  S" U< " TYPE
  1 2 U<
  -1 EXPECT
  -1 1 U<
  0 EXPECT

  S" U> " TYPE
  -1 1 U>
  -1 EXPECT
  1 2 U>
  0 EXPECT

  S" WITHIN " TYPE
  5 0 10 WITHIN
  -1 EXPECT
  10 0 10 WITHIN
  0 EXPECT
  0 0 10 WITHIN
  -1 EXPECT
  5 5 6 WITHIN
  -1 EXPECT

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
