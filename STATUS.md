# 64TCOM — Project status (living document)

**Update this file when phase boundaries move.**  
**Last updated:** 2026-08-17 (how to re-run demos; VAR/NEST/IF green; agent 1.1.2)

> Canonical “where are we?” for the repo.  
> Older plain-text twin: [`64DESIGN/STATUS.txt`](64DESIGN/STATUS.txt) (kept in sync at high level).

---

## Product destination

**Goal:** The ARM64 target of TCOM should compile **fairly complicated Forth programs** into **complete standalone executable apps**.

| Stage | What | Status |
|-------|------|--------|
| **Now** | Codegen foundation: calls, control demos, lib leaves, sim / native / Mach-O | **Layer 0** — largely done |
| **Next** | Compile a **Forth source file** into a complete image + entry | **Layer 1** — not yet |
| **Then** | Useful **CLI** tools (args, print, exit code) in Terminal | **Layer 2** — thin (ANS exit 5 only) |
| **Later** | Real I/O, files, strings, runtime services | **Layer 3** |
| **Eventually** | Finder double-clickable apps with their own window(s), like 64Forth | **Layer 4** |

```text
  Layer 4  Finder double-click + own windows  (64Forth-class app)
  Layer 3  Real I/O, files, strings, runtime services
  Layer 2  CLI Mach-O that does something useful (args, print, exit code)
  Layer 1  Compile a Forth source file into a complete image + entry
  Layer 0  Codegen foundation (calls, control, lib, sim/native/Mach-O)  ← you are here
```

**Product story** (not “finish the ARM64 ISA”):

> Host 64Forth runs 64TCOM → reads target source → emits ARM64 image → `SAVE-MACHO` → terminal binary.

Eventually that binary *is* the app (or is linked into one), with a small C/runtime shell only where the OS forces it (Mach-O, windowing, etc.).

Debugging capability comes at some point (listing, symbol map, SIM step, crash PC→name). **First need:** compile a Forth source file end-to-end. GUI/Finder apps come last.

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
  Phase 4.0        OPEN   — utilities (listing, xref, debugger) — after source compile
  Roadmap B        mostly done — TIF/TELSE/TTHEN, TBEGIN/TUNTIL,
                           IF-DEMO sim+native (IFT…LOOP3), reloc BRANCH#/ZBRANCH#
  Product path     OPEN   — source file → image → CLI → (later) GUI apps
  Host automation  DONE   — 64Forth **1.1.2** agent channel (validated on Applications install)
  Roadmap E        DONE   — NEST-DEMO nested colon + IF, sim + native true BLR
  Roadmap C/D partial — TVARIABLE + FETCH#/STORE# (VAR-DEMO sim+native)
```

**Host baseline:** [64Forth](https://github.com/Win32Forth/64Forth) **1.1.2** (agent channel shipped; ANS/Hayes + agent green on install).  
(Native path needs **1.0.4+**; `SYSTEM` auto-build needs **1.0.5+**.)  
Release: https://github.com/Win32Forth/64Forth/releases/tag/v1.1.2  

---

## Host automation (64Forth agent channel)

64TCOM demos and regressions are driven **from** 64Forth. The GUI does not expose a reliable stdin REPL for AI/CI. A **headless agent channel** was added on the 64Forth side so tools (Grok, scripts) can load files and capture console output.

| Item | Detail |
|------|--------|
| **Where** | 64Forth repo: `XCodeProjects/64Forth/` (not inside 64TCOM) |
| **Docs** | `64Forth/Resources/Docs/Agent-channel.md`, `tools/64forth-agent`, 64Forth README |
| **Activate** | `…/64Forth.app/Contents/MacOS/64Forth --agent …` or `FORTH64_AGENT=1` |
| **Wrapper** | `64Forth/tools/64forth-agent` (resolves app binary, passes `--agent`) |
| **Capture** | All kernel EMIT → **stdout**; optional `-o transcript.txt` |
| **Invoke** | Bundle **binary** path — not `open -a` (need a real stdout pipe) |

**Status:** **Shipped in 64Forth 1.1.2** (GitHub release + `/Applications` install validated: agent eval, ANS-VALIDATE 383/0, Hayes all-zero).

**Grok / workspace:** Work on 64TCOM and 64Forth can stay in one session (workspace under `Documents` or either project). No need to restart the agent from the 64Forth folder — paths are absolute. Rebuild the **app** when agent sources change; restarting Grok does not install the new binary.

**Not the same as:** typing into a live GUI window (Accessibility), or a future socket into a running session. Agent mode is a **separate headless process**.

---

## How to re-run 64TCOM demos (agent channel)

Requires **64Forth 1.1.2+** installed (e.g. `/Applications/64Forth.app`). Working directory for pack loads: `64TCOMARM64/`.

```bash
cd ~/Documents/64TCOM/64TCOMARM64
FORTH=/Applications/64Forth.app/Contents/MacOS/64Forth
```

### One-shot demos

Each of these does its own `TARGET-INIT` (they do not share one image — that is fine).

```bash
# Nested colon calls (Roadmap E) — sim + native true BLR
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'NEST-DEMO' \
  -o /tmp/nest.txt

