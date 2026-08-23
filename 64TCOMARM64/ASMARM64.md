# ASMARM64 — AArch64 assembler toolkit (Phase 3.2)

Public domain.  
**Synced Aug 23, 2026 3:16 PM** — identical copies:

| Home | Path |
|------|------|
| Pack | `64TCOMARM64/ASMARM64.fth` |
| Library | `64Forth/.../Library/Assembler/asmarm64.fth` |

Tests: `ASMARMTESTS.fth` → `ASM-TESTS` (same sync stamp).  
Progress monitor: [`../STATUSASM64.md`](../STATUSASM64.md) (also in 64Forth `Resources/Docs/`).

## What it is

A **practical STC/Forth-oriented** AArch64 emitter set for:

- **64TCOM** target CODE images (`FLOAD TARGETARM64.fth`)
- **Interactive 64Forth** host sessions (load alone → assemble → optional `CALL-NATIVE` → **discard**)

Not a full A64 ISA assembler. Deferred: NEON / FP / SVE, most barriers / atomics / system regs.

## ABI (Forth leaves)

| Reg | Role |
|-----|------|
| **X0** | TOS |
| **X19** | DSP (push `STR X0,[X19,#-8]!`) |
| **X16** | Call temp (`CALL-ABS`) |
| **X30** | LR |
| Cell | 8 bytes |

## How to load

**Two homes (same source — keep in sync):**

| Home | Path | Who loads it |
|------|------|----------------|
| Pack | `64TCOMARM64/ASMARM64.fth` | `FLOAD TARGETARM64.fth` only |
| Library | `64Forth/.../Library/Assembler/asmarm64.fth` | `FROMLIB` on interactive 64Forth only — **not** TCOM |

### TCOM pack

```forth
CHDIR …/64TCOMARM64
FLOAD TARGETARM64.fth
.ASMARM64
```

Emit goes to the target CODE image (`HERE-T` / `C,-T` from 64HOST).  
TCOM does **not** load the Library copy.

### 64Forth alone (host toolkit)

```forth
FROMLIB FLOAD Assembler/asmarm64.fth
FROMLIB FLOAD Assembler/ASMARMTESTS.fth
.ASMARM64
ASM-TESTS                 \ extensive encode + run suite
ASMARM64-DISCARD          \ unload when finished
```

Rebuild 64Forth after editing the Library file so the app bundle copy updates.

**Detection:** if `T-CODE-BASE` is defined (64HOST), pack backend; else host buffer + overlay.  
(`\ANS`/`\TCOM` are flipped *after* pack includes, so they are not used to choose the emit backend.)

## Vocabulary

Emitters and registers are defined in **`ASMARM64`** (not in FORTH). The kernel’s empty **`ASSEMBLER`** vocabulary name is redefined to select `ASMARM64`, so either listing works:

```forth
ASMARM64 WORDS
ASSEMBLER WORDS      \ same wordlist
SETASSEM             \ ALSO ASMARM64 DEFINITIONS
  X0 X1 ADD-X-X,
  RET,
END-CODE
```

## Overlay / discard

| Word | Meaning |
|------|---------|
| `ASMARM64-OVERLAY` | Marker (ANS/host); all toolkit words live at/after it |
| `ASMARM64-DISCARD` | Free ASM/EXEC buffers; `FORGET ASMARM64-OVERLAY` |
| Reload | `TCOM-ANEW` / re-`INCLUDED` forgets prior overlay then reloads |

**Pack loads:** discard of assembler alone is unsupported (OPT/LIB would dangle). Reload `TARGETARM64` or restart.

Assembled **bytes** live in the host buffer (or target image), not in ITC dictionary CODE.

## Emit model

| Word | Role |
|------|------|
| `HERE-T` | Current emit **offset** (taddr) |
| `C,-T` `C!-T` `C@-T` | Byte append / patch / fetch |
| `W,` | Little-endian 32-bit insn |
| `ALIGN4-T` `PATCH-W` `W@-T` | Align / 32-bit patch |

**Host extras:** `ASM-CLEAR` `ASM-ORG` `ASM-USED` `ASM-ENTRY` `ASM-ALLOC` `ASM-MAKE-EXEC` `ASM-RUN-LEAF`

