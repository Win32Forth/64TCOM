64TCOM ARM64 — window/
======================

GUI demos for Layer 4 (AppKit). Sibling of samples/ (CLI tools).

What ships
----------
  Distributed:  *.tfth  and this README.txt
  Not shipped:  generated binaries and intermediates
                (name, name.m, name-build.sh, name.bin)

Requirements
------------
  - 64Forth 1.1.2+ recommended (1.0.5+ for auto-cc via SYSTEM)
  - Working folder: 64TCOMARM64/  (parent of this window/ folder)
  - macOS AppKit (cc -framework AppKit)

Build (64Forth console)
-----------------------
  FLOAD TARGETARM64.fth
  TCOM-GUI window/win.tfth
  → window/win  (+ .m, -build.sh, .bin)

Run
---
  ./window/win

  A blank window titled "64TCOM" should appear and stay until you
  close it (red button) or Quit 64TCOM (menu / Cmd-Q).
  Launch from Terminal for this MVP; a Finder .app bundle comes later.
  The menu bar app name is "64TCOM" (not the binary leaf name).

Dialect
-------
  WINDOW   ( -- )  open a blank NSWindow via the GUI shell host call.
                   Only useful with TCOM-GUI (AppKit .m shell).
                   Under plain TCOM the host stub is a no-op (-1).

See also: samples/ for CLI tools (print, args, fcat, …).

Public domain.
