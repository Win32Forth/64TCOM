64TCOMARM64 — ARM64 / AArch64 real target pack for 64TCOM
=========================================================
Public domain.

Name
----
  64TCOMARM64   product-relative pack directory (like 64TCOMGEN).
  Load file:    TARGETARM64.fth   (planned; Phase 3)

  “ARM64” / AArch64 covers Apple Silicon (M1/M2/…) and other A64 hosts.
  We do not brand the pack “M1” only — same ISA family.

Role vs GEN
-----------
  64TCOMGEN/     Tutorial / log target (tag stream, cookies). Always available.
  64TCOMARM64/   First *real* machine target: emit AArch64, ITC hybrid runtime.

  Shared director:  ../64TCOMSRC/  (64HOST, 64DIR)

Planned files (Phase 3 — not all present yet)
---------------------------------------------
  TARGETARM64.fth   Load chain (HOST → DIR → ASM → OPT → LIB)
  TARGETARM64.txt   Pack notes (this tree’s design notes)
  ASMARM64.fth      Forth-style AArch64 assembler (minimal → growing)
  OPTARM64.fth      COMP-* / END-* / RESOLVE-1 for ARM64
  LIBARM64.fth      Target library / primitives (ITC hybrid)
  TESTARM64.fth     Sample application source
  README.txt        This file

Load (when implemented)
-----------------------
  CHDIR to 64TCOMARM64, then:

    FLOAD TARGETARM64.fth

  Same pattern as:

    FLOAD TARGETGEN.fth    \ from 64TCOMGEN

Phase 3 first milestone (scope lock)
------------------------------------
  • Minimal AArch64 byte emitters (LE) into T-CODE-BASE
  • Enough mnemonics for enter/exit, call, ret, literal materialization,
    a few data moves — not full ISA / NEON
  • ITC hybrid: high-level colon bodies + assembly primitives
  • Tiny demo analogous to GEN-DEMO / FWD-DEMO
  • Disassemble or hex-dump image for verification

  Later: richer assembler, image save (Mach-O or raw bin), more library.

Status
------
  Scaffold / naming only until Phase 3 implementation begins.
  See 64DESIGN/STATUS.txt and 64DESIGN/Phase 3 ARM64 notes.txt