```forth
SETASSEM
  ALIGN4-T  HERE-T          \ leaf start (taddr)
  7 X0 MOV-X-IMM64,
  RET,
END-CODE
0 ASM-RUN-LEAF .            \ 7
```

## Layers

1. **ISA emitters** — `ADD-X-X,`, `LDR-OFF,`, `B.COND,`, `MOVZ-W,`, …
2. **Forth-ABI / structured** — `TIF`/`TTHEN`, `TDO`/`TLOOP`, `CALL-ABS,`, `LIT-PUSH-X0,`

Use `SETASSEM` … `END-CODE` (or `C;`) so the `ASMARM64` vocabulary is in the search order.

## Emitter catalog (supported)

**Control:** `NOP,` `BTI,` `BTI-C,` `BTI-J,` `BTI-JC,` `RET,` `RET-X,` `BLR-X,` `BR-X,` `SVC,`  
`B-IMM,` `BL-IMM,` `B.COND,` `CBZ-X,` `CBNZ-X,` `CBZ-W,` `CBNZ-W,`  
`CALL-ABS,` `JMP-ABS,` `AHEAD` `THEN,` `AGAIN,` `AIF,` `AELSE,` `ATHEN,`  
Labels `LL:` `BR>LL` (0..15)

**X ALU / move:** `MOVZ-X,` `MOVK-X,` `MOV-X-IMM64,` `MOV-X-X,`  
`AND-X,` `ORR-X,` `EOR-X,` `ADD-X-X,` `SUB-X-X,` `ADDS-X,` `SUBS-X,` `ADC-X,` `SBC-X,` `CMP-X,`  
`ADD-IMM,` `SUB-IMM,` `MUL-X,` `UDIV-X,` `MSUB-X,`

**Shifts / bitfield:** `LSL-IMM,` `LSR-IMM,` `ASR-IMM,` `LSL-X,` `LSR-X,` `ASR-X,` `UBFM-X,` `SBFM-X,`

**W suite:** `MOVZ-W,` `MOVK-W,` `MOV-W-IMM32,` `MOV-W-W,` `AND-W,` `ORR-W,` `EOR-W,`  
`ADD-W-W,` `SUB-W-W,` `ADDS-W,` `SUBS-W,` `CMP-W,` `ADD-W-IMM,` `SUB-W-IMM,`  
`LDR-W-OFF,` `STR-W-OFF,`

**Addressing:** `ADR,` `ADRP,` `ADR-X0,`  
`STR-PRE,` `LDR-POST,` `LDR-PRE,` `STR-POST,` `LDR-X0,` `STR-X0,` `LDR-OFF,` `STR-OFF,`  
`LDR-REG,` `STR-REG,` `LDRB-X,` `STRB-X,` PC-rel `LDR64-*`

**Pairs:** `STP-OFF,` `LDP-OFF,` `STP-PRE,` `LDP-POST,`

**Select:** `CSEL-X,` `CSINC-X,` `CSET-X,` `T0=,`

**Deferred:** NEON / FP / SVE; full barriers / atomics / MRS/MSR; exotic extends; full ISA.

## Recipe: add an emitter

1. Look up the A64 encoding (Arm ARM / llvm / existing sibling).
2. Name it `FOO,` with a stack comment `( … -- )`.
3. Range-check immediates; `S" …" TCOM-ABORT` on failure.
4. Build the u32; `W,`.
5. If SIM must execute it, extend `SIMARM64` when demos need it.
6. Document in this catalog + check off `STATUSASM64.md`.

## Writing a LIB leaf (TCOM)

```forth
SETASSEM
  \ body using X0/X19 ABI
  RET,
END-CODE
```

Register the cookie / symbol through DIR as today’s LIB pattern requires.

## JIT / native notes

Host `ASM-MAKE-EXEC` uses `ALLOCATE-EXEC` + `MPROTECT` RX + `ICACHE-INVAL`.  
Requires 64Forth entitlements (`allow-jit` / unsigned executable memory) as for `.RUN-ANS-N`.
