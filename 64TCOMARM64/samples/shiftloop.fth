\ shiftloop.fth — LSHIFT RSHIFT UNLOOP ?DO
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/shiftloop.fth
\   ./samples/shiftloop ; echo $?

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

: SCAN  ( -- n )
  5 0 DO
    I 2 = IF  I UNLOOP EXIT  THEN
  LOOP
  -1
  ;

: MAIN
  S" LSHIFT " TYPE
  1 3 LSHIFT
  8 EXPECT
  1 64 LSHIFT
  0 EXPECT

  S" RSHIFT " TYPE
  8 2 RSHIFT
  2 EXPECT
  -1 1 RSHIFT
  $7FFFFFFFFFFFFFFF EXPECT

  S" ?DO skip " TYPE
  0
  5 5 ?DO  1+  LOOP
  0 EXPECT

  S" ?DO run " TYPE
  0
  3 0 ?DO  I +  LOOP
  3 EXPECT

  S" UNLOOP " TYPE
  SCAN
  2 EXPECT

  FAILS
;
