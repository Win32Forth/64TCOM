\ PRINTDEMO.fth — samples/print.tfth via TSRC (Layer 2 print)
\ Public domain. Proves TYPE# / S" on sim + native + Mach-O stdout.

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

S" samples/print.tfth" TSRC-INCLUDE

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: PRINT-DEMO-CHECK  ( -- )
  S" --- PRINT-DEMO (print.tfth) ---" TYPE CR
  S" MAIN" RUN-SYM RX !
  S" MAIN sim => " TYPE RX @ . CR
  RX @ 0 <> IF S" PRINT-DEMO fail MAIN sim want 0" TYPE CR ABORT THEN
  [DEFINED] RUN-SYM-N [IF]
    S" MAIN" RUN-SYM-N RX !
    S" MAIN native => " TYPE RX @ . CR
    RX @ 0 <> IF S" PRINT-DEMO fail MAIN native" TYPE CR ABORT THEN
  [THEN]
  [DEFINED] SAVE-MACHO-FILE [IF]
    S" --- PRINT-DEMO Mach-O MAIN ---" TYPE CR
    S" MAIN" MACHO-ENTRY-SET
    SAVE-MACHO-FILE
    [DEFINED] SYSTEM [IF]
      S" ./tcomarm64" SYSTEM
      S" Mach-O MAIN exit (want 0) = " TYPE DUP . CR
      0 <> IF S" PRINT-DEMO fail Mach-O MAIN exit" TYPE CR ABORT THEN
      S" PRINT-DEMO: OK (Mach-O MAIN => 0 + print)" TYPE CR
    [ELSE]
      S" PRINT-DEMO: Mach-O written; no SYSTEM" TYPE CR
    [THEN]
  [THEN]
  S" PRINT-DEMO: OK (source → sim/native/Mach-O print)" TYPE CR
  ;

PRINT-DEMO-CHECK
