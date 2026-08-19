\ memdbl.fth — 2! CELL- FILL ERASE MOVE CMOVE> COUNT  D+ D- S>D D>S  and .
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/memdbl.fth
\   ./samples/memdbl ; echo $?

CREATE BUF  32 ALLOT
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
  S" 2!2@ " TYPE
  11 22 BUF 2!
  BUF 2@
  22 EXPECT
  11 EXPECT

  S" CELL- " TYPE
  16 CELL-
  8 EXPECT

  S" FILL " TYPE
  BUF 4 65 FILL
  BUF C@
  65 EXPECT
  BUF 3 + C@
  65 EXPECT

  S" ERASE " TYPE
  BUF 4 ERASE
  BUF C@
  0 EXPECT
  BUF 3 + C@
  0 EXPECT

  S" COUNT " TYPE
  3 BUF C!
  65 BUF 1+ C!
  66 BUF 2 + C!
  67 BUF 3 + C!
  BUF COUNT
  3 EXPECT
  C@
  65 EXPECT

  S" CMOVE> " TYPE
  BUF 8 ERASE
  65 BUF C!
  66 BUF 1+ C!
  BUF BUF 1+ 2 CMOVE>
  BUF 1+ C@
  65 EXPECT
  BUF 2 + C@
  66 EXPECT

  S" MOVE " TYPE
  BUF 8 ERASE
  65 BUF C!
  66 BUF 1+ C!
  BUF BUF 1+ 2 MOVE
  BUF 1+ C@
  65 EXPECT
  BUF 2 + C@
  66 EXPECT

  S" D+ " TYPE
  5 0 3 0 D+
  0 EXPECT
  8 EXPECT

  S" D- " TYPE
  8 0 3 0 D-
  0 EXPECT
  5 EXPECT

  S" S>D " TYPE
  -3 S>D
  -1 EXPECT
  -3 EXPECT
  7 S>D
  0 EXPECT
  7 EXPECT

  S" D>S " TYPE
  9 0 D>S
  9 EXPECT

  S" . " TYPE
  DECIMAL
  -42 .
  CR
  HEX
  255 .
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
