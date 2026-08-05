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
- **First real pack:** **ARM64** (`64TCOMARM64/`) — AArch64 / Apple Silicon; ITC hybrid + Forth-style assembler (Phase 3)
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

### ARM64 pack (`64TCOMARM64/`) — Phase 3

| File | Role |
|------|------|
| `TARGETARM64.fth` | Load chain (planned) |
| `ASMARM64.fth` | AArch64 Forth-style assembler (planned) |
| `OPTARM64.fth` | Target interface hooks (planned) |
| `LIBARM64.fth` | ITC hybrid library (planned) |
| `README.txt` / `TARGETARM64.txt` | Naming and notes |

### Design documents (`64DESIGN/`)

- *TCOM to 64Forth Port Analysis* — difficulty and architecture assessment  
- *TCOM on 64Forth Phase 0 Design* — locked decisions and phases  
- *64TCOM Naming and Layout* — product name and folder layout  

---

## Current status

| Area | Status |
|------|--------|
| Project name & tree | **Done** |
| Director (`64TCOMSRC`) | **`64HOST` + `64DIR`** (symbols, T:/L:/G', forwards) |
| GEN pack | **Done for demos** (`GEN-DEMO`, `FWD-DEMO`) |
| ARM64 pack | **Named `64TCOMARM64`** — implement Phase 3 next |
| Living status | **`64DESIGN/STATUS.txt`** |
| Reference F-PC / TCOM | **`REFERENCE_FILES/`** |

### Planned phases (summary)

1. **Phase 0** — Design & layout (this stage)  
2. **Phase 1** — Native host support + director loads on 64Forth  
3. **Phase 2** — GEN “compiles” a sample to a log/listing  
4. **Phase 3+** — Real target packs (e.g. ARM64 ITC) and utilities  

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