# VARIABLE + @ / ! (data cells)
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'VAR-DEMO' \
  -o /tmp/var.txt

# IF / LOOP (sim + native subset)
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'IF-DEMO' \
  -o /tmp/if.txt
```

### All three in one agent process

```bash
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'NEST-DEMO' \
  -e 'VAR-DEMO' \
  -e 'IF-DEMO' \
  -o /tmp/64tcom-demos.txt
```

### Full pack smoke (heavier)

```bash
$FORTH --agent -c "$(pwd)" -f runtest.fth -o /tmp/runtest.txt
```

Loads the pack and runs ARM64-DEMO, ANS sim/native, IF-DEMO, NEST-DEMO, VAR-DEMO, SAVE-MACHO, standalone, etc.

### Interactive GUI (optional)

In 64Forth (after `CHDIR` / `cd` to `64TCOMARM64/`):

```forth
FLOAD TARGETARM64.fth
NEST-DEMO
VAR-DEMO
IF-DEMO
\ or:  ARM64-DEMO  .RUN-ANS  .RUN-ANS-N
```

### Success markers

| Demo | Word | Expect in transcript |
|------|------|----------------------|
| **NEST-DEMO** | `OUTER` | `=> 7` |
| | `GO` | `=> 12` |
| | `NIF` | `=> 5` |
| | `FWDN` | `=> 8738` ($2222) |
| | | `NEST-DEMO: OK (sim)` and `NEST-DEMO: OK (native true BLR)` |
| **VAR-DEMO** | `VGET` | `=> 0` |
| | `VSET` | `=> 42` |
| | `VINC` | `=> 43` |
| | `VSWP` | `=> 100` |
| | | `VAR-DEMO: OK (sim)` and `VAR-DEMO: OK (native)` |
| **IF-DEMO** | `IFT`…`LOOP3` | `LOOP3 => 3`, etc. |
| | | `IF-DEMO: OK (sim)` and `IF-DEMO: OK (native)` (IFT/IFF/LOOP3) |

Quick check:

```bash
grep -E 'OK|fail|ABORT|undefined' /tmp/nest.txt /tmp/var.txt /tmp/if.txt
```

### Demo inventory (what each proves)

| Word / file | Proves |
|-------------|--------|
| `NEST-DEMO` / `NESTDEMO.fth` | Multi-level `G'` → `CALL-ABS` / true BLR; forward call; IF + nested calls |
| `VAR-DEMO` / `VARDEMO.fth` | `TVARIABLE`, `SYM-DATA`, `G'`, `G@`/`G!`, `FETCH#`/`STORE#`, data in `T-DATA` |
| `IF-DEMO` / `IFDEMO.fth` | `TIF`/`TELSE`/`TTHEN`, `T0=,`, `TBEGIN`/`TUNTIL`, `TLOOP-TO-3,`, native subset |
| `ARM64-DEMO` | Lit + `PLUS#` → ANS => 5 (sim/native/Mach-O) |
| `runtest.fth` | End-to-end pack smoke including demos above |

### Target VARIABLE usage pattern

```forth
TVARIABLE X
T: BUMP
  G' X G@  1 G,  ' PLUS# LIB,  G' X G!
  G' X G@
;T
```

- **`TVARIABLE name`** — one cell in target data; symbol type `SYM-DATA` (host address of cell).  
- **`G' name`** — for DATA: push host addr (`COMP-SINGLE`), not a call.  
- **`G@` / `G!`** — compile `FETCH#` / `STORE#`.  
- In-process **sim and native** use absolute host `T-DATA` pointers (same process). **Standalone Mach-O** still needs data embed (open item 2b).

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

### Capability matrix (honest)

