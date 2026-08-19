\ wave.fth — C@ C! +! 2DROP XOR 0< ABS MIN MAX PICK LEAVE EXECUTE [']
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/wave.fth
\   ./samples/wave ; echo $?
\
\ Prints one line per check. Exit 0 if all pass.

VARIABLE V
CREATE BYTES  8 ALLOT
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

: INC  ( n -- n+1 )  1+ ;

: MAIN
  S" 2DROP " TYPE
  1 2 3 4 2DROP 2DROP
  9
  9 EXPECT

  S" XOR " TYPE
  7 3 XOR
  4 EXPECT

  S" 0< " TYPE
  -5 0<
  -1 EXPECT
  3 0<
  0 EXPECT

  S" ABS " TYPE
  -7 ABS
  7 EXPECT
  8 ABS
  8 EXPECT

  S" MIN " TYPE
  3 8 MIN
  3 EXPECT
  8 3 MIN
  3 EXPECT

  S" MAX " TYPE
  3 8 MAX
  8 EXPECT

  S" +! " TYPE
  0 V !
  5 V +!
  2 V +!
  V @
  7 EXPECT

  S" C!C@ " TYPE
  65 BYTES C!
  66 BYTES 1+ C!
  BYTES C@
  65 EXPECT
  BYTES 1+ C@
  66 EXPECT

  S" PICK " TYPE
  10 20 30 2 PICK
  10 EXPECT
  2DROP DROP

  S" EXECUTE " TYPE
  41 ['] INC EXECUTE
  42 EXPECT

  S" LEAVE " TYPE
  0
  5 0 DO
    I 3 = IF DROP I LEAVE THEN
    DROP I
  LOOP
  3 EXPECT

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
