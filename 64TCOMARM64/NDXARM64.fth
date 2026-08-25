\ NDXARM64.fth — Wire classic TCOMNDX index! into ARM64 COMP-CALL / END-T:
\ Public domain. Port of F-PC TCOMNDX (xCC, → calltype index!).
\ Load AFTER TCOMNDX.fth + OPTARM64.
\
\ Does not reimplement CALL-ABS, — wraps the existing (%COMP-CALL) xt.

ONLY FORTH ALSO ASMARM64
FORTH-WORDLIST SET-CURRENT
DECIMAL

' (%COMP-CALL) CONSTANT NDX-OLD-COMP-CALL
' (%END-T:)    CONSTANT NDX-OLD-END-T
' (%END-L:)    CONSTANT NDX-OLD-END-L
[DEFINED] HOST-CALL, [IF]
  ' HOST-CALL, CONSTANT NDX-OLD-HOST-CALL
[THEN]

CREATE NDX-HOST-NAME  32 ALLOT

: NDX-SYM-NAME  ( taddr -- ca u )
  SYM-N @ 0 DO
    I SYM-ADDR@ OVER = IF  DROP I SYM-GET-NAME UNLOOP EXIT  THEN
  LOOP
  DROP S" ?"
  ;

: NDX-COLON-NAME  ( -- ca u )
  [DEFINED] TSRC-LAST [IF]
    TSRC-LAST @ DUP 0< IF  DROP S" -" EXIT  THEN
    SYM-GET-NAME
  [ELSE]
    S" -"
  [THEN]
  ;

\ Prefer live TSRC token (what the programmer wrote); else SYM name.
: NDX-CALL-LABEL  ( taddr -- ca u )
  [DEFINED] TSRC-WORD [IF]
    TSRC-WORD C@ IF  DROP TSRC-WORD COUNT EXIT  THEN
  [THEN]
  NDX-SYM-NAME
  ;

\ COMP-CALL: record type/taddr/ret/name (readable .NDX rows)
: (%COMP-CALL-NDX)  ( taddr -- )
  DUP NDX-T0 !
  HERE-T NDX-T1 !
  NDX-OLD-COMP-CALL EXECUTE
  HERE-T NDX-T2 !
  NDX-CALL NDX-T1 @ NDX-T2 @ NDX-T0 @ NDX-CALL-LABEL NDX-RECORD
  ;
' (%COMP-CALL-NDX) IS COMP-CALL

: (%END-T:-NDX)  ( -- )
  HERE-T NDX-T1 !
  NDX-OLD-END-T EXECUTE
  NDX-RET NDX-T1 @ 0 NDX-COLON-NAME NDX-RECORD
  ;
' (%END-T:-NDX) IS END-T:

: (%END-L:-NDX)  ( -- )
  HERE-T NDX-T1 !
  NDX-OLD-END-L EXECUTE
  NDX-RET NDX-T1 @ 0 NDX-COLON-NAME NDX-RECORD
  ;
' (%END-L:-NDX) IS END-L:

[DEFINED] NDX-OLD-HOST-CALL [IF]
: HOST-CALL,  ( slot -- )
  DUP NDX-T0 !
  HERE-T NDX-T1 !
  NDX-OLD-HOST-CALL EXECUTE
  HERE-T NDX-T2 !
  S" HOST:" NDX-HOST-NAME PLACE
  BASE @ >R DECIMAL
  NDX-T0 @ 0 <# #S #>
  DUP >R NDX-HOST-NAME COUNT + SWAP MOVE
  R> NDX-HOST-NAME C@ + NDX-HOST-NAME C!
  R> BASE !
  NDX-HOST NDX-T1 @ NDX-T2 @ NDX-HOST-NAME COUNT NDX-RECORD
  ;
[THEN]

