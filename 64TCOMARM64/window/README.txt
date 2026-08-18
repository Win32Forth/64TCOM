64TCOM ARM64 — window/
======================

GUI demos for Layer 4 (AppKit). Sibling of samples/ (CLI tools).

What ships
----------
  Distributed:  *.tfth, optional *.png (1024×1024 app icons), and this README.txt
  Not shipped:  generated binaries and intermediates
                (name, name.m, name-build.sh, name.bin, name.app/)

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

Icon
----
  For the .app to show a custom Finder icon, put a **1024×1024 PNG** in the
  **same folder as the .tfth source**, with the **same leaf name**:

    window/win.tfth
    window/win.png          ← required for an icon (1024×1024 pixels)

  Then run TCOM (rebuild). The build converts the PNG to an .icns inside
  the .app (Contents/Resources) and sets CFBundleIconFile.
  Without that PNG, the app still builds; Finder shows the default icon.

  Tip: Finder may cache icons — reopen the folder or relaunch Finder if
  the new icon does not appear immediately. Ship the .png with sources;
  .icns / .iconset are generated and not kept beside the source.

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
