\ extras.fth — double, string, parse, search-order extras, ABORT"
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/extras.fth
\   ./samples/extras ; echo $?

0 VALUE FAILS
CREATE BUF  16 ALLOT

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

VOCABULARY APP
ALSO APP
PREVIOUS
ALSO APP DEFINITIONS
: IN-APP  7 ;
ONLY FORTH ALSO APP DEFINITIONS
WORDLIST CONSTANT WL

: MAIN
  S" D= " TYPE
  1 0  1 0 D=
  -1 EXPECT
  1 0  2 0 D=
  0 EXPECT

  S" D< " TYPE
  1 0  2 0 D<
  -1 EXPECT
  2 0  1 0 D<
  0 EXPECT

  S" DNEGATE " TYPE
  1 0 DNEGATE
  -1 EXPECT
  -1 EXPECT

  S" DABS " TYPE
  -5 -1 DABS
  0 EXPECT
  5 EXPECT

  S" D2* " TYPE
  3 0 D2*
  0 EXPECT
  6 EXPECT

  S" M+ " TYPE
  1 0 4 M+
  0 EXPECT
  5 EXPECT

  S" COMPARE " TYPE
  S" abc" S" abc" COMPARE
  0 EXPECT
  S" abc" S" abd" COMPARE
  0< -1 EXPECT

  S" SEARCH " TYPE
  S" foobar" S" oba" SEARCH
  -1 EXPECT
  4 EXPECT
  DROP

  S" -TRAILING " TYPE
  S" hi  " -TRAILING
  2 EXPECT
  DROP

  S" /STRING " TYPE
  S" hello" 2 /STRING
  3 EXPECT
  DROP

  S" BLANK " TYPE
  S" xxxx" DROP BUF 4 MOVE
  BUF 4 BLANK
  BUF C@
  32 EXPECT

  S" SOURCE " TYPE
  S" aa bb" SOURCE!
  BL WORD COUNT
  2 EXPECT
  DROP
  BL WORD COUNT
  2 EXPECT
  DROP

  S" PARSE " TYPE
  S" one,two" SOURCE!
  [CHAR] , PARSE
  3 EXPECT
  DROP

  S" GET-ORDER " TYPE
  GET-ORDER
  DUP 0> -1 EXPECT
  BEGIN DUP WHILE SWAP DROP 1- REPEAT DROP

  S" IN-APP " TYPE
  IN-APP
  7 EXPECT

  S" ABORTq " TYPE
  -1
  0 ABORT" should-not-run"
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