| Capability | Status |
|------------|--------|
| Target image, symbols, `T:` / `G,` / lib prims | Working |
| True BLR, nested colon calls | **Done** — `NEST-DEMO` sim+native (OUTER/GO/NIF/FWDN) |
| IF / BEGIN–UNTIL / loops | **Done** — `IF-DEMO` sim+native (IFT…LOOP3); Mach-O IF optional |
| Sim + in-process native run | Working |
| Standalone CLI Mach-O via `cc` | Working for tiny entry words (e.g. ANS → exit 5) |
| **Parse a `.fth` and compile colon defs automatically** | **Not yet** — demos are still hand-assembled `T:` scripts |
| Target `TVARIABLE` + `@`/`!` | **Done** in-process — `VAR-DEMO`; Mach-O data embed later |
| Strings, I/O, argc/argv, GUI apps | Not yet |
| **Host agent: headless load + transcript** | **Done** — 64Forth 1.1.2 `/Applications` |

### Reload / restart (host 64Forth session)

| Situation | Action |
|-----------|--------|
| Changed `ASMARM64` / `SIMARM64` / pack load order | `FLOAD TARGETARM64.fth` then demo (`IFDEMO.fth`, …) — no full Forth restart |
| Only changed a demo source and pack is current | `FLOAD` that demo alone is enough |
| `dictionary full` / FORGET errors / redefine mess after many partial loads | **Restart 64Forth**, then full pack load |
| Unsure if host matches disk | Prefer full pack reload: `FLOAD TARGETARM64.fth` |
| Agent channel sources changed in 64Forth | **Rebuild 64Forth.app** in Xcode (not just FLOAD / not restart Grok) |
| Want automated transcript without GUI | Use `--agent` (after rebuild); GUI instance can stay open separately |

`TCOM-ANEW` is reload-safe. Reloading only one pack file out of order (e.g. ASM alone) forgets SIM and everything defined after it.

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
| `ARM64DEMO.fth` / `FWDARM64.fth` / `ASMDEMO.fth` | ANS/lit demos; forward refs; asm leaves |
| `IFDEMO.fth` | Control-flow smoke (sim+native subset) |
| `NESTDEMO.fth` | Nested `G'` / true BLR + IF + forward call |
| `VARDEMO.fth` | `TVARIABLE` + `G@`/`G!` data cells |
| `runtest.fth` | Full pack smoke (agent: `-f runtest.fth`) |

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

**Strategic priority:** shortest path to “I can compile a Forth source file” (Layer 1), then useful CLI (Layer 2). GUI is last.

| Step | Deliverable | Gate |
|------|-------------|------|
| 1 | Nested colon + IF/loop **via compiled words**, sim+native (+Mach-O later) | **Done sim+native** — `NEST-DEMO`; Mach-O entry optional B4 |
| 2 | `VARIABLE` + `@`/`!` + data area (in-process host ptrs) | **Done** — `TVARIABLE` / `VAR-DEMO`; Mach-O embed later |
| 3 | Target subset parser: `: … ;` `IF`… numbers, word calls | One `.tfth` (or similar) file |
| 4 | `MAIN` + `SAVE-MACHO` exit code / `write` | `./prog ; echo $?` |
| 5 | Second, messier source (two files, deeper control) | Still green on three runners |
| 6 | I/O and strings | Useful CLI tools |
| 7 | App bundle + windows | 64Forth-class apps |

Immediate engineering queue:

0. ~~**Host agent**~~ — **done** (64Forth 1.1.2)  
1. ~~**Roadmap E nested colon**~~ — **done** (`NEST-DEMO` sim+native)  
2. ~~**VARIABLE + @/!**~~ — **done** (`TVARIABLE`, `G@`/`G!`, `VAR-DEMO` sim+native)  
2b. **B4** — optional Mach-O entry for IF/VAR demos; data embed for standalone  
3. **Source loader** (step 3 — Layer 1)  
4. Library wave (compares, `ROT`, …) as demos need  
5. Grow assembler / library **on demand**  
6. **Phase 4.0** utilities — *after* source compile  

## Assembler completeness policy

The ARM64 assembler is **not** a finished full A64 ISA and is **not** completed up front.
It is a **growing toolkit** driven by the compiler and demos:

| Layer | Role |
|-------|------|
| **ASMARM64** | Emitters for instructions the pack needs *now* |
| **LIB / OPT / T:** | Use those emitters; reveal the next gap |
| **Add insn** | Only when a prim, control form, or demo needs it |

