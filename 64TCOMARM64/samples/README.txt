64TCOM ARM64 — samples/
=======================

These are *target* programs for the restricted dialect (.fth). They are not
loaded with FLOAD as host 64Forth source. Build them with **TCOM-CLI**
(Terminal / exit-status tools). GUI apps use **TCOM** — see ../window/.

What ships
----------
  Distributed:  *.fth  and this README.txt
  Not shipped:  generated binaries and intermediates next to each sample
                (name, name.c, name-build.sh, name.bin)

Requirements
------------
  - 64Forth 1.1.3+ recommended (1.0.5+ for auto-cc via SYSTEM)
  - Working folder: 64TCOMARM64/  (the parent of this samples/ folder)

Build a sample (64Forth console)
--------------------------------
  FLOAD TARGETARM64.fth

  TCOM-CLI samples/hello.fth
  TCOM-CLI samples/print.fth
  TCOM-CLI samples/args.fth
  TCOM-CLI samples/add.fth
  TCOM-CLI samples/multi.fth
  TCOM-CLI samples/err.fth
  TCOM-CLI samples/echoin.fth
  TCOM-CLI samples/fcat.fth
  TCOM-CLI samples/fwrite.fth

Paths with spaces must be quoted:

  TCOM-CLI "path with spaces/foo.fth"

TCOM-CLI always uses MAIN as the executable entry point. The output base name
is the source path without the .fth suffix, in the same directory as the source:

  samples/hello.fth  →  samples/hello  (+ .c, -build.sh, .bin)
  samples/print.fth  →  samples/print  (+ .c, -build.sh, .bin)

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
  hello.fth
    Prints "Hello, 64TCOM" and exits with status 42
    (VARIABLE, colon defs, DOUBLE, @/!, S"/TYPE)

  print.fth
    Prints "Hello, 64TCOM" and exits with status 0
    (minimal S" + TYPE demo)

  args.fth
    Prints ARG1 and ARG2 (each on a line); exits with ARGCOUNT
    User args are 1-based (program name is not ARG1).
    Shell quotes apply: ./samples/args "" foo  → empty ARG1, ARG2=foo

  add.fth
    ./samples/add 3 5 → prints 8 (uses = IF S>N + . CR)

  multi.fth + math.fth
    multi does:  FLOAD math.fth  (relative to samples/)
    ./samples/multi 7 → prints "14 49" (DOUBLE and SQUARE from math.fth)

  err.fth
    Writes a message to stderr via ETYPE; exits 1
    ./samples/err 2>/tmp/e  → /tmp/e has the message

  echoin.fth
    Reads one line from stdin (ACCEPT + LINE-BUF), echoes it
    echo hello | ./samples/echoin  →  hello
    empty stdin → "(eof)" on stderr, exit 1

  fcat.fth
    ./samples/fcat path  — cat file to stdout (OPEN-R READ CLOSE)
    exit 0 ok, 1 usage, 2 open fail

  fwrite.fth
    ./samples/fwrite path  — write a fixed line (OPEN-W WRITE CLOSE)
    exit 0 ok, 1 usage, 2 open fail

  wave.fth
    Stack/memory/execute smoke (2DROP XOR ABS C@ +! EXECUTE ['])
    TCOM-CLI samples/wave.fth  →  exit 0

  stackcmp.fth
    Stack extras + compares (PICK ROLL DEPTH WITHIN U< …)
    TCOM-CLI samples/stackcmp.fth  →  exit 0

  numeric.fth
    Pictured numeric (<# # HOLD SIGN #> .) and BASE
    TCOM-CLI samples/numeric.fth  →  exit 0

  memdbl.fth
    Memory + double (2! FILL ERASE COUNT MOVE D+ S>D)
    TCOM-CLI samples/memdbl.fth  →  exit 0

  arith.fth
    Signed / MOD /MOD */ */MOD (SM/REM, toward zero)
    TCOM-CLI samples/arith.fth  →  exit 0

  xheap.fth
    CATCH THROW ALLOCATE FREE RESIZE
    TCOM-CLI samples/xheap.fth  →  exit 0

  shiftloop.fth
    LSHIFT RSHIFT UNLOOP ?DO
    TCOM-CLI samples/shiftloop.fth  →  exit 0

  defining.fth
    CONSTANT DOES> :NONAME RECURSE IMMEDIATE [ ] LITERAL POSTPONE
    TCOM-CLI samples/defining.fth  →  exit 0

  search.fth
    VOCABULARY ALSO ONLY DEFINITIONS ' FIND
    TCOM-CLI samples/search.fth  →  exit 0

  CLI / dialect words (after pack load):
    ARGCOUNT ARG1 ARG2 ARG#
    0=  =  <  >   + - *   ROT NIP 2DUP
    EMIT CR SPACE .   TYPE   S>N  (string to signed decimal)
    CHAR c  [CHAR] c              (ASCII code of next word's first char)
    ETYPE EEMIT ECR                 (stderr)
    KEY ACCEPT LINE-BUF             (stdin)
    OPEN-R OPEN-W CLOSE READ WRITE  (files; Darwin errno → fail/-1)
    FLOAD path.fth  |  INCLUDE path.fth   (top-level; relative to this file)
    Comments:  \ to EOL   ( … )   \\ … {   or   } … {  (multi-line)

Optional demos (after FLOAD TARGETARM64.fth)
-------------------------------------------
  SRC-DEMO     rebuilds/checks hello on sim + native + Mach-O
  PRINT-DEMO   rebuilds/checks print on sim + native + Mach-O

Also available:  c-addr u TSRC-BUILD  (always names the default image
tcomarm64 in the pack folder — prefer TCOM-CLI for samples)

GUI demos live in the sibling folder ../window/ (build with TCOM).

Public domain.
