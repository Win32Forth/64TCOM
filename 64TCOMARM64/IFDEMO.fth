\ IFDEMO.fth — Control flow smoke
\ Public domain.

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

\ Loop via TLOOP-TO-3, (register-only CBZ+B; no TUNTIL stack)
T: LOOP3
  TLOOP-TO-3,
;T

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX
: (IF-RUN)  ( c-addr u -- x0 )  RUN-SYM ;

: .LOOP3-CODE  ( -- )
  S" LOOP3" SYM-FIND-IX SYM-ADDR@
  S" LOOP3 code @ " TYPE DUP SYM-HEX. CR
  S" expect after MOV#0: 91000400 AA0003E1 D1000C21 B5FFFFA1" TYPE CR
  \ 4 MOV#0 + ADD + MOV + SUB + CBNZ + RET = 9 words; dump 16
  16 0 DO
    DUP I 4 * + W@-T
    BASE @ >R HEX 0 <# # # # # # # # # #> TYPE SPACE R> BASE !
    I 7 = IF CR THEN
  LOOP CR DROP
  ;

: IF-DEMO-CHECK  ( -- )
  .LOOP3-CODE

  S" --- IF-DEMO sim ---" TYPE CR
  S" IFT" (IF-RUN) RX !  S" IFT => " TYPE RX @ . CR
  RX @ 1 <> IF S" fail IFT" TYPE CR ABORT THEN
  S" IFF" (IF-RUN) RX !  S" IFF => " TYPE RX @ . CR
  RX @ 2 <> IF S" fail IFF" TYPE CR ABORT THEN
  S" IFN" (IF-RUN) RX !  S" IFN => " TYPE RX @ . CR
  RX @ 7 <> IF S" fail IFN" TYPE CR ABORT THEN
  S" IFZ" (IF-RUN) RX !  S" IFZ => " TYPE RX @ . CR
  RX @ 9 <> IF S" fail IFZ" TYPE CR ABORT THEN
  S" ZEQ" (IF-RUN) RX !  S" ZEQ => " TYPE RX @ . CR
  RX @ 1 <> IF S" fail ZEQ" TYPE CR ABORT THEN
  S" ZNE" (IF-RUN) RX !  S" ZNE => " TYPE RX @ . CR
  RX @ 0 <> IF S" fail ZNE" TYPE CR ABORT THEN
  S" ONCE" (IF-RUN) RX ! S" ONCE => " TYPE RX @ . CR
  RX @ 9 <> IF S" fail ONCE" TYPE CR ABORT THEN
  S" PUSHPOP" (IF-RUN) RX ! S" PUSHPOP => " TYPE RX @ . CR
  RX @ 7 <> IF S" fail PUSHPOP" TYPE CR ABORT THEN
  S" ADD3" (IF-RUN) RX ! S" ADD3 => " TYPE RX @ . CR
  RX @ 3 <> IF S" fail ADD3" TYPE CR ABORT THEN
  S" LOOP3" (IF-RUN) RX ! S" LOOP3 => " TYPE RX @ . CR
  RX @ 3 <> IF S" fail LOOP3 want 3" TYPE CR ABORT THEN
  S" IF-DEMO: OK (sim)" TYPE CR
  ;

IF-DEMO-CHECK
