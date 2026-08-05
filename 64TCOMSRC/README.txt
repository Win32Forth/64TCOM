64TCOMSRC — 64TCOM director / compiler sources
==============================================
Adapted from classic TCOM core concepts for native 64Forth (8-byte cells).
Not an F-PC translation layer.

Files
-----
  64HOST.fth     Host layer: vocabularies, errors, target image buffers,
                 deferred memory ops and pack hooks (Phase 1)
  README.txt     This file

Load 64HOST on 64Forth
----------------------
  INCLUDE <path-to>/64TCOMSRC/64HOST.fth
  .64HOST
  64HOST-SMOKE

See 64DESIGN/64HOST notes.txt for the word list summary.

Coming later
------------
  head2 / compile1 / compile2 / host exports / tcomndx (director pieces)
