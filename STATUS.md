# 64TCOM — Project status (living document)

**Update this file when phase boundaries move.**  
**Last updated:** 2026-08-18 — **Version 0.5**: tetra `\ANS` dual-load; real TONE; ANS-compatible CASE
> Canonical “where are we?” for the repo.  
> Older plain-text twin: [`64DESIGN/STATUS.txt`](64DESIGN/STATUS.txt) (kept in sync at high level).

---

## Product destination

**Goal:** The ARM64 target of TCOM should compile **fairly complicated Forth programs** into **complete standalone executable apps**.

| Stage | What | Status |
|-------|------|--------|
| **Layer 0** | Codegen foundation: calls, control demos, lib leaves, sim / native / Mach-O | **Done** |
| **Layer 1** | Compile a **Forth source file** into a complete image + entry + standalone | **Done** (restricted dialect; `hello.fth` MAIN=>42 all paths) |
| **Layer 2** | Useful **CLI** tools (args, print, exit, I/O) in Terminal | **Done** — print + args + stderr/stdin/files |
| **Later** | More dialect, strings, runtime services (env/sockets deferred) | **Layer 3** |
| **Layer 4** | Own window(s); Finder `.app` | **In progress** — 80×25 text grid + `TETRA` `.app` |

```text
  Layer 4  Text grid + TETRA.app (playable polish + dual-load next)   ← you are here
  Layer 3  More dialect / services (env·sockets not planned yet)
  Layer 2  CLI: print + args + I/O DONE
  Layer 1  Compile a Forth source file into a complete image     DONE
  Layer 0  Codegen foundation (calls, control, lib, sim/native/Mach-O)   DONE
```

**Product story** (not “finish the ARM64 ISA”):

> Host 64Forth runs 64TCOM → reads target source → emits ARM64 image → `SAVE-MACHO` → terminal binary / `.app`.

**Proven today:**

```text
FLOAD TARGETARM64.fth
SRC-DEMO     \ hello.fth MAIN => 42 (sim + native + Mach-O)
PRINT-DEMO   \ print.fth writes "Hello, 64TCOM\n", MAIN exit 0
```

Or one-shot:

```text
S" samples/hello.fth" TSRC-BUILD   \ image + SAVE-MACHO entry MAIN → ./tcomarm64
S" ./tcomarm64" SYSTEM .            \ exit status 42

\ Preferred console form (output next to source, strip .fth):
TCOM window/win.fth                \ → window/win + window/win.app (GUI, primary)
TCOM-CLI samples/print.fth         \ → samples/print  (CLI / Terminal)
TCOM "path with spaces/foo.fth"    \ → GUI build; quote paths with spaces
```

### Source extension: `.fth` again (not `.fth`)

Target samples use **`.fth`** again (classic TCOM/F-PC style). Dual-load will use `\ANS` / `\TCOM` line directives (like classic `\FPC` / `\TCOM`), not a separate extension, to distinguish interactive 64Forth load from TCOM compile. Host pack sources remain `.fth` as well; context (TCOM vs `FLOAD`) decides the loader.

---

## YOU ARE HERE

