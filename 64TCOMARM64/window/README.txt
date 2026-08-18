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
  TCOM window/win.tfth
  → window/win           (Terminal binary)
  → window/win.app       (Finder double-clickable bundle)
  → window/win.m, -build.sh, .bin

Run
---
  Terminal:   ./window/win
  Finder:     double-click window/win.app
              or:  open window/win.app

  A blank window should appear (sample uses APP-NAME "Demo") and stay
  until you close it (red button) or Quit <name> (menu / Cmd-Q).

  Bundle folder name follows the output leaf (win.app). The menu-bar
  title still comes from APP-NAME at runtime (e.g. "Demo").

Dialect
-------
  APP-NAME ( c-addr u -- )  set menu-bar app name and default window title.
                   Call before WINDOW. Default if omitted: "64TCOM".
  WINDOW   ( -- )  open a blank NSWindow via the GUI shell host call.
                   Only useful with TCOM (AppKit .m + .app).
                   Under TCOM-CLI the host stub is a no-op (-1).

Example
-------
  : MAIN  S" MyApp" APP-NAME  WINDOW  0 ;

See also: samples/ for CLI tools (print, args, fcat, …).

Public domain.
