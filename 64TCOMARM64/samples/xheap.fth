\ xheap.fth — CATCH THROW ALLOCATE FREE RESIZE
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/xheap.fth
\   ./samples/xheap ; echo $?

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

: BOOM  7 THROW ;

: QUIET ;

: MAIN
  S" CATCH0 " TYPE
  ['] QUIET CATCH
  0 EXPECT

  S" THROW " TYPE
  ['] BOOM CATCH
  7 EXPECT

  S" 0THROW " TYPE
  0 THROW
  1 1 EXPECT

  S" ALLOC " TYPE
  32 ALLOCATE
  0 EXPECT
  DUP 65 SWAP C!
  DUP C@
  65 EXPECT

  S" RESIZE " TYPE
  64 RESIZE
  0 EXPECT
  DUP C@
  65 EXPECT

  S" FREE " TYPE
  FREE
  0 EXPECT

  S" ALL PASS
" TYPE
  0
;
