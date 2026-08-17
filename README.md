# 64TCOM

**64TCOM** is a retargetable Forth **target compiler** (TCOM lineage) being ported to run **natively on [64Forth](https://github.com/Win32Forth/64Forth)** — a 64-bit / 8-byte-cell ANS-oriented Forth for macOS Apple Silicon.

It is **not** an F-PC 16-bit translation layer. The compiler director is being redesigned and re-implemented for 64Forth’s cell size and host environment, while preserving classic TCOM’s multi-target architecture (director + pluggable target packs).

**Public domain.** 64TCOM, like classic **TCOM** and **F-PC** (Tom Zimmer and contributors), is dedicated to the public domain.

---

## What it is evolving from

| Heritage | Role |
|----------|------|
| **TCOM 2.5** | Optimizing target compiler: symbols, deferred library inclusion, HOST/COMPILER/TARGET model, pack interface (`TCOMINTF`) |
| **TCOMGEN** | Generic “tutorial” target (no real CPU) — template for new backends |
| **Other TCOM packs** | 8086, 8080 (ITC), 68HC11, 6805, 80196, SSP1600, BASIC front ends, … |
| **F-PC 3.6** | Classic host Forth that original TCOM was built on (reference only) |
| **64Forth** | New host: ARM64 ITC kernel + SwiftUI console, ANS word sets |

Classic sources used for reference are kept in this repo under **`REFERENCE_FILES/`** (not the active compiler).

---

## Design goals (locked for Phase 0)

- **Host:** 64Forth, native **64-bit cells**
- **Tutorial pack:** **GEN** (`64TCOMGEN/`) — tag stream / log; no real CPU code
- **First real pack:** **ARM64** (`64TCOMARM64/`) — AArch64 / Apple Silicon; emit, sim, native run, SAVE-IMAGE / SAVE-MACHO (Phases 3.0–3.4)
- **Assembler syntax** (prefix vs postfix): chosen with the ARM64 pack as it grows

---

## Repository layout

```text
64TCOM/
  README.md                 This overview
  64DESIGN/                 Design documents + STATUS.txt
  64TCOMSRC/                Director / host (64HOST, 64DIR)
  64TCOMGEN/                GEN tutorial pack (working demos)
  64TCOMARM64/              ARM64 real target pack (Phase 3)
  64TCOMUTILS/              Utilities later (debugger, listing, xref, …)
  REFERENCE_FILES/
    FPC36/                  Classic F-PC 3.6 sources & docs (reference)
    tcom25/                 Classic TCOM 2.5 multi-target tree (reference)
```

### GEN pack (`64TCOMGEN/`) — working

| File | Role |
|------|------|
| `TARGETGEN.fth` | Load HOST → DIR → ASM → OPT → LIB |
| `ASMGEN.fth` / `OPTGEN.fth` / `LIBGEN.fth` | Stub assembler, hooks, cookies |
| `GENDEMO.fth` / `FWDDEMO.fth` | Demos |

### ARM64 pack (`64TCOMARM64/`) — Phase 3.3–3.4 (working)

| File | Role |
|------|------|
| `TARGETARM64.fth` | Load HOST → DIR → ASM → OPT → LIB → SIM → NAT → MACHO |
| `ASMARM64.fth` | AArch64 emitters (`W,` `RET,` `CALL-ABS,` …) |
| `OPTARM64.fth` | COMP-* → real A64; `ARM64-DEMO` / `FWD-ARM64`; `SAVE-IMAGE` |
| `LIBARM64.fth` | Library prims (`DUP#` `DROP#` `+` …) with real A64 bodies |
| `SIMARM64.fth` | Software simulator; `.RUN-ANS` → 5 |
| `NATARM64.fth` | In-process native run (mmap + mprotect + `CALL-NATIVE`); `.RUN-ANS-N` → 5 |
| `MACHOARM64.fth` | `SAVE-MACHO` → `.c` + `*-build.sh` → real arm64 Mach-O via `cc` |
| `ARM64DEMO.fth` / `FWDARM64.fth` / `ASMDEMO.fth` | Demos |

```forth
FLOAD TARGETARM64.fth
ARM64-DEMO
.RUN-ANS          \ software sim => 5
.RUN-ANS-N        \ native in-process (64Forth 1.0.4+) => 5
S" ANS" MACHO-ENTRY-SET
SAVE-MACHO-FILE   \ .c + -build.sh; auto-cc via SYSTEM (64Forth 1.0.5+)
S" ./tcomarm64" SYSTEM .   \ => 5
\ /NOMACHO-BUILD  → emit sources only; manual: sh tcomarm64-build.sh
```

Requires **64Forth 1.0.4+** for native helpers (`CALL-NATIVE`, `MPROTECT`, JIT entitlements); **1.0.5+** for `SYSTEM` auto-build after `SAVE-MACHO`.

### Design documents

- **[`STATUS.md`](STATUS.md)** — living project status (start here)  
- *TCOM to 64Forth Port Analysis* — difficulty and architecture assessment (`64DESIGN/`)  
- *TCOM on 64Forth Phase 0 Design* — locked decisions and phases  
- *64TCOM Naming and Layout* — product name and folder layout  
- *Phase 3.5 ARM64 notes* — optional true BL/BLR analysis

---

## Current status

| Area | Status |
|------|--------|
| Project name & tree | **Done** |
| Director (`64TCOMSRC`) | **`64HOST` + `64DIR`** (symbols, T:/L:/G', forwards) |
| GEN pack | **Done for demos** (`GEN-DEMO`, `FWD-DEMO`) |
| ARM64 pack | **Phase 3.0–3.4 done** — sim, native, SAVE-IMAGE, SAVE-MACHO |
| Living status | **[`STATUS.md`](STATUS.md)** (project root; twin: `64DESIGN/STATUS.txt`) |
| Reference F-PC / TCOM | **`REFERENCE_FILES/`** |

### Phases (summary)

| Phase | Status | Notes |
|-------|--------|-------|
| **0** Design & layout | **Done** | Name, tree, design docs |
| **1** Host + director | **Done** | `64HOST`, `64DIR` on 64Forth |
| **2** GEN tutorial pack | **Done** | Tags / demos / forwards |
| **3.0–3.2** ARM64 emit + SAVE-IMAGE | **Done** | Prim bodies, SIM, BRANCH, `.bin` |
| **3.3** Native in-process | **Done** | `.RUN-ANS-N` => 5 (inline callees) |
| **3.4** Standalone Mach-O | **Done** | `SAVE-MACHO` → C + `cc` → executable |
| **3.5** True BL/BLR (no inline) | Optional | Not required for green ANS |
| **4.0** Utilities | Next | Listing, xref, debugger (`64TCOMUTILS`) |

---

## Host system

64TCOM is intended to be developed and run with **64Forth**:

- https://github.com/Win32Forth/64Forth  

---

## License / distribution

**64TCOM is public domain.**

You may use, copy, modify, and distribute it freely, for any purpose, with or without attribution.

Classic **F-PC** and **TCOM** were also released as public domain by Tom Zimmer and contributors.  
Reference trees under `REFERENCE_FILES/` retain their original historical notices where present.

See [PUBLIC_DOMAIN](PUBLIC_DOMAIN) for the short dedication.