```text
  Pack version     0.5    — 64TCOM ARM64 (TVERSION in OPTARM64)
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
  Roadmap B        DONE   — TIF/TELSE/TTHEN, TBEGIN/TUNTIL/TAGAIN/TWHILE/TREPEAT,
                           IF-DEMO sim+native+Mach-O LOOP3, BRANCH#/ZBRANCH#
  Roadmap E        DONE   — NEST-DEMO nested colon + IF, sim + native true BLR
  Roadmap C/D      DONE   — TVARIABLE + FETCH#/STORE#; SYM-DATA = daddr;
                           COMP-DATA-ADDR + DATA-RELOC; Mach-O tcom_data[] + MOV fixup
  Host automation  DONE   — 64Forth **1.1.2+** agent channel; **1.1.3** GRAPHICS window
  Layer 1          DONE   — TSRC-INCLUDE + TSRC-BUILD + SRC-DEMO:
                           samples/hello.fth → MAIN => 42 (sim + native + Mach-O)
  Layer 2 print    DONE   — TYPE# (Darwin write SVC); dialect S" / TYPE / ."
                           samples/print.fth → "Hello, 64TCOM\n" + exit 0 (all paths)
  Console build    DONE   — `TCOM` (GUI) / `TCOM-CLI` (Terminal) → same-dir leaf (MAIN)
  Layer 2 args     DONE   — ARGCOUNT ARG1 ARG2 ARG# (1-based user argv; Mach-O fill)
  Dialect grow     DONE   — 0= = < > * ROT NIP 2DUP EMIT CR SPACE . S>N; samples/add
  Multi-file       DONE   — FLOAD/INCLUDE in .fth (nested); samples/multi + math.fth
  Layer 2 I/O      DONE   — stderr ETYPE/EEMIT/ECR; stdin KEY/ACCEPT/LINE-BUF;
                           files OPEN-R/W CLOSE READ WRITE (Darwin SVC + CS)
                           samples: err, echoin, fcat, fwrite
  Control hygiene  DONE   — TIF/TELSE + TWHILE/TREPEAT use TCS (host stack safe)
  Layer 4 window   DONE   — host-call grid: AT/CLS/EMIT/GET-CHAR/KEY?/KEY/timers/TYPE
                           `tcom-textgrid.inc` 80×25 NSView; event pump during MAIN
                           `TCOM` → `.app`; `TCOM-CLI` → Terminal; icon from `name.png`
                           demos: `window/win.fth`, `tetra/tetra.fth` → `tetra.app`
  Bugfix         DONE   — SWAP/OVER/ROT/2DUP used LDR-X0 with a stray offset (X0↔X19)
  Product path     OPEN   — TETRA playability polish; more dialect on demand
```
**Pack version history**

| Version | Notes |
|---------|--------|
| **0.1** | First ARM64 pack: prims, SIM, native, SAVE-MACHO, true BLR, IF demos |
| **0.2** | NEST/VAR; Roadmap B complete; `TSRC-INCLUDE` + Mach-O data page; Layer 1 `hello.fth` MAIN=>42; Layer 2 print (`TYPE#`, `S"`); console build → same-dir executable; `samples/` + README |
| **0.3** | Layer 2 I/O; Layer 4 text grid + window demo; TCOM=GUI / TCOM-CLI=Terminal |
| **0.4** | TETRA playable `.app`; real AppKit 80×25 grid; `\ANS`/`\TCOM` DIRECTIVE; growable TSRC; `.fth` again; DSP/HOST-CALL fixes; `>R`/`R>`/`R@` |
| **0.5** | tetra `\ANS` dual-load; real `TONE` (Hz/tenths); DIRECTIVE skips current line only; host 64Forth 1.1.4 |

