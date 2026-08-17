\ NESTDEMO.fth — Nested colon calls under true BLR (Roadmap E)
\ Public domain.
\
\ Proves multi-level CALL-ABS / BLR: OUTER → MID → INC → PLUS#,
\ and TIF with nested G' calls.
\
\ Expect (sim and native):
\   OUTER => 7   (5 +1 +1 via MID→INC twice)
\   GO    => 12  (10 +1 +1 via INC2)
\   NIF   => 5   (3 +1 +1 on true path)
\   FWDN  => $2222  (forward G' to LEAF)

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

\ Leaf: ( n -- n+1 )
T: INC
  1 G,
  ' PLUS# LIB,
;T

\ One nest level: ( n -- n+2 )
T: INC2
  G' INC
  G' INC
;T

\ Two nest levels: MID → INC
T: MID
  G' INC
;T

\ OUTER → MID → INC → PLUS#  (depth 3 calls)
T: OUTER
  5 G,
  G' MID
  G' MID
;T

T: GO
  10 G,
  G' INC2
;T

\ IF with nested calls on true path: 3 under, flag 1 → 3+1+1=5
T: NIF
  3 G,
  1 G,
  TIF
    G' INC
    G' INC
  TELSE
    99 G,
  TTHEN
;T

\ Forward call (G' before body), like FWD-ARM64
T: FWDN
  G' LEAF
;T

T: LEAF
  $2222 G,
;T

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: (NEST-RUN)  ( c-addr u -- x0 )  RUN-SYM ;

: (NEST-CHECK1)  ( ca u want -- )
  {: ca u want | x :}
  ca u TYPE S"  => " TYPE
  ca u (NEST-RUN) TO x  x .
  x want <> IF S"  FAIL want " TYPE want . CR ABORT THEN
  CR
  ;

: NEST-DEMO-SIM  ( -- )
  S" --- NEST-DEMO sim ---" TYPE CR
  S" OUTER" 7 (NEST-CHECK1)
  S" GO" 12 (NEST-CHECK1)
  S" NIF" 5 (NEST-CHECK1)
  S" FWDN" $2222 (NEST-CHECK1)
  S" NEST-DEMO: OK (sim)" TYPE CR
  ;

: NEST-DEMO-NAT  ( -- )
  [DEFINED] RUN-SYM-N [IF]
    S" --- NEST-DEMO native (true BLR) ---" TYPE CR
    S" OUTER" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" OUTER => " TYPE RX @ . CR
    RX @ 7 <> IF S" NEST-DEMO fail OUTER native" TYPE CR ABORT THEN
    S" GO" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" GO => " TYPE RX @ . CR
    RX @ 12 <> IF S" NEST-DEMO fail GO native" TYPE CR ABORT THEN
    S" NIF" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" NIF => " TYPE RX @ . CR
    RX @ 5 <> IF S" NEST-DEMO fail NIF native" TYPE CR ABORT THEN
    S" FWDN" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" FWDN => " TYPE RX @ . CR
    RX @ $2222 <> IF S" NEST-DEMO fail FWDN native" TYPE CR ABORT THEN
    S" NEST-DEMO: OK (native true BLR)" TYPE CR
  [ELSE]
    S" NEST-DEMO: skip native (no RUN-SYM-N)" TYPE CR
  [THEN]
  ;

: NEST-DEMO-CHECK  ( -- )
  NEST-DEMO-SIM
  NEST-DEMO-NAT
  S" NEST-DEMO: OK" TYPE CR
  ;

NEST-DEMO-CHECK
