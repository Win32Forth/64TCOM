\ files.fth — ANS File-Access (CREATE-FILE OPEN-FILE READ-LINE …)
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/files.fth
\   ./samples/files ; echo $?

0 VALUE FAILS
0 VALUE FD
CREATE BUF  80 ALLOT

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
  S" /tmp/tcom-ans-a.txt" DELETE-FILE DROP
  S" /tmp/tcom-ans-b.txt" DELETE-FILE DROP

  S" CREATE-FILE " TYPE
  S" /tmp/tcom-ans-a.txt" W/O BIN CREATE-FILE
  0 EXPECT
  TO FD

  S" WRITE-LINE " TYPE
  S" hello-ans" FD WRITE-LINE
  0 EXPECT
  FD FLUSH-FILE
  0 EXPECT

  S" FILE-SIZE " TYPE
  FD FILE-SIZE
  0 EXPECT
  0 EXPECT
  10 EXPECT
  FD CLOSE-FILE
  0 EXPECT

  S" OPEN-FILE " TYPE
  S" /tmp/tcom-ans-a.txt" R/O OPEN-FILE
  0 EXPECT
  TO FD

  S" READ-LINE " TYPE
  BUF 80 FD READ-LINE
  0 EXPECT
  -1 EXPECT
  9 EXPECT

  S" FILE-POSITION " TYPE
  FD FILE-POSITION
  0 EXPECT
  0 EXPECT
  10 EXPECT

  0 0 FD REPOSITION-FILE
  0 EXPECT
  BUF 80 FD READ-FILE
  0 EXPECT
  10 EXPECT
  FD CLOSE-FILE DROP

  S" RENAME-FILE " TYPE
  S" /tmp/tcom-ans-a.txt" S" /tmp/tcom-ans-b.txt" RENAME-FILE
  0 EXPECT

  S" FILE-STATUS " TYPE
  S" /tmp/tcom-ans-b.txt" FILE-STATUS
  0 EXPECT
  DROP
  S" /tmp/tcom-ans-a.txt" FILE-STATUS
  0= 0 EXPECT
  DROP

  S" /tmp/tcom-ans-b.txt" R/W OPEN-FILE
  0 EXPECT
  TO FD
  0 0 FD RESIZE-FILE
  0 EXPECT
  FD FILE-SIZE
  0 EXPECT
  0 EXPECT
  0 EXPECT
  FD CLOSE-FILE DROP

  S" DELETE-FILE " TYPE
  S" /tmp/tcom-ans-b.txt" DELETE-FILE
  0 EXPECT

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
