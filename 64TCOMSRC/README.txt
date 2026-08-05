64TCOMSRC — 64TCOM director / compiler sources
==============================================
Adapted from classic TCOM core concepts for native 64Forth (8-byte cells).
Not an F-PC translation layer.

Files
-----
  64HOST.fth     Host layer: vocs, image buffers, hooks (Phase 1.1)
  64DIR.fth      Symbol table + thin director T:/L:/G' (Phase 1.2)
  README.txt     This file

Usual load
----------
  From 64TCOMGEN:  FLOAD TARGETGEN.fth
  (pulls in 64HOST + 64DIR + GEN pack)

Or piecemeal:
  INCLUDE …/64TCOMSRC/64HOST.fth
  INCLUDE …/64TCOMSRC/64DIR.fth

See 64DESIGN/STATUS.txt for project position.
See 64DESIGN/64HOST notes.txt for host word list.

Coming later
------------
  Fuller COMPILE1/2-style director; real target packs
