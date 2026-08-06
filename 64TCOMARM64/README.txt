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
  COMP-CALL taddr → LDR X16,[PC+8]; BLR X16; .quad THERE(taddr)
  ;T              → RET
  DUP# DROP# SWAP# OVER# PLUS# MINUS# FETCH# STORE# EXIT#  real bodies
  BRANCH# ZBRANCH# EXEC# LIT# still stubs (RET only)

  Forward G': RESOLVE-1 stores host address of final in .quad.

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

Native execution (Phase 3.3)
----------------------------
  Requires 64Forth 1.0.3+ kernel words:
    MPROTECT  ICACHE-INVAL  CALL-NATIVE  (ALLOCATE-EXEC optional)

  After ARM64-DEMO (image in T-CODE-BASE):

    CODE-MAKE-EXEC?   \ mprotect RWX + icache; prints status
    .RUN-ANS-N        \ CALL-NATIVE into ANS  => 5 expected

  CALL-ABS stores host addresses, so code runs in place (not a copy).
  Needs 64Forth 1.0.4+ (allow-jit entitlements). T-CODE-BASE should be MAP_JIT
  (load message: "T-CODE-BASE: MAP_JIT"). malloc + mprotect(EXEC) fails on
  Apple Silicon even with allow-unsigned-executable-memory.
  If C! crashes on MAP_JIT: rebuild so kernel_eval forces JIT write mode.

Not yet
-------
  Mach-O image, full ISA/NEON, hardened-runtime JIT entitlement (if needed).

Files
-----
  TARGETARM64.fth   load chain
  ASMARM64.fth      emitters
  OPTARM64.fth      COMP-* hooks + demos
  LIBARM64.fth      library stubs
  SIMARM64.fth      host simulator RUN-ANS
  NATARM64.fth      native RUN-ANS-N / CODE-MAKE-EXEC
  ARM64DEMO.fth     HI demo
  FWDARM64.fth      forward demo
  TARGETARM64.txt   short notes
  README.txt        this file
