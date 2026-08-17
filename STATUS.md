# 64TCOM — Project status (living document)

**Update this file when phase boundaries move.**  
**Last updated:** 2026-08-06 (Phase 3.5 true BLR default — native + Mach-O)

> Canonical “where are we?” for the repo.  
> Older plain-text twin: [`64DESIGN/STATUS.txt`](64DESIGN/STATUS.txt) (kept in sync at high level).

---

## YOU ARE HERE

```text
  Phase 0–2        DONE
  Phase 3.0b–d     DONE   — ARM64 pack, prims, SIM, BRANCH
  Phase 3.1        DONE   — richer ASMARM64 + ASM-DEMO
  Phase 3.2        DONE   — SAVE-IMAGE → tcomarm64.bin (+ optional .map/.hdr)
  Phase 3.3        DONE   — .RUN-ANS-N => 5 (native; inline path retained)
  Phase 3.4        DONE   — SAVE-MACHO → .c + build.sh → cc → Mach-O
                           (+ auto-cc via 64Forth SYSTEM when available)
  Phase 3.5        DONE   — true BLR default: fixup .quad → base+taddr
                           (/INLINE-CALLS restores paste-leaf path)
  Phase 4.0        OPEN   — utilities (listing, xref, debugger)
  Next roadmap     B      — control flow (BRANCH/IF) for real programs
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
- [x] **3.5** True BL/BLR without callee inlining (default)  
      Native: `(NAT-FIXUP-CALLS)` — `.quad` taddr → `base+taddr`, keep BLR  
      Mach-O: C main fixup loop (same pattern) before `mprotect`  
      Fallback: `/INLINE-CALLS` (old Phase 3.3 paste leaves)  
      Detail: [`64DESIGN/Phase 3.5 ARM64 notes.txt`](64DESIGN/Phase%203.5%20ARM64%20notes.txt)
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

Native path (64Forth 1.0.4+), Phase 3.5 default true BLR:
  mmap RW code+DSP pages; fixup CALL-ABS .quad → base+taddr;
  mprotect code RX; CALL-NATIVE with X0=0 and DSP on the RW page.
  /INLINE-CALLS — paste leaf bodies (old 3.3 path).

Standalone (64Forth 1.0.5+ SYSTEM auto-build default):
  S" ANS" MACHO-ENTRY-SET  SAVE-MACHO-FILE
  \ writes .c + -build.sh; C fixups BLR sites; runs sh NAME-build.sh
  S" ./tcomarm64" SYSTEM .     \ demo expects 5
  \ or manual:  sh tcomarm64-build.sh && ./tcomarm64 ; echo $?
  \ sources only:  /NOMACHO-BUILD SAVE-MACHO-FILE
  \ old inline embed: /INLINE-CALLS SAVE-MACHO-FILE
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
| `64DESIGN/Phase 3.5 ARM64 notes.txt` | True BL/BLR (done; design + implementation notes) |
| `64DESIGN/TCOM to 64Forth Port Analysis.docx` | Difficulty / architecture |
| `64DESIGN/TCOM on 64Forth Phase 0 Design.docx` | Locked Phase 0 decisions |
| `64DESIGN/64TCOM Naming and Layout.docx` | Name + tree |
| `64DESIGN/64HOST notes.txt` | Host layer |
| `64DESIGN/GEN load notes.txt` | GEN chain |
| `64DESIGN/Library cookies explained.txt` | Cookie model |

---

## Next step

1. **Roadmap B** — real `BRANCH#`/`ZBRANCH#` + IF/THEN compile (control flow)  
2. Nested colon demo under true BLR (roadmap E)  
3. **Phase 4.0:** utilities (`64TCOMUTILS`) — after control flow works  
4. Grow assembler / library **on demand** as programs need more ISA  
5. Phase 3.5 detail (historical): [`64DESIGN/Phase 3.5 ARM64 notes.txt`](64DESIGN/Phase%203.5%20ARM64%20notes.txt)

---

# Expanded notes (beyond original STATUS.txt)

## Phases at a glance

