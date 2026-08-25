64TCOMUTILS — Utilities for 64TCOM
==================================
Public domain.

Phase 4.0 (in progress) — debugger / listing / xref

Debugger (SIMARM64 + 64Forth editor)
------------------------------------
Loaded automatically from TARGETARM64.fth:

  TCOMDBG.fth     — BREAK WHERE STEP GO TDEBUG / TDBG  (shared UI)
  DBGARM64.fth    — SIMARM64 backends for DBG-* hooks
  TCOMDBG-ED.fth  — SZ-EDITOR highlight / quiet / side pane
                    (included when SZ-EDITOR is already loaded, e.g. AutoLoad;
                     skipped under agent --no-autoload)

If you ever load TARGETARM64 before the editor:

  FROMLIB FLOAD Editor/SZ-EDITOR.fth
  FLOAD ../64TCOMUTILS/TCOMDBG-ED.fth

Monitor: ../STATUSDBG64.md

Quick smoke (console):

  CHDIR …/64TCOMARM64
  FLOAD TARGETARM64.fth
  ARM64-DEMO
  TDBG ANS
  \ space/F6 step over  F7 into  g go  q quit

Index / NDX (port of classic TCOMNDX.SEQ)
-----------------------------------------
Loaded with TARGETARM64:

  TCOMNDX.fth     — /INDEX  INDEX!  NDX-SAVE-AS   (PC↔source table)
  NDXARM64.fth    — wraps COMP-CALL / END-T: like classic xCC,

After `TCOM path/foo.fth` writes `path/foo.NDX` (text index listing).
TDBG opens the **source .fth** and uses the .NDX as a map: GOTO line + highlight
token (classic TCOM index UX). The .NDX file itself is for inspection/listing.

Classic reference: tcom25 TCOMNDX.FTH (index!), TCOMUTIL/XREF.FTH (asm LST xref — different tool).

Still planned: richer .FIL paths/names, full ls86-style listing, native BRK traps.
