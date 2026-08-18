64TCOM ARM64 — samples/
=======================

These are *target* programs for the restricted dialect (.tfth). They are not
loaded with FLOAD as host 64Forth source. Build them with **TCOM-CLI**
(Terminal / exit-status tools). GUI apps use **TCOM** — see ../window/.

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

  TCOM-CLI samples/hello.tfth
  TCOM-CLI samples/print.tfth
  TCOM-CLI samples/args.tfth
  TCOM-CLI samples/add.tfth
  TCOM-CLI samples/multi.tfth
  TCOM-CLI samples/err.tfth
  TCOM-CLI samples/echoin.tfth
  TCOM-CLI samples/fcat.tfth
  TCOM-CLI samples/fwrite.tfth

Paths with spaces must be quoted:

  TCOM-CLI "path with spaces/foo.tfth"

TCOM-CLI always uses MAIN as the executable entry point. The output base name
is the source path without the .tfth suffix, in the same directory as the source:

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

  multi.tfth + math.tfth
    multi does:  FLOAD math.tfth  (relative to samples/)
    ./samples/multi 7 → prints "14 49" (DOUBLE and SQUARE from math.tfth)

  err.tfth
    Writes a message to stderr via ETYPE; exits 1
    ./samples/err 2>/tmp/e  → /tmp/e has the message

  echoin.tfth
    Reads one line from stdin (ACCEPT + LINE-BUF), echoes it
    echo hello | ./samples/echoin  →  hello
    empty stdin → "(eof)" on stderr, exit 1

  fcat.tfth
    ./samples/fcat path  — cat file to stdout (OPEN-R READ CLOSE)
    exit 0 ok, 1 usage, 2 open fail

  fwrite.tfth
    ./samples/fwrite path  — write a fixed line (OPEN-W WRITE CLOSE)
    exit 0 ok, 1 usage, 2 open fail

  CLI / dialect words (after pack load):
    ARGCOUNT ARG1 ARG2 ARG#
    0=  =  <  >   + - *   ROT NIP 2DUP
    EMIT CR SPACE .   TYPE   S>N  (string to signed decimal)
    ETYPE EEMIT ECR                 (stderr)
    KEY ACCEPT LINE-BUF             (stdin)
    OPEN-R OPEN-W CLOSE READ WRITE  (files; Darwin errno → fail/-1)
    FLOAD path.tfth  |  INCLUDE path.tfth   (top-level; relative to this file)

Optional demos (after FLOAD TARGETARM64.fth)
-------------------------------------------
  SRC-DEMO     rebuilds/checks hello on sim + native + Mach-O
  PRINT-DEMO   rebuilds/checks print on sim + native + Mach-O

Also available:  c-addr u TSRC-BUILD  (always names the default image
tcomarm64 in the pack folder — prefer TCOM-CLI for samples)

GUI demos live in the sibling folder ../window/ (build with TCOM).

Public domain.
