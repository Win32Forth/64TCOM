\ print.fth — sample target program (S" + TYPE)
\
\ How to build (from 64Forth, working folder = 64TCOMARM64/):
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/print.fth
\
\ That writes next to this file:
\   samples/print          (standalone arm64 executable)
\   samples/print.c
\   samples/print-build.sh
\   samples/print.bin
\
\ Run:
\   ./samples/print        (Terminal)  or  S" ./samples/print" SYSTEM .
\ Expect: stdout "Hello, 64TCOM" and process exit status 0
\
\ Only the .fth sources ship in a distribution; rebuild generated files with TCOM-CLI.
\
\ See samples/README.txt for more detail.

: MAIN
  S" Hello, 64TCOM
"
  TYPE
  0
;
