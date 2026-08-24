64TCOMUTILS — Utilities for 64TCOM
==================================
Public domain.

Phase 4.0 (in progress) — debugger / listing / xref

Debugger (SIMARM64 + 64Forth editor)
------------------------------------
Loaded automatically from TARGETARM64.fth:

  TCOMDBG.fth     — BREAK WHERE STEP GO TDEBUG / TDBG  (shared UI)
  ../64TCOMARM64/DBGARM64.fth — SIMARM64 backends for DBG-* hooks

Optional editor polish (after FROMLIB Editor):

  FROMLIB FLOAD Editor/SZ-EDITOR.fth
  FLOAD ../64TCOMUTILS/TCOMDBG-ED.fth

  → highlight current word, quiet console, Files-column stacks

Monitor: ../STATUSDBG64.md

Quick smoke (console):

  CHDIR …/64TCOMARM64
  FLOAD TARGETARM64.fth
  ARM64-DEMO
  TDBG ANS
  \ space/F6 step over  F7 into  g go  q quit

Still planned: listing, xref, native BRK traps.

Classic reference: tcom25/TCOMUTIL and listing tools under various targets.
