64TCOM — tetra/ (TETRA port)
============================

Source: TETRA.FTH — classic TCOM/F-PC character Tetris (Marc Hawley).

Goal: playable Finder .app via TCOM + AppKit text grid (see project plan).

Status
------
Cleaned tetra.fth, 64-bit cells, dialect, growable TSRC buffer, and a real
AppKit **80×25 text grid** for TCOM `.app` builds.

Screen / input (GUI host slots in tcom-textgrid.inc)
----------------------------------------------------
  AT CLS EMIT GET-CHAR KEY? KEY TYPE . CR SPACE
  TIME-RESET 10TH-ELAPSED TENTHS TONE
  WINDOW APP-NAME
Nested event pump inside KEY?/KEY/TENTHS so GAME can run before [NSApp run].
Arrow keys map to classic F-PC codes (200/203/205/208). Char 219 → █.

Dialect also includes: CREATE ALLOT , VALUE TO DO LOOP +LOOP I J
  CMOVE CELLS CELL+ AND OR NOT 2* 2/ NEGATE MOD / 1- 1+ 2@ SPACES
  >R R> R@ CASE OF ENDOF ENDCASE BYE EXIT UPC TRUE FALSE
  !> OFF> ON> +!> ?EXIT

Build
-----
  FLOAD TARGETARM64.fth
  TCOM tetra/tetra.fth     \ → tetra/tetra.app (Finder)
  open tetra/tetra.app

  TCOM-CLI tetra/tetra.fth \ Terminal binary (grid stubs / stdio)

Controls: arrows move/rotate, Space drop, S sound, P pause, Esc quit.

Public domain sample; original game logic by Marc Hawley.
