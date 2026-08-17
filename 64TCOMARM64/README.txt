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

What v0.3 emits (and 3.0c foundations)
----------------------
  COMP-SINGLE n   → push TOS; MOV X0,#n
  COMP-CALL taddr → LDR X16; BLR; B+3; .quad taddr (offset; native adds base)
  ;T              → RET
  DUP# DROP# SWAP# OVER# PLUS# MINUS# FETCH# STORE# EXIT#  real bodies
  BRANCH#/ZBRANCH# relocatable (ADR base); EXEC#/LIT# still stubs

  Forward G': RESOLVE-1 stores final taddr in .quad at site.

Assembler 3.1+ (grows with the compiler — not a full ISA)
---------------------------------------------------------
  Registers X0–X30, AND/ORR/EOR, ADDS/SUBS/CMP, ADD/SUB #imm
  LDR/STR scaled, B/BL/B.cond, CBZ/CBNZ
  Labels: LL:  BR>LL  (0..15; not L: — that is 64DIR library)
  Control: AHEAD THEN, AIF, AELSE, ATHEN,
  Forth-ABI: TIF TELSE TTHEN  TBEGIN TUNTIL  (TOS flag in X0)
  CALL-ABS: STP LR; LDR; BLR; LDP LR; B+3; .quad  (Phase 3.5)
  Demo: ASM-DEMO  IF-DEMO  (sim)
  Policy: add emitters when LIB/OPT/demos need them, not full A64 first.

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

Native execution (Phase 3.3 / 3.5) — in 64Forth
----------------------------------------------
  Requires 64Forth 1.0.4+ (MPROTECT ICACHE-INVAL CALL-NATIVE ALLOCATE-EXEC).

  ARM64-DEMO
  .RUN-ANS      \ simulator => 5
  .RUN-ANS-N    \ native in-process => 5
                \ Phase 3.5 default: true BLR
                \   (fixup CALL-ABS .quad: taddr → base+taddr)
                \ /INLINE-CALLS  — old paste-leaf path (Phase 3.3)

Standalone Mach-O (Phase 3.4 / 3.5)
-----------------------------------
  After compile (e.g. ARM64-DEMO). CHDIR to 64TCOMARM64 (or write path) first:

    S" ANS" MACHO-ENTRY-SET   \ or MACHO-ENTRY-COLD
    SAVE-MACHO-FILE           \ writes .c + -build.sh; auto-cc if SYSTEM
    \ or:  /MACHO  before finish to auto-emit
    \ or:  S" myprog" SAVE-MACHO-AS
    \ or:  /NOMACHO-BUILD SAVE-MACHO-FILE   \ sources only
    \ or:  /INLINE-CALLS SAVE-MACHO-FILE    \ embed inlined leaves

  64Forth 1.0.5+ (SYSTEM): SAVE-MACHO runs  sh NAME-build.sh  for you and
  reports "MACHO: built ./NAME (cc exit 0)". Then:

    S" ./tcomarm64" SYSTEM .     \ expect 5 for ANS
    \ or in Terminal:  ./tcomarm64 ; echo exit:$?

  Without SYSTEM (older host) or with /NOMACHO-BUILD:

    sh tcomarm64-build.sh
    ./tcomarm64 ; echo exit:$?

  The .c embeds the A64 image. Phase 3.5 default: CALL-ABS kept as BLR;
  C main relocates each .quad (offset → buf+offset) before mprotect, then
  sys_icache_invalidate. /INLINE-CALLS pastes leaves into the image instead.
  Apple's cc produces a normal arm64 Mach-O.

Not yet
-------
  Full ISA/NEON; nested multi-level library calls stress-tested;
  PC-relative BL imm (optional optimization).

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
