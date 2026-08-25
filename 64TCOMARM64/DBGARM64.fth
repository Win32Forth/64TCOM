\ DBGARM64.fth — SIMARM64 backend for TCOMDBG DEFER hooks
\
\ Public domain. Load after TCOMDBG.fth (TARGETARM64 order).
\ Defines A64-* implementations and IS's them into TCOMDBG DEFERs.
\ Do NOT redefine DBG-* with colon words — that shadows DEFERs and
\ leaves WHERE/TDEBUG still calling the stub.

TCOM-ANEW DBGARM64

FORTH DEFINITIONS
DECIMAL

VARIABLE DBG-A
VARIABLE DBG-U
VARIABLE DBG-N
VARIABLE DBG-I
VARIABLE DBG-BEST
VARIABLE DBG-BEST-A
VARIABLE DBG-OVER-T
VARIABLE DBG-TMP

: A64-DBG-PC@  ( -- taddr )  SIM-PC @ ;
: A64-DBG-X0@  ( -- x )  0 SIM-X@ ;
: A64-DBG-FETCH  ( taddr -- x )  @-T ;
: A64-DBG-STORE  ( x taddr -- )  !-T ;
: A64-DBG-ARMED?  ( -- f )  SIM-BRK-EN @ ;
: A64-DBG-HALTED?  ( -- f )  SIM-HALT @ ;

: A64-DBG-SYM@  ( taddr -- ca u )
  DBG-A !
  -1 DBG-BEST !
  0 DBG-BEST-A !
  SYM-N @ 0= IF  S" ?" EXIT  THEN
  SYM-N @ 0 DO
    I SYM-ADDR@ DUP DBG-A @ U> IF  DROP
    ELSE
      DBG-BEST @ 0< IF
        DBG-BEST-A !  I DBG-BEST !
      ELSE
        DUP DBG-BEST-A @ U> IF
          DBG-BEST-A !  I DBG-BEST !
        ELSE  DROP  THEN
      THEN
    THEN
  LOOP
  DBG-BEST @ 0< IF  S" ?" EXIT  THEN
  DBG-BEST @ SYM-GET-NAME
  ;

\ RLABEL must not reuse DBG-A/DBG-U — A64-DBG-SYM@ overwrites DBG-A with the
\ taddr under search, which made `DBG-A @ C!` store into a target address
\ (agent: after STEP-OVER, C! to 41816 → XCSTORE). Own scratch only.
VARIABLE DBG-LAB-A
VARIABLE DBG-LAB-U
: A64-DBG-RLABEL  ( i addr u -- )
  \ (i dest maxlen) — copy nearest SYM name for TDBG-RBUF[i] into dest.
  DBG-LAB-U !  DBG-LAB-A !  DBG-I !
  DBG-LAB-A @ 0= IF  EXIT  THEN
  DBG-I @ 16 U>= IF  0 DBG-LAB-A @ C! EXIT  THEN
  TDBG-RBUF DBG-I @ CELLS + @
  DBG-SYM@                                 \ ca u
  BEGIN DEPTH 2 > WHILE  ROT DROP  REPEAT
  DEPTH 2 < IF  DROP 0 DBG-LAB-A @ C! EXIT  THEN
  DBG-LAB-U @ UMIN  63 MIN
  DUP DBG-LAB-A @ C!
  DBG-LAB-A @ CHAR+ SWAP CMOVE
  ;

: A64-DBG-RSTACK  ( addr u -- n )
  DBG-U !  DBG-A !
  SIM-RP @ SIM-R - CELL /
  DBG-U @ UMIN DUP DBG-N !
  0 DBG-I !
  BEGIN  DBG-I @ DBG-N @ < WHILE
    SIM-RP @ DBG-I @ 1+ CELLS - @
    DBG-A @ DBG-I @ CELLS + !
    1 DBG-I +!
  REPEAT
  DBG-N @
  ;

