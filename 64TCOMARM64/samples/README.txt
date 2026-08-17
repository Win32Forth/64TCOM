64TCOM ARM64 — samples/
=======================

These are *target* programs for the restricted dialect (.tfth). They are not
loaded with FLOAD as host 64Forth source. Build them with the pack word TCOM.

What ships
----------
  Distributed:  *.tfth  and this README.txt
  Not shipped:  generated binaries and intermediates next to each sample
                (name, name.c, name-build.sh, name.bin)

Requirements
------------
  - 64Forth 1.1.2+ recommended (1.0.5+ for auto-cc via SYSTEM)
  - Working folder: 64TCOMARM64/  (the parent of this samples/ folder)

Build a sample (64Forth console)
--------------------------------
  FLOAD TARGETARM64.fth

  TCOM samples/hello.tfth
  TCOM samples/print.tfth
  TCOM samples/args.tfth
  TCOM samples/add.tfth

Paths with spaces must be quoted:

  TCOM "path with spaces/foo.tfth"

TCOM always uses MAIN as the executable entry point. The output base name is
the source path without the .tfth suffix, in the same directory as the source:

  samples/hello.tfth  →  samples/hello  (+ .c, -build.sh, .bin)
  samples/print.tfth  →  samples/print  (+ .c, -build.sh, .bin)

Run
---
  Terminal (from 64TCOMARM64/):

    ./samples/hello ; echo $?
    ./samples/print ; echo $?

  Or from the 64Forth console:

    S" ./samples/hello" SYSTEM .
    S" ./samples/print" SYSTEM .

What each sample does
---------------------
  hello.tfth
    Prints "Hello, 64TCOM" and exits with status 42
    (VARIABLE, colon defs, DOUBLE, @/!, S"/TYPE)

  print.tfth
    Prints "Hello, 64TCOM" and exits with status 0
    (minimal S" + TYPE demo)

  args.tfth
    Prints ARG1 and ARG2 (each on a line); exits with ARGCOUNT
    User args are 1-based (program name is not ARG1).
    Shell quotes apply: ./samples/args "" foo  → empty ARG1, ARG2=foo

  add.tfth
    ./samples/add 3 5 → prints 8 (uses = IF S>N + . CR)

  CLI / dialect words (after pack load):
    ARGCOUNT ARG1 ARG2 ARG#
    0=  =  <  >   ROT NIP 2DUP
    EMIT CR SPACE .   TYPE   S>N  (string to signed decimal)

Optional demos (after FLOAD TARGETARM64.fth)
-------------------------------------------
  SRC-DEMO     rebuilds/checks hello on sim + native + Mach-O
  PRINT-DEMO   rebuilds/checks print on sim + native + Mach-O

Also available:  c-addr u TSRC-BUILD  (always names the default image
tcomarm64 in the pack folder — prefer TCOM for samples)

Public domain.
