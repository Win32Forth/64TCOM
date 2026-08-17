\ runtest.fth — ARM64 pack smoke (Phase 3.0–3.5)
\ Public domain.
\
\ From 64TCOMARM64/ in 64Forth:
\   FLOAD runtest.fth
\
\ Expect: sim / native true-BLR / Mach-O all report ANS => 5
\ FILE-ECHO ON so each line is shown if something aborts.
\
\ Note: TARGETARM64 turns FILE-ECHO OFF while loading the pack; we
\ turn it back ON so the remaining test steps still echo.

FILE-ECHO ON

S" === 64TCOMARM64 runtest start ===" TYPE CR

FLOAD TARGETARM64.fth

FILE-ECHO ON

S" --- .ARM64 ---" TYPE CR
.ARM64

S" --- ARM64-DEMO ---" TYPE CR
ARM64-DEMO

S" --- .RUN-ANS (sim) ---" TYPE CR
.RUN-ANS

S" --- .RUN-ANS-N (native true BLR) ---" TYPE CR
.RUN-ANS-N

S" --- IF-DEMO (TIF/TELSE/TTHEN sim) ---" TYPE CR
IF-DEMO

S" --- NEST-DEMO (nested colon true BLR) ---" TYPE CR
NEST-DEMO

S" --- VAR-DEMO (VARIABLE + @/!) ---" TYPE CR
VAR-DEMO

S" --- SRC-DEMO (TSRC-INCLUDE hello.tfth) ---" TYPE CR
SRC-DEMO

S" --- PRINT-DEMO (Layer 2 S-quote + TYPE) ---" TYPE CR
PRINT-DEMO

\ Re-run ANS path after demos (TARGET-INIT cleared app)
S" --- ARM64-DEMO again + native after nest ---" TYPE CR
ARM64-DEMO
.RUN-ANS
.RUN-ANS-N

S" --- SAVE-MACHO-FILE ---" TYPE CR
S" ANS" MACHO-ENTRY-SET
SAVE-MACHO-FILE

S" --- standalone ./tcomarm64 ---" TYPE CR
S" ./tcomarm64" SYSTEM
S" standalone exit (want 5) = " TYPE . CR

S" === 64TCOMARM64 runtest done ===" TYPE CR

FILE-ECHO OFF
