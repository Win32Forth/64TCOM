64TCOM — tetra/ (TETRA port)
============================

Source: TETRA.FTH — classic TCOM/F-PC character Tetris (Marc Hawley).

Dual-load
---------
Same tetra.fth builds a Finder .app via TCOM *and* runs interactively under
64Forth GRAPHICS (separate char window — not the console). Lines prefixed
with \ANS or \TCOM select host-specific bits (Esc quit, CASE default, MAIN).

TCOM (.app)
-----------
  FLOAD TARGETARM64.fth
  TCOM tetra/tetra.fth     \ → tetra/tetra.app (Finder)
  open tetra/tetra.app

  TCOM-CLI tetra/tetra.fth \ Terminal binary (grid stubs / stdio)

ANS / 64Forth GRAPHICS
----------------------
  Requires 64Forth with AppOutput / GRAPHICS (1.1.3+ tetra-readiness).

  S" AppOutput/app-output.fth" FROMLIB INCLUDED
  ONLY FORTH ALSO GRAPHICS
  S" /path/to/64TCOMARM64/tetra/tetra.fth" INCLUDED
  MAIN

  Esc closes the graphics window and returns to the console (does not BYE).

Screen / input
--------------
  AT CLS EMIT GET-CHAR KEY? KEY TYPE . CR SPACE
  TIME-RESET 10TH-ELAPSED TENTHS TONE
  WINDOW APP-NAME
  TONE: freq in Hz, dur in tenths of a second (F-PC)

Arrow keys map to classic F-PC codes (200/203/205/208). Char 219 → █.

Dialect also includes: CREATE ALLOT , VALUE TO DO LOOP +LOOP I J
  CMOVE CELLS CELL+ AND OR NOT 2* 2/ NEGATE MOD / 1- 1+ 2@ SPACES
  >R R> R@ CASE OF ENDOF ENDCASE BYE EXIT UPC TRUE FALSE
  ?EXIT

Controls: arrows move/rotate, Space drop, S sound, P pause, Esc quit.

Public domain sample; original game logic by Marc Hawley.
