\ VARDEMO.fth — Target VARIABLE + @ / ! (data space)
\ Public domain.
\
\ TVARIABLE allocates a cell in T-DATA (host buffer). G' name pushes that
\ host address (SYM-DATA → COMP-SINGLE). FETCH#/STORE# load/store through it.
\ Works on sim and in-process native (same process, absolute host data ptrs).
\
\ Expect:
\   VGET  => 0     (fresh zero cell)
\   VSET  => 42    (store 42, fetch back)
\   VINC  => 43    (fetch, +1, store, fetch)
\   VSWP  => 100   (two vars; X=7 Y=100; copy Y→X; fetch X)

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

TVARIABLE X
TVARIABLE Y

\ ( -- 0 )  fetch X (should be 0 after TARGET-INIT erase)
T: VGET
  G' X
  ' FETCH# LIB,
;T

\ ( -- 42 )  X := 42 ; X @
T: VSET
  42 G,
  G' X
  ' STORE# LIB,
  G' X
  ' FETCH# LIB,
;T

\ ( -- 43 )  assume X is 42 from prior... but each RUN-SYM is fresh X0 only;
\ data persists across RUN-SYM in same image. Order: VSET then VINC in check.
T: VINC
  G' X
  ' FETCH# LIB,
  1 G,
  ' PLUS# LIB,
  G' X
  ' STORE# LIB,
  G' X
  ' FETCH# LIB,
;T

\ Use G@ G! sugar: X := 7 ; Y := 100 ; X := Y @ ; X @
T: VSWP
  7 G,
  G' X  G!
  100 G,
  G' Y  G!
  G' Y  G@
  G' X  G!
  G' X  G@
;T

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: (VAR-RUN)  ( ca u -- x0 )  RUN-SYM ;

: (VAR-CHECK)  ( ca u want -- )
  {: ca u want | x :}
  ca u TYPE S"  => " TYPE
  ca u (VAR-RUN) TO x  x .
  x want <> IF S"  FAIL want " TYPE want . CR ABORT THEN
  CR
  ;

: VAR-DEMO-SIM  ( -- )
  S" --- VAR-DEMO sim ---" TYPE CR
  S" VGET" 0 (VAR-CHECK)
  S" VSET" 42 (VAR-CHECK)
  S" VINC" 43 (VAR-CHECK)
  S" VSWP" 100 (VAR-CHECK)
  S" VAR-DEMO: OK (sim)" TYPE CR
  ;

: VAR-DEMO-NAT  ( -- )
  [DEFINED] RUN-SYM-N [IF]
    S" --- VAR-DEMO native ---" TYPE CR
    \ Fresh image already ran sim on same data — re-zero X/Y for clean native
    \ by re-running VGET path only after re-init would wipe. Re-FLOAD demo
    \ would rebuild. Instead run VSET/VINC/VSWP which set their own state.
    S" VSET" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" VSET => " TYPE RX @ . CR
    RX @ 42 <> IF S" VAR-DEMO fail VSET native" TYPE CR ABORT THEN
    S" VINC" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" VINC => " TYPE RX @ . CR
    RX @ 43 <> IF S" VAR-DEMO fail VINC native" TYPE CR ABORT THEN
    S" VSWP" SYM-FIND-IX SYM-ADDR@ RUN-NATIVE RX !
    S" VSWP => " TYPE RX @ . CR
    RX @ 100 <> IF S" VAR-DEMO fail VSWP native" TYPE CR ABORT THEN
    S" VAR-DEMO: OK (native)" TYPE CR
  [ELSE]
    S" VAR-DEMO: skip native" TYPE CR
  [THEN]
  ;

: VAR-DEMO-CHECK  ( -- )
  VAR-DEMO-SIM
  VAR-DEMO-NAT
  S" VAR-DEMO: OK" TYPE CR
  ;

VAR-DEMO-CHECK