\ Space/OVER: treat consecutive NDX CALL rows with the same source
\ line+tok as one token.  "/" expands to TOR# STOD# FROMR# SMREM# NIP#
\ — five CALLs, one source word — so one Space must clear all five.
\ Run SIM until PC reaches the last CALL's ret addr (do not execute the
\ colon RET).  On unknown/# HALT, pop one sim frame and keep going.
[DEFINED] TDBG-STEP-OVER-SRC [IF]
VARIABLE TDBG-OVER-LINE
VARIABLE TDBG-OVER-TOK
VARIABLE TDBG-OVER-END
VARIABLE TDBG-OVER-IX

: TDBG-NDX-AT-PC  ( -- ix|-1 )
  DBG-PC@ NDX-FIND
  ;

\ CALL site containing PC: taddr <= PC < ret.  Do NOT match PC==ret —
\ that is already past the BLR and would make SRC-OVER a no-op (stuck).
: TDBG-NDX-CALL-AT  ( -- ix|-1 )
  -1 NDX-FIND-IX !
  DBG-PC@ NDX-FIND-KEY !
  NDX-N @ 0 DO
    I CELLS NDX-TYPE-A @ + @ NDX-CALL = IF
      I CELLS NDX-TADDR-A @ + @ NDX-FIND-KEY @ U> 0=
      I CELLS NDX-RET-A @ + @ NDX-FIND-KEY @ U> AND IF
        I NDX-FIND-IX !
      THEN
    THEN
  LOOP
  NDX-FIND-IX @
  ;

\ ix = a CALL in the group → set TDBG-OVER-END to last same line+tok CALL ret.
: TDBG-SRC-GROUP-END  ( ix -- )
  DUP TDBG-OVER-IX !
  DUP CELLS NDX-LINE-A @ + @ TDBG-OVER-LINE !
  DUP CELLS NDX-TOK-A @ + @ TDBG-OVER-TOK !
  DUP CELLS NDX-RET-A @ + @ TDBG-OVER-END !
  BEGIN
    TDBG-OVER-IX @ 1+ DUP NDX-N @ U>= IF  DROP EXIT  THEN
    DUP CELLS NDX-TYPE-A @ + @ NDX-CALL <> IF  DROP EXIT  THEN
    DUP CELLS NDX-LINE-A @ + @ TDBG-OVER-LINE @ <> IF  DROP EXIT  THEN
    DUP CELLS NDX-TOK-A @ + @ TDBG-OVER-TOK @ <> IF  DROP EXIT  THEN
    DUP TDBG-OVER-IX !
    CELLS NDX-RET-A @ + @ TDBG-OVER-END !
  AGAIN
  ;

: TDBG-STEP-OVER-SRC-NDX  ( -- )
  TDBG-SKIP-LIB
  DBG-HALTED? IF EXIT THEN
  TDBG-NDX-CALL-AT DUP 0< IF
    DROP DBG-STEP-OVER TDBG-SKIP-LIB EXIT
  THEN
  TDBG-SRC-GROUP-END
  [DEFINED] SIM-BRK-EN [IF]
    SIM-BRK-EN @ IF  SIM-PC @ SIM-BRK-SKIP !  THEN
  [THEN]
  FALSE SIM-HALT !
  SIM-STOP-NONE SIM-STOP !
  SIM-RP @ DBG-OVER-T !
  100000 0 DO
    DBG-PC@ TDBG-OVER-END @ U>= IF  UNLOOP EXIT  THEN
    SIM-HALT @ IF
      SIM-RP @ DBG-OVER-T @ U>
      [DEFINED] SIM-R-EMPTY? [IF] SIM-R-EMPTY? 0= AND [THEN]
      IF
        SIM-R-POP SIM-PC !
        FALSE SIM-HALT !
        SIM-STOP-NONE SIM-STOP !
      ELSE
        FALSE SIM-HALT !
        SIM-STOP-NONE SIM-STOP !
        UNLOOP EXIT
      THEN
    ELSE
      SIM-STEP
      SIM-STOP @ SIM-STOP-BREAK = IF  UNLOOP EXIT  THEN
    THEN
  LOOP
  ;
' TDBG-STEP-OVER-SRC-NDX IS TDBG-STEP-OVER-SRC
[THEN]

S" NDXARM64 loaded (wrap COMP-CALL/END-T: → TCOMNDX)." TYPE CR
