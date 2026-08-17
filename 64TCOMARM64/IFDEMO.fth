\ IFDEMO.fth — Control flow smoke (Roadmap B complete)
\ Public domain.
\
\ Sim + native: IFT/IFF/IFN/IFZ, ZEQ/ZNE, ONCE, PUSHPOP, ADD3, LOOP3, WONCE
\ Mach-O: entry LOOP3 => process exit 3

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

T: IFT   5 G,  TIF 1 G, TELSE 2 G, TTHEN  ;T
T: IFF   0 G,  TIF 1 G, TELSE 2 G, TTHEN  ;T
T: IFN   9 G, 5 G,  TIF 7 G, TTHEN  ;T
T: IFZ   9 G, 0 G,  TIF 7 G, TTHEN  ;T

T: ZEQ   0 G,  T0=,  ;T
T: ZNE   5 G,  T0=,  ;T
T: ONCE  9 G, 1 G,  TBEGIN TUNTIL  ;T

T: PUSHPOP
  7 X0 MOV-X-IMM64,
  X0 X19 -8 STR-PRE,
  0 X0 MOV-X-IMM64,
  X0 X19 8 LDR-POST,
;T

T: ADD3
  0 X0 MOV-X-IMM64,
  1 X1 MOV-X-IMM64,
  X1 X0 X0 ADD-X-X,
  X1 X0 X0 ADD-X-X,
  X1 X0 X0 ADD-X-X,
;T

\ Loop via TLOOP-TO-3, (register-only CBNZ back)
T: LOOP3
  TLOOP-TO-3,
;T

\ BEGIN … WHILE … REPEAT: enter once with true flag, body leaves 7, then false
T: WONCE
  1 G,                 \ first WHILE flag (true)
  TBEGIN
  TWHILE
    7 G,               \ body result under next flag
    0 G,               \ next WHILE flag (false → exit)
  TREPEAT
;T

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: (IF-RUN)  ( c-addr u -- x0 )  RUN-SYM ;

: (IF-CHECK)  ( ca u want -- )
  {: ca u want | x :}
  ca u TYPE S"  => " TYPE
  ca u (IF-RUN) TO x  x .
  x want <> IF S"  FAIL want " TYPE want . CR ABORT THEN
  CR
  ;

: .LOOP3-CODE  ( -- )
  S" LOOP3" SYM-FIND-IX SYM-ADDR@
  S" LOOP3 code @ " TYPE DUP SYM-HEX. CR
  S" expect after MOV#0: 91000400 AA0003E1 D1000C21 B5FFFFA1" TYPE CR
  16 0 DO
    DUP I 4 * + W@-T
    BASE @ >R HEX 0 <# # # # # # # # # #> TYPE SPACE R> BASE !
    I 7 = IF CR THEN
  LOOP CR DROP
  ;

: IF-DEMO-CHECK  ( -- )
  .LOOP3-CODE
  S" --- IF-DEMO sim ---" TYPE CR
  S" IFT" 1 (IF-CHECK)
  S" IFF" 2 (IF-CHECK)
  S" IFN" 7 (IF-CHECK)
  S" IFZ" 9 (IF-CHECK)
  S" ZEQ" 1 (IF-CHECK)
  S" ZNE" 0 (IF-CHECK)
  S" ONCE" 9 (IF-CHECK)
  S" PUSHPOP" 7 (IF-CHECK)
  S" ADD3" 3 (IF-CHECK)
  S" LOOP3" 3 (IF-CHECK)
  S" WONCE" 7 (IF-CHECK)
  S" IF-DEMO: OK (sim)" TYPE CR
  ;

: (IF-NAT1)  ( ca u want -- )
  {: ca u want | x :}
  ca u TYPE S"  => " TYPE
  ca u RUN-SYM-N TO x  x .
  x want <> IF S"  FAIL native want " TYPE want . CR ABORT THEN
  CR
  ;

: IF-DEMO-NAT  ( -- )
  [DEFINED] RUN-SYM-N [IF]
    S" --- IF-DEMO native ---" TYPE CR
    S" IFT" 1 (IF-NAT1)
    S" IFF" 2 (IF-NAT1)
    S" IFN" 7 (IF-NAT1)
    S" IFZ" 9 (IF-NAT1)
    S" ZEQ" 1 (IF-NAT1)
    S" ZNE" 0 (IF-NAT1)
    S" ONCE" 9 (IF-NAT1)
    S" PUSHPOP" 7 (IF-NAT1)
    S" ADD3" 3 (IF-NAT1)
    S" LOOP3" 3 (IF-NAT1)
    S" WONCE" 7 (IF-NAT1)
    S" IF-DEMO: OK (native)" TYPE CR
  [ELSE]
    S" IF-DEMO: skip native" TYPE CR
  [THEN]
  ;

\ Mach-O entry LOOP3: standalone process should exit with status 3
: IF-DEMO-MACHO  ( -- )
  [DEFINED] SAVE-MACHO-FILE [IF]
    S" --- IF-DEMO Mach-O LOOP3 ---" TYPE CR
    S" LOOP3" MACHO-ENTRY-SET
    SAVE-MACHO-FILE
    [DEFINED] SYSTEM [IF]
      S" ./tcomarm64" SYSTEM
      S" Mach-O LOOP3 exit (want 3) = " TYPE DUP . CR
      3 <> IF S" fail IF-DEMO Mach-O LOOP3" TYPE CR ABORT THEN
      S" IF-DEMO: OK (Mach-O LOOP3 => 3)" TYPE CR
    [ELSE]
      S" IF-DEMO: Mach-O sources written; no SYSTEM — run sh tcomarm64-build.sh" TYPE CR
    [THEN]
  [ELSE]
    S" IF-DEMO: skip Mach-O" TYPE CR
  [THEN]
  ;

: IF-DEMO-ALL  ( -- )
  IF-DEMO-CHECK
  IF-DEMO-NAT
  IF-DEMO-MACHO
  S" IF-DEMO: OK (Roadmap B complete)" TYPE CR
  ;

IF-DEMO-ALL