: A64-DBG-STACK  ( addr u -- n )
  DBG-U !  DBG-A !
  DBG-U @ 0= IF  0 EXIT  THEN
  0 SIM-X@  DBG-A @ !
  1 DBG-N !
  SIM-DSP0 @ 19 SIM-X@ - 8 /
  DUP 0< IF  DROP 0  THEN
  DBG-U @ 1- UMIN
  0 DBG-I !
  BEGIN  DBG-I @ OVER < WHILE
    19 SIM-X@ DBG-I @ CELLS + @
    DBG-A @ DBG-N @ CELLS + !
    1 DBG-N +!
    1 DBG-I +!
  REPEAT
  DROP
  DBG-N @
  ;

: A64-DBG-BREAK!  ( taddr f -- )
  IF  SIM-BRK-ADD  TRUE SIM-BRK-EN !
  ELSE  SIM-BRK-DEL
    SIM-BRK-N @ 0= IF  FALSE SIM-BRK-EN !  THEN
  THEN
  ;

: A64-DBG-START  ( taddr -- )
  SIM-INIT
  SIM-PC !
  ;

: A64-DBG-STEP-INTO  ( -- )
  SIM-BRK-EN @ IF  SIM-PC @ SIM-BRK-SKIP !  THEN
  FALSE SIM-HALT !
  0 DBG-TMP !
  BEGIN
    SIM-HALT @ 0=
  WHILE
    1 DBG-TMP +!
    DBG-TMP @ 100000 > IF
      TRUE SIM-HALT !  EXIT
    THEN
    SIM-PC @ SIM-W@ DBG-I !
    DBG-I @ SIM-IS-CALL? IF  SIM-STEP EXIT  THEN
    DBG-I @ SIM-IS-RET?  IF  SIM-STEP EXIT  THEN
    SIM-STEP
    SIM-STOP @ SIM-STOP-BREAK = IF EXIT THEN
  REPEAT
  ;

\ OVER = one Forth word atomically: INTO once; if that nested a CALL, keep
\ stepping until sim R depth is restored (do not stop inside the callee).
\ If the callee hits unknown/# prim junk, snap out via return link.
: A64-DBG-STEP-OVER  ( -- )
  SIM-BRK-EN @ IF  SIM-PC @ SIM-BRK-SKIP !  THEN
  FALSE SIM-HALT !
  SIM-RP @ DBG-OVER-T !
  DBG-STEP-INTO
  BEGIN
    SIM-RP @ DBG-OVER-T @ U> 0= IF EXIT THEN    \ not nested — done
    SIM-HALT @ IF
      BEGIN
        SIM-RP @ DBG-OVER-T @ U>
        SIM-R-EMPTY? 0= AND
      WHILE
        SIM-R-POP SIM-PC !
      REPEAT
      FALSE SIM-HALT !
      SIM-STOP-NONE SIM-STOP !
      EXIT
    THEN
    SIM-STEP
    SIM-STOP @ SIM-STOP-BREAK = IF EXIT THEN
  AGAIN
  ;

: A64-DBG-GO  ( -- )
  SIM-BRK-EN @ IF  SIM-PC @ SIM-BRK-SKIP !  THEN
  FALSE SIM-HALT !
  BEGIN SIM-HALT @ 0= WHILE SIM-STEP REPEAT
  ;

' A64-DBG-PC@       IS DBG-PC@
' A64-DBG-STACK     IS DBG-STACK
' A64-DBG-RSTACK    IS DBG-RSTACK
' A64-DBG-RLABEL    IS DBG-RLABEL
' A64-DBG-FETCH     IS DBG-FETCH
' A64-DBG-STORE     IS DBG-STORE
' A64-DBG-BREAK!    IS DBG-BREAK!
' A64-DBG-STEP-INTO IS DBG-STEP-INTO
' A64-DBG-STEP-OVER IS DBG-STEP-OVER
' A64-DBG-GO        IS DBG-GO
' A64-DBG-SYM@      IS DBG-SYM@
' A64-DBG-START     IS DBG-START
' A64-DBG-ARMED?    IS DBG-ARMED?
' A64-DBG-HALTED?   IS DBG-HALTED?
' A64-DBG-X0@       IS DBG-X0@

FORTH DEFINITIONS
S" DBGARM64 loaded (SIMARM64 hooks IS'd into TCOMDBG)." TYPE CR