Examples: Phase 3.5 added STP/LDP around BLR; control flow added `PATCH-CBZ` and
`TIF`/`TELSE`/`TTHEN`. NEON and exotic addressing stay out until something real
requires them.

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
| **Control demos** | **Sim green** | `IF-DEMO` IFT…LOOP3; native/Mach-O still thin |
| **Source→CLI→app** | **Open** | Layers 1–4 (see Product destination) |
| **4.0** Utilities | **Open** | Listing, xref, debugger — after source compile |

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
- Labels **L0–L15**: `LL:` `BR>LL` (not `L:` — that is 64DIR library define)

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
- **`IF-DEMO` (sim):** IFT/IFF/IFN/IFZ, ZEQ/ZNE, ONCE, PUSHPOP, ADD3, **LOOP3 => 3**
  - LOOP3 machine: `MOV#0` + `ADD-IMM` + `MOV` + `SUB-IMM` + `CBNZ` back (`B5FFFFA1`)

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

**Solid Phase 3.1+ working assembler for a small STC/Forth-ish ARM64 subset** — enough for demos (incl. IF/LOOP on sim), real stack prims, branches/labels, true BLR, and the green ANS path. **Not** a general-purpose AArch64 assembler, a complete TCOM library emitter, or a Forth source compiler yet.

---

## Roadmap: expand for real program generation

Goal: move from **leaf demos** (ANS => 5) to code the **compiler** can generate for nested colon definitions, control flow, and real data—without finishing the entire ARM64 ISA first—then **source file → standalone CLI**, and eventually **Finder apps**.

### Critical path: compile a Forth source file (Layer 1)

Aim for a **restricted but real** dialect first, not full ANS. Example shape:

```forth
\ hello.tfth  — target source (name TBD)
VARIABLE X
: DOUBLE  ( n -- 2n )  DUP + ;
: MAIN    ( -- )  21 DOUBLE  X !  X @  ;
```

**Success criteria for the first “real compiler” milestone:**

1. `FLOAD TARGETARM64.fth`
2. Something like `S" hello.tfth" TCOM-COMPILE` (or `INCLUDE` under a target compile mode)
3. Sim and native: `MAIN` leaves expected result
4. `SAVE-MACHO-FILE` → `./hello` exits with that value (or prints it)

That proves the whole toolchain without GUI, files, or a full kernel.

### Design choice: target source language (lock early)

| Option | Notes |
|--------|--------|
| **1. Restricted Forth** (recommended) | Classic colon syntax, small wordset, clear “not supported” errors |
| **2. TCOM-only syntax forever** | `T:` `G,` `TIF`… — faster for demos, not “compile a Forth source file” |
| **3. Full ANS later** | Superset after (1) works |

Public story: **(1)**. Keep `TIF` / `G,` / emitters as the **internal IR** the compiler emits.

### Work packages (P1–P6)

#### P1 — Compiler surface (highest leverage)

Wire control and calls so **colon text** drives emission, not only `TIF`/`G,` by hand:

- High-level `IF` `ELSE` `THEN` `BEGIN` `UNTIL` `AGAIN` `WHILE` `REPEAT` → existing emitters
- Word lookup → `CALL-ABS` / lib cookies for non-immediates
- Nested colon trees (roadmap E) under true BLR
- `VARIABLE` / `CREATE` / `@` `!` with a simple data segment
- **Target source loader** (`TCOM-INCLUDE` / compile mode): supported subset only; clear errors otherwise

Until P1 exists, every “program” stays a hand-written demo file.

#### P2 — Library breadth (only what source needs)

Grow LIB as the first real sources demand it:

- Stack: `ROT` `NIP` `2DUP` `2DROP` …
- Compare/logic: `0=` `=` `<` `AND` `OR` …
- Memory: `C@` `C!` `+!`
- Later: multiply, `EXECUTE`, etc.

Assembler grows **on demand** (ADR/ADRP, more LDR/STR, frames)—same “grow with demos” rule.

#### P3 — Standalone CLI runtime

Mach-O is not just “code blob + exit(X0)”:

- Documented entry: `MAIN` or `COLD` → return code or `TYPE`-style write
- Minimal syscalls or libc: `write`, `exit`, later `open`/`read`
- Optional argc/argv onto the data stack
- One golden program: e.g. factorial / string length / “add numbers from args”

Still no Finder app—just a real terminal tool.

#### P4 — “Fairly complicated” Forth

Stress the compiler, not the OS:

- Multi-file target sources
- Deeper nesting, recursion (LR/stack discipline)
- Locals or a simple return-stack model if DO/LOOP is wanted
- Larger lib (strings, pictured numeric output)
- Keep **sim + native + Mach-O** as three gates for every milestone

#### P5 — Debuggability (after P1, not before)

Listing, symbol map, “show code for word,” single-step in SIM, crash PC → name. Phase 4 utilities matter once there is real code to inspect; they should **not** block the first source compile.

#### P6 — Double-clickable GUI apps (last)

This is a **product runtime**, not more codegen:

