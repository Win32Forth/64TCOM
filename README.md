# 64TCOM

**64TCOM** is a retargetable Forth **target compiler** (TCOM lineage) being ported to run **natively on [64Forth](https://github.com/Win32Forth/64Forth)** — a 64-bit / 8-byte-cell ANS-oriented Forth for macOS Apple Silicon.

It is **not** an F-PC 16-bit translation layer. The compiler director is being redesigned and re-implemented for 64Forth’s cell size and host environment, while preserving classic TCOM’s multi-target architecture (director + pluggable target packs).

Public domain lineage: classic **TCOM** and **F-PC** by Tom Zimmer and contributors.

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
- **First target pack:** **GEN** (generic) — stub compile / log; **no assembler**, no real machine code
- **Later real targets:** **ITC hybrid** (assembly primitives + high-level Forth), with a Forth-style assembler when needed
- **Assembler syntax** (prefix vs postfix/infix): deferred until a real target pack needs it

---

## Repository layout

```text
64TCOM/
  README.md                 This overview
  64DESIGN/                 Design documents (.docx)
  64TCOMSRC/                64TCOM director / compiler sources (in progress)
  64TCOMGEN/                GEN target pack (placeholders)
  64TCOMUTILS/              Utilities later (debugger, listing, xref, …)
  REFERENCE_FILES/
    FPC36/                  Classic F-PC 3.6 sources & docs (reference)
    tcom25/                 Classic TCOM 2.5 multi-target tree (reference)
```

### GEN pack files (`64TCOMGEN/`)

| File | Role |
|------|------|
| `TARGETGEN.fth` | Load / configuration for GEN |
| `ASMGEN.fth` | Stub assembler |
| `OPTGEN.fth` | Deferred target-interface hooks |
| `LIBGEN.fth` | Stub target library |
| `TESTGEN.fth` | Sample source for GEN tests |
| `TARGETGEN.txt` | GEN pack notes |

### Design documents (`64DESIGN/`)

- *TCOM to 64Forth Port Analysis* — difficulty and architecture assessment  
- *TCOM on 64Forth Phase 0 Design* — locked decisions and phases  
- *64TCOM Naming and Layout* — product name and folder layout  

---

## Current status

| Area | Status |
|------|--------|
| Project name & tree | **Done** (`64TCOM` under Documents; this repo) |
| Phase 0 design | **In progress / largely locked** (see `64DESIGN/`) |
| Director sources (`64TCOMSRC`) | **Scaffold only** (README; implementation not started) |
| GEN pack | **Placeholders** (not loadable on 64Forth yet) |
| Utilities | **Reserved** (empty of tools) |
| Reference F-PC / TCOM | **Present** under `REFERENCE_FILES/` |
| Runnable compile on 64Forth | **Not yet** |

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

Classic **F-PC** and **TCOM** were released as **public domain** by Tom Zimmer.  
**64TCOM** continues in that spirit unless a more specific notice is added later.  
Reference trees under `REFERENCE_FILES/` retain their original historical notices where present.