| Phase | Status | Notes |
|-------|--------|-------|
| **0** Design & layout | **Done** | Name, tree, design docs |
| **1** Host + director | **Done** | `64HOST`, `64DIR` on 64Forth |
| **2** GEN tutorial pack | **Done** | Tags / demos / forwards |
| **3.0–3.2** ARM64 emit + SAVE-IMAGE | **Done** | Prim bodies, SIM, BRANCH, `.bin` |
| **3.3** Native in-process | **Done** | `.RUN-ANS-N` => 5 (inline path retained as fallback) |
| **3.4** Standalone Mach-O | **Done** | `SAVE-MACHO` → C + `cc`; auto-build via `SYSTEM` |
| **3.5** True BL/BLR (no inline) | **Done** | Default fixup; `/INLINE-CALLS` fallback |
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
| True BL/BLR at runtime | **Done (3.5)** — default fixup; `/INLINE-CALLS` fallback |
| BTI | Word exists but is NOP |
| Labels | Only 16 local labels; one pending forward per label |
| COMP-* surface | Many director hooks still NOP at compile site |
| Full library | Real leaves for core stack ops; many advanced prims still thin/stub |

### Maturity (one line)

**Solid Phase 3.1 working assembler for a small STC/Forth-ish ARM64 subset** — enough for demos, real stack prims, branches/labels, and the green ANS path. **Not** a general-purpose AArch64 assembler or a complete TCOM library emitter yet.

---

## Roadmap: expand for real program generation

Goal: move from **leaf demos** (ANS => 5) to code the **compiler** can generate for nested colon definitions, control flow, and real data—without finishing the entire ARM64 ISA first.

### What we already have

Enough for **leaf graphs**: stack ops, `+`/`-`, lit, `CALL-ABS` (with **inlining** for native/Mach-O), branches/labels in the **assembler**, sim + native + standalone.

A **real** program needs more than leaves: nested calls, richer control, memory/locals, strings/I/O policy, and a library the **compiler** actually uses—not only hand asm.

### Priority order (what blocks real programs)

#### 1. Call model that scales — Phase 3.5 (runtime) — **DONE**

Native and Mach-O default to true BLR (fixup `.quad` → base+taddr).  
`/INLINE-CALLS` restores the ≤5-insn paste path. Nested multi-level colon trees still need stress testing (roadmap E) and may need LR discipline for non-leaf callees.

**Detail:** [`64DESIGN/Phase 3.5 ARM64 notes.txt`](64DESIGN/Phase%203.5%20ARM64%20notes.txt)

#### 2. Control-flow library the compiler can use

**Why:** Real Forth is mostly `IF`/`THEN`, loops, exits—not `6 + 1`.

| Grow | Assembler pieces (many exist) |
|------|--------------------------------|
| Real `BRANCH#` / `ZBRANCH#` bodies | `B` / `CBZ` / `B.cond` + patch |
| `COMP-IF` / `THEN` / `ELSE` (or pack hooks) | Same as `AIF,`/`ATHEN,` but via director |
| `BEGIN`/`UNTIL`/`AGAIN`/`WHILE`/`REPEAT` | Back branches + labels |
| Later: `DO`/`LOOP` | Compare + branch; may need return-stack or index regs |

Assembler already has `B.COND`, `CBZ`, `AHEAD`/`THEN,`, `L:`/`BR>L`. Gap is **wiring them into OPT/LIB and high-level `T:`**, not inventing B.

#### 3. Memory model for real data

**Why:** Programs use variables, arrays, structs—not only the data stack.

| Need | Assembler / ABI |
|------|------------------|
| `@` `!` already in lib | Confirm/use widely from compiled code |
| `C@` `C!` `2@` `2!` or cell helpers | Narrow LDR/STR sizes |
| PC-relative / absolute data | `ADRP`+`ADD` or lit pool + LDR (**new emitters**) |
| Locals / frame (optional) | `STP`/`LDP` X29/X30, `SUB SP` — high leverage for non-leaf |

Worth adding next in the **assembler**: **`LDP`/`STP` (pre/post), `LDRB`/`STRB`, `ADRP`/`ADD` page**, more `LDR`/`STR` modes.

#### 4. Widen the library (compiler-visible), not the full ISA

Real generation uses **cookies / LIB prims**, not every encoding.

**First wave of useful prims** (after call + control work):