- App bundle / `Info.plist` / icon
- Event loop + window(s) (reuse 64Forth patterns: Cocoa/AppKit or whatever 64Forth uses)
- Hosted vs freestanding: link a small UI runtime with the image, or compile Forth that *calls* a fixed UI prim library
- Same image model as CLI; only the outer shell and I/O prims change

Do **not** design windowing into the compiler until CLI source→binary is boringly reliable.

### What we already have

Enough for **leaf graphs**: stack ops, `+`/`-`, lit, `CALL-ABS` (true BLR default; `/INLINE-CALLS` fallback), branches/labels in the **assembler**, control demos (`IF-DEMO` sim incl. `LOOP3`), sim + native + standalone.

A **real** program needs more than leaves: nested calls, richer control **through the compiler**, memory/locals, strings/I/O policy, a library the **compiler** actually uses—not only hand asm—and eventually a **source loader**.

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

**Codegen foundation (Layer 0):**

- [x] **A.** Phase 3.5 — true BLR (no inline) — *runtime* (default; `/INLINE-CALLS` fallback)
- [x] **B.** IF/THEN via `TIF`/`TELSE`/`TTHEN`; loops via `TBEGIN`/`TUNTIL` / `TLOOP-TO-3,`
  - [x] B2. `IF-DEMO`: IF cases + `LOOP3` on **sim** (IFT…LOOP3 => OK; `ADD-IMM`/`SUB-IMM` in SIM fixed)
  - [ ] B2b. Same on **native** + Mach-O entry (`runtest` / SAVE-MACHO)
  - [x] B3. `BRANCH#`/`ZBRANCH#` relocatable via ADR−taddr base (no host bake-in)
  - [ ] B4. Optional: Mach-O entry for IFT; WHILE/REPEAT; high-level IF sugar
- [ ] **C.** `LDP`/`STP` + `ADRP` (or lit-pool) for frames/data — *asm*
- [ ] **D.** Library wave: `ROT`, logic, compares, `C@`/`C!` — *lib*
- [ ] **E.** Nested colon demo (true BLR, multi-level calls) — *proof*
- [ ] **F.** Optional: strings / `TYPE` if host I/O model exists
- [ ] **G.** More ISA as programs demand

**Source → CLI → app (Layers 1–4):**

- [ ] **P1** Compiler surface: high-level IF/loops, calls, `VARIABLE`, target source loader
- [ ] **P2** Library breadth driven by first real sources
- [ ] **P3** Standalone CLI runtime (`MAIN`/`COLD`, write/exit, optional argc/argv)
- [ ] **P4** Fairly complicated multi-file Forth (stress compiler; three runners)
- [ ] **P5** Debuggability (listing, map, SIM step) — after P1
- [ ] **P6** Finder double-click + windows (app bundle + UI prims) — last

### Success tests

**Codegen (Layer 0):**

```text
T: FOO  ... nested calls, IF/THEN, @/! ... ;T
.RUN-ANS-N => expected
SAVE-MACHO-FILE  → binary behaves the same
without relying on 5-insn inlining
```

**Source compile (Layer 1):**

```text
FLOAD TARGETARM64.fth
S" hello.tfth" TCOM-COMPILE   \ or equivalent
MAIN  (sim + native) => expected
SAVE-MACHO-FILE → ./hello behaves the same
```

**CLI useful (Layer 2):** same, plus print/args/exit policy that a Terminal user cares about.

**GUI (Layer 4):** double-clickable bundle with its own window(s); same image model as CLI.

### What not to prioritize yet

- Full NEON / system register set  
- Full ANS Forth compatibility on day one  
- Hand-rolled perfect Mach-O (already use `cc`)  
- Phase 4 utilities (listing/xref) **before** the compiler can emit nested control / source  
- Interactive debugger inside the standalone app (before source→CLI works)  
- Finder/GUI shells (before CLI source→binary is reliable)  
- Polishing `ASM-DEMO` alone without compiler/library/source path  

### Short answer

**Next for real programs / apps:**

1. ~~**True calls (3.5)**~~ — **done** (default true BLR)  
2. ~~**Control demos (IF-DEMO sim)**~~ — **done** (incl. `LOOP3`)  
3. **Control flow through LIB + COMP-*** + nested colon (E) — still open  
4. **Memory + frames** — ADRP/LDP/STP, more loads/stores  
5. **Library breadth** — what colon definitions actually call  
6. **Source loader (P1)** — restricted Forth `.tfth` → image  
7. **CLI runtime (P3)** — `MAIN` + write/exit  
8. **Assembler opcodes only when a prim needs them**  
9. **GUI (P6)** only after CLI source→binary is boring  

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
