# 64TCOM — Project status (living document)

**Update this file when phase boundaries move.**  
**Last updated:** 2026-08-06 (STATUS.md at project root; ARM64 assembler snapshot; SAVE-MACHO auto-build)

> Canonical “where are we?” for the repo.  
> Older plain-text twin: [`64DESIGN/STATUS.txt`](64DESIGN/STATUS.txt) (kept in sync at high level).

---

## YOU ARE HERE

```text
  Phase 0–2        DONE
  Phase 3.0b–d     DONE   — ARM64 pack, prims, SIM, BRANCH
  Phase 3.1        DONE   — richer ASMARM64 + ASM-DEMO
  Phase 3.2        DONE   — SAVE-IMAGE → tcomarm64.bin (+ optional .map/.hdr)
  Phase 3.3        DONE   — .RUN-ANS-N => 5 (native; inline callees in copy)
  Phase 3.4        DONE   — SAVE-MACHO → .c + build.sh → cc → Mach-O
                           (+ auto-cc via 64Forth SYSTEM when available)
  Phase 3.5        OPEN   — optional true BL/BLR without inlining
  Phase 4.0        OPEN   — utilities (listing, xref, debugger)
```

**Host baseline:** [64Forth](https://github.com/Win32Forth/64Forth) **1.1.1+**  
(Native path needs **1.0.4+**; `SYSTEM` auto-build needs **1.0.5+**.)

---

## Coding style (host/director/GEN)

Prefer ANS locals over `>R` `R@` `R>` (return stack collides with `DO`/`I`).

64Forth form that works reliably in this codebase:

```forth
: test {: bingo bongo | bango :} bingo bongo + TO bango  bango ;
\ or the user's output-local form without | temps:
: test {: bingo bongo -- bango :} bingo bongo + TO bango ;
```

Output locals are returned automatically — do not push them before `;` :

```forth
: SYM-FIND-IX  {: ca u -- ix :}
  ca u SYM-FIND IF TO ix ELSE DROP … THEN
  ;   \ ix is left on the stack by the locals mechanism
```

- Temps: `{: in | temp :}` (not auto-returned).
- Avoid: `{: in | temp -- out :}` (mix failed: `"undefined: out"` on 64Forth).
- Loop scratch: `VARIABLE`s (`SYM-I` …) when outs are also needed.

---

## Phase checklist

- [x] **0.1** Product name 64TCOM, tree under Documents/64TCOM
- [x] **0.2** Design docs in `64DESIGN/`
- [x] **0.3** Public domain + GitHub Win32Forth/64TCOM
- [x] **1.1** `64HOST.fth` — HOST/COMPILER/TARGET, target mem, DEFER hooks, `U>=`
- [x] **1.1b** Quiet `TCOM-ANEW`; GEN load chain; GEN tags; cookies
- [x] **1.2** Symbol table + `64DIR` director (name → type/addr/uses)
- [x] **1.3** Forward refs + resolve chains + options surface
- [x] **2.0** GEN pack loadable (`ASMGEN` `OPTGEN` `LIBGEN` `TARGETGEN`)
- [x] **2.1** `LIB-PRIM` registers into SYM table; `T:` records symbols; `G'` looks up
- [x] **2.2** Forward references + richer resolve (same as 1.3 on GEN)
- [x] **3.0a** Pack name + tree: `64TCOMARM64/`
- [x] **3.0b** `TARGETARM64` + `ASMARM64` + `OPTARM64` + `LIBARM64` + demos (v0.1)
- [x] **3.0c** Real prim bodies (`DUP` `DROP` `SWAP` `OVER` `+` `-` `@` `!`); LIT push; host CALL quads
- [x] **3.0d** `SIMARM64` `RUN-ANS`; `BRANCH#`/`ZBRANCH#`; `SYM-CLEAR-APP` on `TARGET-INIT`
- [x] **3.1** Richer `ASMARM64` (regs, logic, B.cond, labels, AIF); `ASM-DEMO`
- [x] **3.2** `SAVE-IMAGE-FILE` / `SAVE-IMAGE-AS` / optional `.map` and 32-byte hdr
- [x] **3.3** Native ANS: `FLOAD TARGETARM64`; `ARM64-DEMO`; `.RUN-ANS`; `.RUN-ANS-N` => 5
- [x] **3.4** `SAVE-MACHO-FILE` → `NAME.c` + `NAME-build.sh` → `cc` → arm64 Mach-O  
      (default: auto-run build via `SYSTEM` on 64Forth 1.0.5+; `/NOMACHO-BUILD` = sources only)
- [ ] **3.5** Optional: true in-process BL/BLR without callee inlining  
      → see [`64DESIGN/Phase 3.5 ARM64 notes.txt`](64DESIGN/Phase%203.5%20ARM64%20notes.txt)
- [ ] **4.0** Utilities (listing, xref, debugger) in `64TCOMUTILS`

---

## What works today

### GEN (tutorial pack)

```text
FLOAD TARGETGEN.fth   (from 64TCOMGEN)
.GEN  .DIR  .SYMBOLS  .UNRES  .OPTIONS
GEN-DEMO  FWD-DEMO  FLOAD TESTGEN.fth
64HOST-SMOKE  SYM-SMOKE  (case-insensitive find + FWD count)
G' unknown-name → SYM-FORWARD + fixup chain; T: name resolves chain
Unresolved FWD at GEN-FINISH aborts (unless /NOFWDABORT)
Library cookies: DUP# … as SYM-LIBRARY
No >R/R> in live 64TCOM source (locals only)
```

### ARM64 pack

```text
FLOAD TARGETARM64.fth  (from 64TCOMARM64)
ARM64-DEMO  .RUN-ANS  .RUN-ANS-N   \ both => 5

Native path (64Forth 1.0.4+):
  mmap RW code+DSP pages, mprotect code RX,
  inline CALL-ABS callees into the copy (BLR into leaves was unreliable),
  CALL-NATIVE with X0=0 and DSP on the RW page.

Standalone (64Forth 1.0.5+ SYSTEM auto-build default):
  S" ANS" MACHO-ENTRY-SET  SAVE-MACHO-FILE
  \ writes .c + -build.sh, runs sh NAME-build.sh
  S" ./tcomarm64" SYSTEM .     \ demo expects 5
  \ or manual:  sh tcomarm64-build.sh && ./tcomarm64 ; echo $?
  \ sources only:  /NOMACHO-BUILD SAVE-MACHO-FILE
```

**Note:** Exit status **5** is the ANS demo contract (X0 after the sample), not a product UI. Real programs would define their own entry/runtime/exit policy; auto-run via `SYSTEM` is for smoke tests.

---

## Key source files

| Path | Role |
|------|------|
| `64TCOMSRC/64HOST.fth` | Host layer + options |
| `64TCOMSRC/64DIR.fth` | Symbol table + director (Phase 1.3) |
| `64TCOMGEN/` | GEN pack (tutorial tags) — done for demos |
| `64TCOMARM64/` | ARM64 real target pack — `FLOAD TARGETARM64.fth` |
| `REFERENCE_FILES/` | Classic F-PC 3.6 + TCOM 2.5 |

### ARM64 pack files

| File | Role |
|------|------|
| `TARGETARM64.fth` | Load chain |
| `ASMARM64.fth` | Forth-style A64 emitters (~Phase 3.1) |
| `OPTARM64.fth` | `COMP-*` hooks, demos, SAVE-IMAGE |
| `LIBARM64.fth` | Library prims with real A64 bodies |
| `SIMARM64.fth` | Software sim — `.RUN-ANS` |
| `NATARM64.fth` | Native run — `.RUN-ANS-N` (inline calls) |
| `MACHOARM64.fth` | `SAVE-MACHO` → C + build.sh → Mach-O |
| `ARM64DEMO.fth` / `FWDARM64.fth` / `ASMDEMO.fth` | Demos |

---

## Design docs (background)

| Doc | Notes |
|-----|--------|
| **`STATUS.md`** (this file) | Start here for “where are we?” |
| `64DESIGN/STATUS.txt` | Plain-text twin / historical living list |
| `64DESIGN/Phase 1.3 notes.txt` | Director / forwards |
| `64DESIGN/Phase 3 ARM64 notes.txt` | ARM64 pack goals |
| `64DESIGN/Phase 3.5 ARM64 notes.txt` | True BL/BLR (optional; detailed analysis) |
| `64DESIGN/TCOM to 64Forth Port Analysis.docx` | Difficulty / architecture |
| `64DESIGN/TCOM on 64Forth Phase 0 Design.docx` | Locked Phase 0 decisions |
| `64DESIGN/64TCOM Naming and Layout.docx` | Name + tree |
| `64DESIGN/64HOST notes.txt` | Host layer |
| `64DESIGN/GEN load notes.txt` | GEN chain |
| `64DESIGN/Library cookies explained.txt` | Cookie model |

---

## Next step

1. **Optional 3.5:** true in-process BL/BLR without inlining  
   → [`64DESIGN/Phase 3.5 ARM64 notes.txt`](64DESIGN/Phase%203.5%20ARM64%20notes.txt)
2. **Phase 4.0:** utilities (`64TCOMUTILS`)
3. Grow assembler / library as real target programs need more ISA

---

# Expanded notes (beyond original STATUS.txt)

## Phases at a glance

| Phase | Status | Notes |
|-------|--------|-------|
| **0** Design & layout | **Done** | Name, tree, design docs |
| **1** Host + director | **Done** | `64HOST`, `64DIR` on 64Forth |
| **2** GEN tutorial pack | **Done** | Tags / demos / forwards |
| **3.0–3.2** ARM64 emit + SAVE-IMAGE | **Done** | Prim bodies, SIM, BRANCH, `.bin` |
| **3.3** Native in-process | **Done** | `.RUN-ANS-N` => 5 (inline callees) |
| **3.4** Standalone Mach-O | **Done** | `SAVE-MACHO` → C + `cc`; auto-build via `SYSTEM` |
| **3.5** True BL/BLR (no inline) | **Optional / open** | Not required for green ANS |
| **4.0** Utilities | **Open** | Listing, xref, debugger |

---

## ARM64 assembler status (`ASMARM64.fth`)

**Phase 3.1 is done** — a working **Forth-style subset** of AArch64 aimed at the 64TCOM stack ABI, **not** a full CPU assembler.

| Item | Status |
|------|--------|
| File | `64TCOMARM64/ASMARM64.fth` (~386 lines) |
| Phase | **3.1 complete** |
| Style | Forth emitters (`W,`, `ADD-X-X,`, …) into target CODE |
| Vocabulary | `ASMARM64` via `SETASSEM` / `END-CODE` |

### ABI

| Register | Role |
|----------|------|
| **X0** | TOS |
| **X19** | DSP (push `STR X0,[X19,#-8]!`) |
| **X16** | Call temp (`CALL-ABS`) |
| **X30** | LR |
| Cell | 8 bytes |

### What it can emit today

**Plumbing:** `W,` (LE 32-bit), `ALIGN4-T`, `PATCH-W`, `W@-T`; regs **X0–X30**, **XZR**, **SP**.

**Control / call:**

- `NOP,` `BTI,` (currently NOP) `RET,` `RET-X,` `BLR-X,` `BR-X,`
- `B-IMM,` `BL-IMM,` `B.COND,` + cond codes EQ…AL
- `CBZ-X,` `CBNZ-X,`
- `CALL-ABS,` / `JMP-ABS,` — LDR X16 + BLR/BR + B+3 + `.quad` taddr
- Structured: `AHEAD` `THEN,` `AGAIN,` `AIF,` `AELSE,` `ATHEN,`
- Labels **L0–L15**: `L:` `BR>L` (one forward site each)

**Data / ALU (64-bit X):**

- `MOVZ-X,` `MOVK-X,` `MOV-X-IMM64,` `MOV-X-X,`
- `AND-X,` `ORR-X,` `EOR-X,`
- `ADD-X-X,` `SUB-X-X,` `ADDS-X,` `SUBS-X,` `CMP-X,`
- `ADD-IMM,` `SUB-IMM,` (12-bit imm)

**Memory:**

- `STR-PRE,` `LDR-POST,` (stack-style DSP)
- `LDR-X0,` `STR-X0,` / `LDR-OFF,` `STR-OFF,`
- PC-rel: `LDR64-PC+8,` `LDR64-PC+12,` `LDR64-LIT,`

**Forth ABI helpers:** `LIT-PUSH-X0,` `LIT-X0,` `DSP-INIT,`

### Proven by demos

- **`ASM-DEMO`** — leaf add, AHEAD/THEN skip, unrolled adds (via SIM)
- **Library leaves** (`DUP#` `DROP#` `+` …) built from these emitters
- **Full path:** sim / native / SAVE-MACHO for ANS => 5

### How the assembler is used

1. **Hand asm** — `SETASSEM` … emitters … `END-CODE` / `ASM-DEMO`
2. **Compiler hooks** (`OPTARM64`) — `COMP-SINGLE` → lit push; `COMP-CALL` → `CALL-ABS,`; `;T` → `RET,`
3. **Library** (`LIBARM64`) — real bodies for core stack/math; some `COMP-*` still **NOP stubs**

The assembler is the **instruction toolkit**; the high-level target compiler only uses a thin slice so far.

### Gaps (not yet)

| Missing / thin | Notes |
|----------------|--------|
| Full A64 ISA | No first-class W-regs suite, most shifts/extends, ADRP/ADR, … |
| NEON / FP / SVE | Explicit non-goal so far |
| System / barriers / atomics | Not present |
| Rich addressing | No full (reg,reg,extend), full LDP/STP suite, … |
| True BL/BLR at runtime | Encoded; native/Mach-O still **inline** callees (Phase **3.5**) |
| BTI | Word exists but is NOP |
| Labels | Only 16 local labels; one pending forward per label |
| COMP-* surface | Many director hooks still NOP at compile site |
| Full library | Real leaves for core stack ops; many advanced prims still thin/stub |

### Maturity (one line)

**Solid Phase 3.1 working assembler for a small STC/Forth-ish ARM64 subset** — enough for demos, real stack prims, branches/labels, and the green ANS path. **Not** a general-purpose AArch64 assembler or a complete TCOM library emitter yet.

### Natural growth paths

1. Widen emitters as library words need them (LDP/STP, more LDR modes, MUL, shifts).
2. **Phase 3.5** — keep encodings; fix **runtime** so BLR is not inlined away.
3. Fill `COMP-*` / control-flow library so high-level TARGET colon code uses more of the assembler without hand asm.

---

## Execution paths (ARM64)

| Path | Word / flow | Needs | Result (ANS demo) |
|------|-------------|-------|-------------------|
| Software sim | `.RUN-ANS` | host only | => 5 |
| In-process native | `.RUN-ANS-N` | 64Forth 1.0.4+ native helpers | => 5 (calls inlined in copy) |
| Standalone Mach-O | `SAVE-MACHO-FILE` | 1.0.5+ `SYSTEM` for auto-`cc` | binary; demo exit 5 |
| Raw image | `SAVE-IMAGE-FILE` | — | `tcomarm64.bin` (+ optional map/hdr) |

---

## Host / product notes

- **64TCOM** is public domain; classic TCOM/F-PC lineage under `REFERENCE_FILES/`.
- Prefer **not** committing generated `tcomarm64*`, `*.bin`, `*-build.sh` build outputs (recreated by SAVE-*).
- When updating phases: edit **this file first**, then skim `64DESIGN/STATUS.txt` and `README.md` status table for consistency.
