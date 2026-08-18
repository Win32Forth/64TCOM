\ SRCDEMO.fth — samples/hello.fth via TSRC-INCLUDE + full CLI loop
\ Public domain. Loader: 64TCOMSRC/64SRC.fth. Outputs: samples/hello

TARGET-INIT
/SHOW
LL-INIT
FORTH DEFINITIONS

S" samples/hello.fth" TSRC-INCLUDE

\ Same-dir names as TCOM (beside the .fth)
S" samples/hello" MACHO-FILENAME PLACE
S" samples/hello.bin" IMAGE-FILENAME PLACE

ARM64-FINISH
FORTH DEFINITIONS

VARIABLE RX

: SRC-DEMO-CHECK  ( -- )
  S" --- SRC-DEMO (hello.fth) ---" TYPE CR
  S" MAIN" RUN-SYM RX !
  S" MAIN => " TYPE RX @ . CR
  RX @ 42 <> IF S" SRC-DEMO fail MAIN want 42" TYPE CR ABORT THEN
  [DEFINED] RUN-SYM-N [IF]
    S" MAIN" RUN-SYM-N RX !
    S" MAIN native => " TYPE RX @ . CR
    RX @ 42 <> IF S" SRC-DEMO fail MAIN native" TYPE CR ABORT THEN
  [THEN]
  [DEFINED] SAVE-MACHO-FILE [IF]
    S" --- SRC-DEMO Mach-O MAIN ---" TYPE CR
    S" MAIN" MACHO-ENTRY-SET
    S" samples/hello" MACHO-FILENAME PLACE
    SAVE-MACHO-FILE
    [DEFINED] SYSTEM [IF]
      S" ./samples/hello" SYSTEM
      S" Mach-O MAIN exit (want 42) = " TYPE DUP . CR
      42 <> IF S" SRC-DEMO fail Mach-O MAIN" TYPE CR ABORT THEN
      S" SRC-DEMO: OK (Mach-O MAIN => 42 + Hello)" TYPE CR
    [ELSE]
      S" SRC-DEMO: Mach-O written; no SYSTEM" TYPE CR
    [THEN]
  [THEN]
  S" SRC-DEMO: OK (source → sim/native/Mach-O => 42 + Hello)" TYPE CR
  ;

SRC-DEMO-CHECK
