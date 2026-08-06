64TCOMARM64 — ARM64 / AArch64 real target pack for 64TCOM
=========================================================
Public domain.

Name
----
  64TCOMARM64     pack directory
  TARGETARM64.fth load entry
  ASMARM64 / OPTARM64 / LIBARM64

Host: 64Forth on Apple Silicon (AArch64). GEN remains the tutorial pack.

Load
----
  CHDIR to 64TCOMARM64, then:

    FLOAD TARGETARM64.fth

  Then:

    .ARM64
    ARM64-DEMO
    .RUN-ANS      \ simulator
    .RUN-ANS-N    \ native BLR (64Forth 1.0.3+: MPROTECT + CALL-NATIVE)
    FWD-ARM64

ABI (3.0c)
----------
  X0  = TOS
  X19 = DSP (push STR X0,[X19,#-8]!)
  Cell = 8 bytes. Cold sets X19 to top of data image, X0 = 0.

What v0.2 / 3.0c emits
----------------------
  COMP-SINGLE n   → push TOS; MOV X0,#n
  COMP-CALL taddr → LDR X16; BLR; B+3; .quad taddr (offset; native adds base)
  ;T              → RET
  DUP# DROP# SWAP# OVER# PLUS# MINUS# FETCH# STORE# EXIT#  real bodies
  BRANCH# ZBRANCH# EXEC# LIT# still stubs (RET only)

  Forward G': RESOLVE-1 stores final taddr in .quad at site.

Assembler 3.1
-------------
  Registers X0–X30, AND/ORR/EOR, ADDS/SUBS/CMP, ADD/SUB #imm
  LDR/STR scaled, B/BL/B.cond, CBZ/CBNZ
  Labels: L:  BR>L  (0..15)
  Control: AHEAD THEN, AIF, AELSE, ATHEN,
  Demo: ASM-DEMO  (leaf 7 and count-to-3 loop via sim)

Image save
----------
  After compile (ARM64-FINISH), SAVE-IMAGE writes:

    tcomarm64.bin   — raw CODE bytes [0, HERE-T)  (default)
    tcomarm64.map   — if /MAP : text map with COLD, LIB-END, symbols

  Options:
    /SAVE / NOSAVE     enable/disable auto-save on finish (default save on)
    /MAP  / /NOMAP     also write .map (default off)
    /HDR  / /NOHDR     prepend 32-byte header "64TCOMA" + sizes (default off)
    SAVE-IMAGE-FILE    force write now
    S" my.bin" SAVE-IMAGE-AS

  Inspect raw A64 (no header):
    llvm-objdump -D -b binary -m aarch64 tcomarm64.bin
    # or:  hexdump -C tcomarm64.bin | head

Native execution (Phase 3.3) — in 64Forth
-----------------------------------------
  Requires 64Forth 1.0.4+ (MPROTECT ICACHE-INVAL CALL-NATIVE ALLOCATE-EXEC).

  ARM64-DEMO
  .RUN-ANS      \ simulator => 5
  .RUN-ANS-N    \ native in-process => 5
                \ (mmap code+DSP pages; inline CALL sites in the copy)

Standalone Mach-O (Phase 3.4)
-----------------------------
  After compile (e.g. ARM64-DEMO):

    S" ANS" MACHO-ENTRY-SET   \ or MACHO-ENTRY-COLD
    SAVE-MACHO-FILE           \ writes tcomarm64.c + tcomarm64-build.sh
    \ or:  /MACHO  before finish to auto-emit
    \ or:  S" myprog" SAVE-MACHO-AS

  Then in Terminal (same cwd):

    sh tcomarm64-build.sh
    ./tcomarm64 ; echo exit:$?     \ expect 5 for ANS

  The .c embeds the A64 image (CALL sites inlined, same as .RUN-ANS-N) and a
  small driver that mmap/mprotect/calls entry, returning X0 as exit status.
  Apple's cc produces a normal arm64 Mach-O (hand-rolled headers rejected by
  modern codesign strict validation).

Not yet
-------
  Full ISA/NEON; true BL/BLR without inlining (host and/or standalone).

Files
-----
  TARGETARM64.fth   load chain
  ASMARM64.fth      emitters
  OPTARM64.fth      COMP-* hooks + demos
  LIBARM64.fth      library stubs
  SIMARM64.fth      host simulator RUN-ANS
  NATARM64.fth      native RUN-ANS-N
  MACHOARM64.fth    SAVE-MACHO → .c + build.sh → Mach-O
  ARM64DEMO.fth     HI demo
  FWDARM64.fth      forward demo
  TARGETARM64.txt   short notes
  README.txt        this file
