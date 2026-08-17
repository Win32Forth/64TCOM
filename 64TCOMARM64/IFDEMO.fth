\ IFDEMO.fth — Phase 3.5+ control flow smoke (TIF / TELSE / TTHEN)
\ Public domain. Loaded by IF-DEMO.
\
\ Builds:
\   IFT  : 5 IF 1 ELSE 2 THEN  → 1
\   IFF  : 0 IF 1 ELSE 2 THEN  → 2
\   IFN  : 5 IF 7 THEN         → 7   (no else; flag consumed)
\   IFZ  : 0 IF 7 THEN         → 0   (false: TOS after drop was empty→0? need care)
\
\ For IFZ: after TIF drops 0, stack empty → we need a known TOS under the flag.
\ Pattern:  9  0  IF  7  THEN  → false path leaves 9

TARGET-INIT
/SHOW
FORTH DEFINITIONS

\ ----- IFT: 5 IF 1 ELSE 2 THEN => 1 -----
T: IFT
  5 G,
  TIF
    1 G,
  TELSE
    2 G,
  TTHEN
;T

\ ----- IFF: 0 IF 1 ELSE 2 THEN => 2 -----
T: IFF
  0 G,
  TIF
    1 G,
  TELSE
    2 G,
  TTHEN
;T

\ ----- IFN: 9 5 IF 7 THEN => 7  (true path) -----
T: IFN
  9 G,
  5 G,
  TIF
    7 G,
  TTHEN
;T

\ ----- IFZ: 9 0 IF 7 THEN => 9  (false: keep under) -----
T: IFZ
  9 G,
  0 G,
  TIF
    7 G,
  TTHEN
;T

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: (IF-RUN)  ( c-addr u -- x0 )  RUN-SYM ;

: IF-DEMO-CHECK  ( -- )
  S" IFT" (IF-RUN) RX !
  S" IFT => " TYPE RX @ . CR
  RX @ 1 <> IF S" IF-DEMO fail IFT (want 1)" TYPE CR ABORT THEN

  S" IFF" (IF-RUN) RX !
  S" IFF => " TYPE RX @ . CR
  RX @ 2 <> IF S" IF-DEMO fail IFF (want 2)" TYPE CR ABORT THEN

  S" IFN" (IF-RUN) RX !
  S" IFN => " TYPE RX @ . CR
  RX @ 7 <> IF S" IF-DEMO fail IFN (want 7)" TYPE CR ABORT THEN

  S" IFZ" (IF-RUN) RX !
  S" IFZ => " TYPE RX @ . CR
  RX @ 9 <> IF S" IF-DEMO fail IFZ (want 9)" TYPE CR ABORT THEN

  S" IF-DEMO: OK (TIF/TELSE/TTHEN via sim)" TYPE CR
  ;

IF-DEMO-CHECK