| Class | Examples |
|-------|----------|
| Stack | `ROT` `NIP` `TUCK` `2DUP` `2DROP` `?DUP` |
| Logic/compare | `AND` `OR` `XOR` `0=` `0<` `=` `<` (flags → TOS) |
| Multiply/div (as needed) | `MUL` then later div |
| Memory | `C@` `C!` `+!` |
| Control | `EXIT` already; real branch prims |
| Call | `EXECUTE` / `EXEC#` if not solid |

Each prim is a few emitters you mostly already have (`AND-X,`, `SUBS`, `CBNZ`, …).

#### 5. Fill COMP-* stubs that still NOP

Director hooks that no-op today mean high-level target syntax doesn’t emit real code.

Prioritize whatever the `T:` / colon path actually hits:

- lit / call / `;T` — **done**
- branch / zbranch compile — **next**
- `@` `!` at compile sites if used  
- leave exotic `COMP-ON`/`COMP-SAVE` until needed

#### 6. Only then: “assembler completeness”

Once calls + control + memory work, expand emitters **on demand**:

| Later | When needed |
|-------|-------------|
| Shifts / extends / bitfield | Masks, scaled indexing |
| `W` register forms | 32-bit ABI bits |
| Full cond select (`CSEL`) | Branchless |
| NEON / FP | Not for classic Forth core |
| Syscalls / libc | Only for “real OS program” I/O |

Avoid full-ISA tourism before steps 1–4.

### Concrete roadmap (checklist)

- [x] **A.** Phase 3.5 — true BLR (no inline) — *runtime* (default; `/INLINE-CALLS` fallback)
- [ ] **B.** Real `BRANCH#`/`ZBRANCH#` + IF/THEN compile — *lib + OPT*
- [ ] **C.** `LDP`/`STP` + `ADRP` (or lit-pool) for frames/data — *asm*
- [ ] **D.** Library wave: `ROT`, logic, compares, `C@`/`C!` — *lib*
- [ ] **E.** Nested colon demo (true BLR, multi-level calls) — *proof*
- [ ] **F.** Optional: strings / `TYPE` if host I/O model exists
- [ ] **G.** More ISA as programs demand

### Success test for “useful for real generation”

```text
T: FOO  ... nested calls, IF/THEN, @/! ... ;T
.RUN-ANS-N => expected
SAVE-MACHO-FILE  → binary behaves the same
without relying on 5-insn inlining
```

### What not to do next

- Full NEON / system register set  
- Hand-rolled perfect Mach-O (already use `cc`)  
- Phase 4 utilities (listing/xref) **before** the compiler can emit nested control  
- Polishing `ASM-DEMO` alone without compiler/library path  

### Short answer

**Next for real programs:**

1. ~~**True calls (3.5)**~~ — **done** (default true BLR)  
2. **Control flow through LIB + COMP-*** — IF/THEN/loops  
3. **Memory + frames** — ADRP/LDP/STP, more loads/stores  
4. **Library breadth** — what colon definitions actually call  
5. **Assembler opcodes only when a prim needs them**  
6. Nested colon demo under true BLR (roadmap E)

---

## Execution paths (ARM64)

| Path | Word / flow | Needs | Result (ANS demo) |
|------|-------------|-------|-------------------|
| Software sim | `.RUN-ANS` | host only | => 5 |
| In-process native | `.RUN-ANS-N` | 64Forth 1.0.4+ native helpers | => 5 (true BLR; or `/INLINE-CALLS`) |
| Standalone Mach-O | `SAVE-MACHO-FILE` | 1.0.5+ `SYSTEM` for auto-`cc` | binary; demo exit 5 (C fixup BLR) |
| Raw image | `SAVE-IMAGE-FILE` | — | `tcomarm64.bin` (+ optional map/hdr) |

---

## Host / product notes

- **64TCOM** is public domain; classic TCOM/F-PC lineage under `REFERENCE_FILES/`.
- Prefer **not** committing generated `tcomarm64*`, `*.bin`, `*-build.sh` build outputs (recreated by SAVE-*).
- When updating phases: edit **this file first**, then skim `64DESIGN/STATUS.txt` and `README.md` status table for consistency.