**Host baseline:** [64Forth](https://github.com/Win32Forth/64Forth) **1.1.4** (GRAPHICS + tetra `\ANS` + real TONE).  
(Native path needs **1.0.4+**; `SYSTEM` auto-build needs **1.0.5+**.)  

---

## Future / potential work (architecture & dual-load)

Tracked here so it is not lost; not blocking current TETRA/grid polish.

### Dual-load: `\ANS` / `\TCOM` (near-term)

Classic F-PC/TCOM used `DIRECTIVE` so one application source could load under F-PC *and* compile under TCOM (`\FPC` / `\TCOM` in `REFERENCE_FILES/FPC36/fpcsrc/UTILS.FTH`). For 64TCOM:

| Environment | `\ANS` | `\TCOM` |
|-------------|--------|---------|
| 64Forth interactive | **true** (rest of line loads) | **false** (rest of line commented) |
| TCOM compile | **false** | **true** |

Same `.fth` sample (`tetra/tetra.fth`) **does** `INCLUDED` under 64Forth GRAPHICS and `TCOM` for `.app`. Host GRAPHICS + `TONE` ready; `\ANS`/`\TCOM` gates in tetra (Esc / MAIN). **CASE is ANS-compatible** (`ENDCASE` drops the selector). DIRECTIVE from AppOutput (ANS) or 64HOST+TARGETARM64 flip (TCOM).

### 64Forth app output window — **not** the console (near-term / design locked)

**Do not** bend the 64Forth console into TCOM character graphics. The console stays the REPL/debug surface (compile log, `.S`, `SEE`, agent, future debug features).

Add a **separate graphics / app-output layer** (own window(s)):

| Surface | Role |
|---------|------|
| **Console** | Host Forth, TCOM log, debugging — unchanged |
| **Char-graphics window** | Fixed text grid (`AT` / `CLS` / `EMIT` / `GET-CHAR` / `KEY?`) for TETRA-class apps under `\ANS` |
| **Pixel-graphics window** (later) | Framebuffer / draw ops |

**Implementation preference:** implement as much as possible **in Forth**, with **limited Swift helpers in `forth.s` / host bridge only as needed** (window create, blit, event pump). Ideally share the same buffer/API model as TCOM’s AppKit text grid (`tcom-textgrid.inc`) so `\ANS` and `\TCOM` skins stay aligned.

Input focus: keys go to the graphics window when it is frontmost; console keeps its own KEY when focused.

**Started 2026-08-18 (64Forth):**
- Swift: `Host/AppOutputHost.swift` — NSWindow + grid view, blit, key queue  
- Kernel: `(APP-OPEN)` `(APP-CLOSE)` `(APP-BLIT)` `(APP-KEY?)` `(APP-KEY)` in `forth.s`  
- Forth: `Resources/Library/AppOutput/app-output.fth` — `GRAPHICS` with full TETRA-class set + coalesced EMIT + real `TONE` (Hz / tenths)
- **`tetra/tetra.fth` dual-load:** `\ANS` under 64Forth GRAPHICS; `\TCOM` for `.app` (Esc / MAIN). See `tetra/README.txt`.
- **CASE OF ENDOF ENDCASE:** ANS-compatible in TSRC (`ENDCASE` emits `DROP#`); do not put a default-arm `DROP` before `ENDCASE`.
- Console / Facility unchanged. Agent: open returns error (no window).

### Sound

`TONE` is real on both hosts now: **freq = Hz**, **dur = tenths of a second** (F-PC). 64Forth and TCOM GUI play a sine WAV (fallback beep). Richer polyphony / samples still future base-system work.

### Retargetability: vocabularies vs string dispatch (later)

Classic TCOM made a new CPU pack comparatively easy: set up **vocabularies** (`HOST`, `TARGET`, `HTARGET`, `COMPILER`, …), compile adjusted definitions of the *same* names into those vocabularies, and let search order decide meaning.

Current 64TCOM keeps packs (`ASM*` / `OPT*` / `LIB*` / `MACHO*`) and `DEFER`/`IS` for `COMP-*`, but **TSRC name resolution** is a shared tokenizer with long `2DUP S" name" TSRC-EQ` chains in `64SRC.fth`. That works, but retargeting is **not as easy** as classic TCOM: adding dialect words or mapping source spellings often means editing the shared dispatcher, not only filling a target vocabulary.

**Potential future alignment:** shrink or replace the string-dispatch table with vocabulary-based name resolution so a new CPU pack is mostly “new vocab contents + `COMP-*` implementations,” closer to the original design. Deferred `COMP-*` is already pointed the right way; the gap is name resolution.

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

# IF / LOOP (sim + native + Mach-O LOOP3)
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'IF-DEMO' \
  -o /tmp/if.txt

# Layer 1: .fth source → sim + native + Mach-O MAIN => 42
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'SRC-DEMO' \
  -o /tmp/src.txt

# Layer 2 print: S" + TYPE → stdout
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'PRINT-DEMO' \
  -o /tmp/print.txt
# Expect: Hello, 64TCOM  and  PRINT-DEMO: OK
```

### All demos in one agent process

```bash
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'NEST-DEMO' \
  -e 'VAR-DEMO' \
  -e 'IF-DEMO' \
  -e 'SRC-DEMO' \
  -e 'PRINT-DEMO' \
  -o /tmp/64tcom-demos.txt
```

### Full pack smoke (heavier)

```bash
$FORTH --agent -c "$(pwd)" -f runtest.fth -o /tmp/runtest.txt
```

Loads the pack and runs ARM64-DEMO, ANS sim/native, IF-DEMO, NEST-DEMO, VAR-DEMO, SRC-DEMO, SAVE-MACHO, standalone, etc.

### Interactive GUI (optional)

In 64Forth (after `CHDIR` / `cd` to `64TCOMARM64/`):

```forth
FLOAD TARGETARM64.fth
NEST-DEMO
VAR-DEMO
IF-DEMO
SRC-DEMO
\ or:  ARM64-DEMO  .RUN-ANS  .RUN-ANS-N
\ or:  S" samples/hello.fth" TSRC-BUILD
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
| **IF-DEMO** | `IFT`…`LOOP3`, `WONCE` | `LOOP3 => 3`, `WONCE => 7`, etc. |
| | | `IF-DEMO: OK (sim)`, `OK (native)`, `OK (Mach-O LOOP3 => 3)` |
| **SRC-DEMO** | `MAIN` | `MAIN => 42`, `MAIN native => 42` |
| | | `Mach-O MAIN exit (want 42) = 42` |
| | | `SRC-DEMO: OK (source → sim/native/Mach-O => 42)` |
| **PRINT-DEMO** | `MAIN` | stdout `Hello, 64TCOM` (newline); exit **0** sim/native/Mach-O |
| | | `PRINT-DEMO: OK (source → sim/native/Mach-O print)` |

Quick check:

```bash
grep -E 'OK|fail|ABORT|undefined|Hello' /tmp/nest.txt /tmp/var.txt /tmp/if.txt /tmp/src.txt /tmp/print.txt
```

### Demo inventory (what each proves)

| Word / file | Proves |
|-------------|--------|
| `NEST-DEMO` / `NESTDEMO.fth` | Multi-level `G'` → `CALL-ABS` / true BLR; forward call; IF + nested calls |
| `VAR-DEMO` / `VARDEMO.fth` | `TVARIABLE`, `SYM-DATA` (daddr), `G'`, `G@`/`G!`, `FETCH#`/`STORE#`, data in `T-DATA` |
| `IF-DEMO` / `IFDEMO.fth` | Full Roadmap B: IF/loops/WHILE, sim+native+Mach-O LOOP3 |
| `SRC-DEMO` / `SRCDEMO.fth` | **Layer 1:** `TSRC-INCLUDE` + data reloc; `hello.fth` MAIN=>42 sim/native/Mach-O |
| `PRINT-DEMO` / `PRINTDEMO.fth` | **Layer 2 print:** `S"` + `TYPE#` (write SVC); stdout on three runners |
| `ARM64-DEMO` | Lit + `PLUS#` → ANS => 5 (sim/native/Mach-O) |
| `runtest.fth` | End-to-end pack smoke including demos above |

### Target VARIABLE / data model

```forth
TVARIABLE X
T: BUMP
  G' X G@  1 G,  ' PLUS# LIB,  G' X G!
  G' X G@
;T
```

| Piece | Role |
|-------|------|
| **`TVARIABLE name`** | One cell in `T-DATA`; symbol type `SYM-DATA` holds **daddr** (offset), not a host pointer |
| **`G' name`** (DATA) | `COMP-DATA-ADDR` — emit lit of runtime address; record reloc (MOVZ site + daddr) |
| **`G@` / `G!`** | Compile `FETCH#` / `STORE#` |
| **In-process** (sim / native) | `COMP-DATA-ADDR` uses `DTHERE` → absolute host `T-DATA` pointer |
| **Standalone Mach-O** | `tcom_data[]` embedded; C runtime copies data page; `MH-EMIT-DATA-FIXUP-C` rewrites MOVZ/MOVK×3 to `data + daddr` |

### Source loader (Layer 1) — pack-independent — **DONE**

**Architecture:** the restricted interpreter / token scanner lives in **`64TCOMSRC/64SRC.fth`** (compiler). Target packs only supply emitters (`TIF`, `G@`, prims, `COMP-DATA-ADDR`, SAVE-MACHO data). Do **not** put a special interpreter in `64TCOMARM64/`.

| Piece | Location |
|-------|----------|
| `TSRC-INCLUDE` token scanner + dialect | `64TCOMSRC/64SRC.fth` |
| `COMP-DATA-ADDR` default (`DTHERE`) | `64TCOMSRC/64HOST.fth` |
| `SYM-COMPILE-REF` → `COMP-DATA-ADDR` for `SYM-DATA` | `64TCOMSRC/64DIR.fth` |
| Control/data emitters + DATA-RELOC | Pack (`ASMARM64` / `OPTARM64`) |
| Mach-O `tcom_data[]` + data MOV fixup | `MACHOARM64.fth` |
| Sample sources + howto | `64TCOMARM64/samples/*.fth`, `samples/README.txt` |
| Pack demo | `SRC-DEMO` → `SRCDEMO.fth` |
| Console build | `TCOM-CLI samples/hello.fth` → `samples/hello`; `TCOM window/win.fth` → `.app` |
| One-shot build helper | `TSRC-BUILD` (ca u — path) in `TARGETARM64.fth` |

**Dialect:** `VARIABLE`, `: … ;`, numbers/`$hex`, `IF ELSE THEN`, `BEGIN UNTIL AGAIN WHILE REPEAT`, `@ ! + - DUP DROP SWAP OVER`, **`S" …"` / `TYPE` / `." …"`** (Layer 2), **`CHAR` / `[CHAR]`** + `EMIT`, comments `\ ` / `( )` / multi-line **`\\ … {`** or **`} … {`**, other names → symbol compile.

**Sample `samples/hello.fth`:**

```forth
VARIABLE X
: DOUBLE  DUP + ;
: MAIN
  S" Hello, 64TCOM
"
  TYPE
  21 DOUBLE  X !  X @
;
\ stdout Hello + exit 42
```

**Sample `samples/print.fth` (Layer 2 print):**

```forth
: MAIN
  S" Hello, 64TCOM
"
  TYPE
  0
;
```

**Print implementation notes**

| Piece | Role |
|-------|------|
| `TYPE#` | Lib prim: Darwin `write` — `X0=1`, `X1=buf`, `X2=len`, `X16=4`, `SVC #0x80` |
| `S"` | Dialect: store bytes in `T-DATA`, compile `COMP-DATA-ADDR` + length lit |
| `TYPE` | Dialect → `TYPE#` |
| `." …"` | Dialect: string + `TYPE#` |
| SIM | Traps `SVC #0x80` with `X16=4` → host `TYPE` |
| Native / Mach-O | Real syscall; string addr via existing data reloc |

**CLI args (Layer 2)**

| Word | Stack | Meaning |
|------|--------|---------|
| `ARGCOUNT` | `( -- n )` | Number of **user** arguments (not including program name) |
| `ARG1` | `( -- c-addr u )` | First user arg, or empty `(addr 0)` |
| `ARG2` | `( -- c-addr u )` | Second user arg, or empty |
| `ARG#` | `( n -- c-addr u )` | 1-based user arg; invalid `n` → empty |

Shell already parses blanks and `"..."` (including empty `""`). Mach-O `main(argc,argv)` copies `argv[1..]` into fixed `T-DATA` counted slots (max 16 × 255). Sim/native leave `ARGCOUNT=0`. Sample: `samples/args.fth`.

**Re-run (agent):**

```bash
cd ~/Documents/64TCOM/64TCOMARM64
FORTH=/Applications/64Forth.app/Contents/MacOS/64Forth
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'SRC-DEMO' \
  -o /tmp/src.txt
# Expect:
#   MAIN => 42
#   MAIN native => 42
#   Mach-O MAIN exit (want 42) = 42
#   SRC-DEMO: OK (source → sim/native/Mach-O => 42)
```

**One-shot TSRC-BUILD:**

```bash
$FORTH --agent -c "$(pwd)" \
  -e 'FLOAD TARGETARM64.fth' \
  -e 'S" samples/hello.fth" TSRC-BUILD' \
  -e 'S" ./tcomarm64" SYSTEM .' \
  -o /tmp/tsrc-build.txt
# Expect: 42 on SYSTEM line; ./tcomarm64 exits 42
```

Or after pack load (interactive):

```forth
TARGET-INIT
S" samples/hello.fth" TSRC-INCLUDE
ARM64-FINISH
S" MAIN" RUN-SYM .          \ => 42
S" MAIN" MACHO-ENTRY-SET SAVE-MACHO-FILE
S" ./tcomarm64" SYSTEM .    \ => 42
\ or:  S" samples/hello.fth" TSRC-BUILD
```

**Agent verify (2026-08-17):** SRC-DEMO and TSRC-BUILD green on 64Forth 1.1.2 `/Applications` — all three runners MAIN=>42.

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
- [x] **0.4** TETRA `.app` + text grid; `\ANS`/`\TCOM`; growable TSRC; `.fth` again
- [x] **0.5** tetra dual-load + real TONE; DIRECTIVE line-skip fix
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
| IF / BEGIN–UNTIL / WHILE / loops | **Done** — Roadmap B (`IF-DEMO` sim+native+Mach-O) |
| Sim + in-process native run | Working |
| Standalone CLI Mach-O via `cc` | Working — ANS exit 5; hello MAIN 42; **print Hello** |
| **Parse a `.fth` and compile colon defs** | **Done (restricted)** — `TSRC-INCLUDE` / `TSRC-BUILD` / `SRC-DEMO` |
| Target `TVARIABLE` + `@`/`!` + data | **Done** — daddr + DATA-RELOC; sim/native/`tcom_data[]` Mach-O |
| **Print (`TYPE` / `S"`)** | **Done** — `TYPE#` write SVC; `PRINT-DEMO` three runners |
| argc/argv, richer I/O, GUI apps | Not yet |
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
| `64TCOMSRC/64SRC.fth` | Generic `.fth` loader (`TSRC-INCLUDE`) — **not** pack-specific |
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
| `SRCDEMO.fth` / `samples/hello.fth` | Layer 1: source → sim/native/Mach-O MAIN => 42 |
| `PRINTDEMO.fth` / `samples/print.fth` | Layer 2 print: `S"` + `TYPE` → stdout + exit 0 |
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

**Strategic priority:** Layer 1 closed; **Layer 2 print closed**. Next: argc/argv (rest of Layer 2), then messier sources / dialect growth. GUI is last.

### Closed this batch (2026-08-17)

| Deliverable | Proof |
|-------------|--------|
| Nested colon + IF/loop | `NEST-DEMO` sim+native; `IF-DEMO` sim+native+Mach-O LOOP3 |
| `VARIABLE` + `@`/`!` + data | `TVARIABLE` / daddr / DATA-RELOC; `VAR-DEMO` + Mach-O data page |
| Restricted `.fth` loader | `64TCOMSRC/64SRC.fth` `TSRC-INCLUDE` (not in pack) |
| Source → sim + native + Mach-O | **`SRC-DEMO` / `TSRC-BUILD`**: `hello.fth` MAIN **exit 42** |
| **Print to stdout** | **`PRINT-DEMO`**: `print.fth` → `Hello, 64TCOM\n` + exit 0 (all paths) |

### Milestone table

| Step | Deliverable | Gate |
|------|-------------|------|
| 1 | Nested colon + IF/loop **via compiled words** | **Done** — `NEST-DEMO`; IF-DEMO Mach-O LOOP3 |
| 2 | `VARIABLE` + `@`/`!` + data area | **Done** — daddr + reloc + `tcom_data[]` |
| 3 | Target subset parser: `: … ;` `IF`… numbers, word calls | **Done** — `64SRC` + `hello.fth` |
| 4 | `MAIN` + `SAVE-MACHO` exit code | **Done** — `./tcomarm64` exit **42** |
| 5 | Print (`S"` + `TYPE` / write) | **Done** — `PRINT-DEMO` three runners |
| 6 | argc/argv onto data stack | **Next** (Layer 2 remainder) |
| 7 | Second, messier source (two files, deeper control) | Still green on three runners |
| 8 | App bundle + windows | 64Forth-class apps (Layer 4) |

### Immediate engineering queue

0. ~~**Host agent**~~ — **done** (64Forth 1.1.2)  
1. ~~**Roadmap E nested colon**~~ — **done** (`NEST-DEMO` sim+native)  
2. ~~**VARIABLE + @/!**~~ — **done** (`TVARIABLE`, `G@`/`G!`, `VAR-DEMO`)  
2b. ~~**Roadmap B**~~ — **done** (WHILE/REPEAT, full IF-DEMO, Mach-O LOOP3)  
2c. ~~**Data embed for standalone VAR (Mach-O)**~~ — **done** (`tcom_data[]` + MOV fixup)  
3. ~~**Source loader + closed loop**~~ — **done** (`TSRC-INCLUDE`, `TSRC-BUILD`, `SRC-DEMO` MAIN=>42)  
4. ~~**Layer 2 print**~~ — **done** (`TYPE#` write SVC, dialect `S"`/`TYPE`, `PRINT-DEMO`)  
5. ~~**Layer 2 args**~~ — **done** (`ARGCOUNT` `ARG1` `ARG2` `ARG#`; `samples/args.fth`)  
6. Grow dialect + messier `.fth` (control-heavy, multi-def)  
7. Library wave (compares, `ROT`, …) as demos need  
8. Grow assembler / library **on demand**  
9. **Phase 4.0** utilities — listing/xref after richer sources exist  

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
| **Control demos** | **Roadmap B done** | `IF-DEMO` sim+native+Mach-O LOOP3; WHILE/REPEAT |
| **Source→image→Mach-O** | **Layer 1 done** | `hello.fth` MAIN=>42 sim/native/Mach-O |
| **CLI I/O → app** | **Open** | Layers 2–4 (see Product destination) |
| **4.0** Utilities | **Open** | Listing, xref, debugger — after richer sources |

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
- **`IF-DEMO` (sim+native+Mach-O):** IFT/IFF/IFN/IFZ, ZEQ/ZNE, ONCE, PUSHPOP, ADD3, **LOOP3 => 3**, **WONCE => 7** (WHILE/REPEAT)
  - LOOP3 machine: `MOV#0` + `ADD-IMM` + `MOV` + `SUB-IMM` + `CBNZ` back (`B5FFFFA1`)
  - Mach-O entry `LOOP3` process exit **3**

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
\ hello.fth  — target source (name TBD)
VARIABLE X
: DOUBLE  ( n -- 2n )  DUP + ;
: MAIN    ( -- )  21 DOUBLE  X !  X @  ;
```

**Success criteria for the first “real compiler” milestone:**

1. `FLOAD TARGETARM64.fth`
2. Something like `S" hello.fth" TCOM-COMPILE` (or `INCLUDE` under a target compile mode)
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

**Layer 0 + Layer 1 MVP:** stack ops, `+`/`-`, lit, `CALL-ABS` (true BLR; `/INLINE-CALLS` fallback), control via `TIF`/loops and dialect, nested colon (`NEST-DEMO`), `VARIABLE` with daddr + Mach-O data page, restricted `.fth` loader → sim/native/standalone (`hello.fth` MAIN=>42).

Still needed for **useful** programs: broader dialect/lib, multi-file sources, strings/I/O policy, richer CLI runtime — then GUI.

### Priority order (what blocks real programs)

#### 1. Call model that scales — Phase 3.5 (runtime) — **DONE**

Native and Mach-O default to true BLR (fixup `.quad` → base+taddr).  
`/INLINE-CALLS` restores the ≤5-insn paste path. Nested multi-level colon proven by `NEST-DEMO`; deeper recursion may need more LR discipline later.

**Detail:** [`64DESIGN/Phase 3.5 ARM64 notes.txt`](64DESIGN/Phase%203.5%20ARM64%20notes.txt)

#### 2. Control-flow library the compiler can use — **DONE for pack + dialect**

| Grow | Status |
|------|--------|
| `BRANCH#` / `ZBRANCH#` | Done (relocatable) |
| `TIF`/`TELSE`/`TTHEN` + loops | Done (`IF-DEMO`) |
| Dialect `IF`…`REPEAT` via `TSRC` | Done (maps to pack emitters) |
| Later: `DO`/`LOOP` | Open when a source needs it |

#### 3. Memory model for real data — **VARIABLE done; frames open**

| Need | Status |
|------|--------|
| `@` `!` + `VARIABLE` | **Done** — daddr, `COMP-DATA-ADDR`, Mach-O `tcom_data[]` |
| `C@` `C!` `2@` `2!` | Open when sources need them |
| Locals / frame | Open — `STP`/`LDP` when non-leaf needs it |

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
  - [x] B2b. Full suite on **native** + Mach-O entry `LOOP3` => exit 3
  - [x] B3. `BRANCH#`/`ZBRANCH#` relocatable via ADR−taddr base (no host bake-in)
  - [x] B4. `TAGAIN` / `TWHILE` / `TREPEAT`; `WONCE` demo; Mach-O LOOP3 in IF-DEMO
  - Pack IF remains `TIF`/`TELSE`/`TTHEN` (host `IF` left alone; source loader maps IF…)
- [x] **C (data path).** `SYM-DATA` = daddr; `COMP-DATA-ADDR` + DATA-RELOC; Mach-O `tcom_data[]` + MOV fixup
- [ ] **C (frames).** `LDP`/`STP` + `ADRP` for call frames — *asm* when non-leaf needs it
- [ ] **D.** Library wave: `ROT`, logic, compares, `C@`/`C!` — *lib*
- [x] **E.** Nested colon demo (true BLR, multi-level calls) — `NEST-DEMO`
- [ ] **F.** Optional: strings / `TYPE` if host I/O model exists
- [ ] **G.** More ISA as programs demand

**Source → CLI → app (Layers 1–4):**

- [x] **P1 (MVP)** Compiler surface: IF/loops via dialect, calls, `VARIABLE`, `TSRC-INCLUDE` / `TSRC-BUILD`
- [ ] **P2** Library breadth driven by next real sources
- [ ] **P3** Standalone CLI runtime beyond exit code (`write`, argc/argv)
- [ ] **P4** Fairly complicated multi-file Forth (stress compiler; three runners)
- [ ] **P5** Debuggability (listing, map, SIM step) — after richer sources
- [ ] **P6** Finder double-click + windows (app bundle + UI prims) — last

### Success tests

**Codegen (Layer 0):**

```text
T: FOO  ... nested calls, IF/THEN, @/! ... ;T
.RUN-ANS-N => expected
SAVE-MACHO-FILE  → binary behaves the same
without relying on 5-insn inlining
```

**Source compile (Layer 1) — achieved:**

```text
FLOAD TARGETARM64.fth
SRC-DEMO
\ or:  S" samples/hello.fth" TSRC-BUILD
MAIN  (sim + native) => 42
./tcomarm64 exit 42
```

**CLI useful (Layer 2):** same, plus print/args beyond bare exit code.

**GUI (Layer 4):** double-clickable bundle with its own window(s); same image model as CLI.

### What not to prioritize yet

- Full NEON / system register set  
- Full ANS Forth compatibility on day one  
- Hand-rolled perfect Mach-O (already use `cc`)  
- Phase 4 utilities (listing/xref) **before** a second real source stresses the dialect  
- Interactive debugger inside the standalone app (before CLI I/O is useful)  
- Finder/GUI shells (before CLI source→binary + I/O is reliable)  
- Polishing `ASM-DEMO` alone without compiler/library/source path  

### Short answer

**Next for real programs / apps:**

1. ~~**True calls (3.5)**~~ — **done** (default true BLR)  
2. ~~**Control demos (IF-DEMO)**~~ — **done** (sim+native+Mach-O LOOP3)  
3. ~~**Nested colon (E)**~~ — **done** (`NEST-DEMO`)  
4. ~~**Memory model for VARIABLE**~~ — **done** (daddr + Mach-O data page)  
5. ~~**Source loader (P1 MVP)**~~ — **done** (`TSRC-INCLUDE` / `TSRC-BUILD` / MAIN=>42)  
6. ~~**Print (`TYPE` / write)**~~ — **done** (`PRINT-DEMO`)  
7. **argc/argv** — finish Layer 2  
8. **Second messier `.fth` + dialect growth** — keep three runners green  
9. **Library breadth** — what next sources actually call  
10. **Assembler opcodes only when a prim needs them**  
11. **GUI (P6)** only after CLI source→binary + I/O is boring  

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
