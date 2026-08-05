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
    FWD-ARM64

What v0.1 emits
---------------
  COMP-SINGLE n   → MOVZ/MOVK X0, #n  (4 insns)
  COMP-CALL addr  → LDR X16, [PC+8]; BLR X16; .quad addr
  END-T: / ;T     → RET
  LIB-PRIM        → ALIGN; RET  (callable stub; address = cookie)

  Forward G' uses same fixup chain as GEN: RESOLVE-1 patches the .quad.

Not yet
-------
  Full ITC outer interpreter, real DUP/DROP bodies, Mach-O save,
  complete A64 assembler, macOS ABI.

Files
-----
  TARGETARM64.fth   load chain
  ASMARM64.fth      emitters
  OPTARM64.fth      COMP-* hooks + demos
  LIBARM64.fth      library stubs
  ARM64DEMO.fth     HI demo
  FWDARM64.fth      forward demo
  TARGETARM64.txt   short notes
  README.txt        this file
