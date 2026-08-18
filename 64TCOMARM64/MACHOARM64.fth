\ MACHOARM64.fth — Standalone macOS arm64 executable (Phase 3.4 / 3.5)
\ Public domain. Requires OPTARM64, ASMARM64, 64DIR.
\
\ Emits a C source file that embeds A64 and runs it via mmap.
\ Phase 3.5 default: keep CALL-ABS as BLR; C main fixups .quad
\   offset → (buf + taddr) before mprotect. /INLINE-CALLS (NATARM64)
\   restores leaf paste-inlining in the embedded image.
\
\ Writes NAME-build.sh; with 64Forth 1.0.5+ SYSTEM, SAVE-MACHO also runs
\ the build (sh NAME-build.sh) so no separate Terminal step is required.
\
\   /MACHO  /NOMACHO          auto-emit on TARGET-FINISH
\   /MACHO-BUILD /NOMACHO-BUILD   run cc after emit (default: build)
\   /MACHO-GUI /NOMACHO-GUI   emit AppKit .m + run loop (Layer 4)
\   /INLINE-CALLS /NOINLINE-CALLS   (shared with NATARM64; default true BLR)
\   S" ANS" MACHO-ENTRY-SET   |  MACHO-ENTRY-COLD
\   SAVE-MACHO-FILE
\   c-addr u SAVE-MACHO-AS
\
\ Manual (no SYSTEM / /NOMACHO-BUILD):
\   sh NAME-build.sh
\   ./NAME ; echo $?

TCOM-ANEW MACHOARM64

FORTH DEFINITIONS
DECIMAL

CREATE MACHO-FILENAME  128 ALLOT
S" tcomarm64" MACHO-FILENAME PLACE

FALSE VALUE ?SAVE-MACHO
: /MACHO    ( -- )  TRUE  TO ?SAVE-MACHO ;
: /NOMACHO  ( -- )  FALSE TO ?SAVE-MACHO ;

\ Auto-run build via SYSTEM after writing .c / -build.sh (64Forth 1.0.5+)
TRUE VALUE ?MACHO-BUILD
: /MACHO-BUILD    ( -- )  TRUE  TO ?MACHO-BUILD ;
: /NOMACHO-BUILD  ( -- )  FALSE TO ?MACHO-BUILD ;

\ Layer 4: AppKit GUI shell (.m) instead of CLI (.c)
FALSE VALUE ?MACHO-GUI
: /MACHO-GUI    ( -- )  TRUE  TO ?MACHO-GUI ;
: /NOMACHO-GUI  ( -- )  FALSE TO ?MACHO-GUI ;

VARIABLE MACHO-ENTRY-T
0 MACHO-ENTRY-T !

: MACHO-ENTRY-SET  ( c-addr u -- )
  SYM-FIND-IX SYM-ADDR@ MACHO-ENTRY-T !
  ;

: MACHO-ENTRY-COLD  ( -- )  0 MACHO-ENTRY-T ! ;

: MACHO-ENTRY-T@  ( -- taddr )
  MACHO-ENTRY-T @ DUP IF EXIT THEN
  DROP A64-COLD @
  ;

VARIABLE MH-BUF
VARIABLE MH-LEN
VARIABLE MH-I
VARIABLE MH-P
VARIABLE MH-T
VARIABLE MH-N
VARIABLE MH-FID
VARIABLE MH-BASE-SAVE
VARIABLE MH-OFF
VARIABLE MH-SRC
VARIABLE MH-DST
VARIABLE MH-J
VARIABLE MH-W

0 MH-BUF !

$D63F0200 CONSTANT MH-BLR16
$D61F0200 CONSTANT MH-BR16
$14000003 CONSTANT MH-B3
$A9BF7FFE CONSTANT MH-STP-LR
$A8C17FFE CONSTANT MH-LDP-LR
$D503201F CONSTANT MH-NOP
$D65F03C0 CONSTANT MH-RET

: MH-W@  ( addr -- u32 )
  DUP C@
  OVER 1 + C@ 8 LSHIFT OR
  OVER 2 + C@ 16 LSHIFT OR
  SWAP 3 + C@ 24 LSHIFT OR
  ;

: MH-W!  ( u32 addr -- )
  OVER $FF AND OVER C!
  OVER 8 RSHIFT $FF AND OVER 1 + C!
  OVER 16 RSHIFT $FF AND OVER 2 + C!
  SWAP 24 RSHIFT $FF AND SWAP 3 + C!
  ;

: MH-FREE  ( -- )
  MH-BUF @ IF MH-BUF @ FREE DROP 0 MH-BUF ! THEN
  ;

: MH-COPY-IMAGE  ( -- )
  MH-FREE
  HERE-T DUP MH-LEN !
  ALLOCATE IF DROP S" MACHO: ALLOCATE failed" TYPE CR TCOM-ABORT THEN
  MH-BUF !
  0 MH-I !
  BEGIN MH-I @ MH-LEN @ U< WHILE
    T-CODE-BASE MH-I @ + C@
    MH-BUF @ MH-I @ + C!
    1 MH-I +!
  REPEAT
  ;

\ Match CALL-ABS: set MH-P = .quad host addr, MH-T = taddr; MH-DST = call start
: MH-FIND-CALL  ( host-start -- f )
  DUP MH-DST !
  MH-P !
  \ New: STP.. BLR at +8, LDP +12, B+3 +16, .quad +20
  MH-P @ 8 + MH-W@ MH-BLR16 = IF
    MH-P @ 12 + MH-W@ MH-LDP-LR = IF
      MH-P @ 16 + MH-W@ MH-B3 = IF
        MH-P @ 20 + @ MH-T !
        MH-P @ 20 + MH-P !
        TRUE EXIT
      THEN
    THEN
  THEN
  \ Old: BLR +4, B+3 +8, .quad +12
  MH-P @ 4 + MH-W@ DUP MH-BLR16 = SWAP MH-BR16 = OR IF
    MH-P @ 8 + MH-W@ MH-B3 = IF
      MH-P @ 12 + @ MH-T !
      MH-P @ 12 + MH-P !
      TRUE EXIT
    THEN
  THEN
  FALSE
  ;

\ Optional (/INLINE-CALLS): paste leaf body over call site
: MH-INLINE-ONE  ( dst-host taddr -- )
  MH-T !  MH-DST !
  MH-BUF @ MH-T @ + MH-SRC !
  0 MH-J !
  BEGIN MH-J @ 7 < WHILE
    MH-SRC @ MH-J @ 4 * + MH-W@ MH-W !
    MH-W @ MH-DST @ MH-J @ 4 * + MH-W!
    MH-W @ MH-RET = IF
      1 MH-J +!
      BEGIN MH-J @ 7 < WHILE
        MH-NOP MH-DST @ MH-J @ 4 * + MH-W!
        1 MH-J +!
      REPEAT
      EXIT
    THEN
    1 MH-J +!
  REPEAT
  ;

: MH-COUNT-CALLS  ( -- )
  0 MH-N !
  0 MH-I !
  BEGIN MH-I @ MH-LEN @ 28 - U< WHILE
    MH-BUF @ MH-I @ + MH-FIND-CALL IF
      MH-T @ MH-LEN @ U< IF 1 MH-N +! THEN
    THEN
    4 MH-I +!
  REPEAT
  ;

: MH-INLINE-CALLS  ( -- )
  0 MH-N !
  0 MH-I !
  BEGIN MH-I @ MH-LEN @ 28 - U< WHILE
    MH-BUF @ MH-I @ + MH-FIND-CALL IF
      MH-T @ MH-LEN @ U< IF
        MH-DST @ MH-T @ MH-INLINE-ONE
        1 MH-N +!
      THEN
    THEN
    4 MH-I +!
  REPEAT
  ;

\ Phase 3.5 default: leave offsets; C main relocates .quad to buf+off
\ /INLINE-CALLS: paste leaves into the embedded image (no C fixup needed)
: MH-REWRITE-CALLS  ( -- )
  [DEFINED] ?INLINE-CALLS [IF]
    ?INLINE-CALLS IF MH-INLINE-CALLS ELSE MH-COUNT-CALLS THEN
  [ELSE]
    MH-COUNT-CALLS
  [THEN]
  ;

: MH-EMIT-S  ( c-addr u -- )  MH-FID @ WRITE-FILE DROP ;
: MH-EMIT-NL ( -- )  10 PAD C! PAD 1 MH-FID @ WRITE-FILE DROP ;
: MH-EMIT-B  ( b -- )  PAD C! PAD 1 MH-FID @ WRITE-FILE DROP ;

: MH-EMIT-U  ( u -- )
  BASE @ MH-BASE-SAVE !
  DECIMAL
  0 <# #S #> MH-EMIT-S
  MH-BASE-SAVE @ BASE !
  ;

: MH-EMIT-HEX2  ( b -- )
  BASE @ MH-BASE-SAVE !
  HEX 0 <# # # #> MH-EMIT-S
  MH-BASE-SAVE @ BASE !
  ;

: MH-EMIT-FIXUP-C  ( -- )
  \ Relocate CALL-ABS .quad while still RW (before mprotect)
  \ New site: STP;LDR;BLR;LDP;B+2;.quad  (.quad at +20)
  \ Old site: LDR;BLR;B+3;.quad           (.quad at +12)
  S"   /* Phase 3.5: CALL-ABS .quad taddr -> buf+taddr (true BLR) */" MH-EMIT-S MH-EMIT-NL
  S"   {" MH-EMIT-S MH-EMIT-NL
  S"     uint32_t i;" MH-EMIT-S MH-EMIT-NL
  S"     for (i = 0; i + 28u <= TCOM_CODE_LEN; i += 4u) {" MH-EMIT-S MH-EMIT-NL
  S"       uint32_t *w = (uint32_t *)(buf + i);" MH-EMIT-S MH-EMIT-NL
  S"       uint64_t *q = 0;" MH-EMIT-S MH-EMIT-NL
  S"       if (w[2] == 0xD63F0200u && w[3] == 0xA8C17FFEu && w[4] == 0x14000003u)" MH-EMIT-S MH-EMIT-NL
  S"         q = (uint64_t *)(buf + i + 20);" MH-EMIT-S MH-EMIT-NL
  S"       else if ((w[1] == 0xD63F0200u || w[1] == 0xD61F0200u) && w[2] == 0x14000003u)" MH-EMIT-S MH-EMIT-NL
  S"         q = (uint64_t *)(buf + i + 12);" MH-EMIT-S MH-EMIT-NL
  S"       if (q) {" MH-EMIT-S MH-EMIT-NL
  S"         uint64_t off = *q;" MH-EMIT-S MH-EMIT-NL
  S"         if (off < (uint64_t)TCOM_CODE_LEN)" MH-EMIT-S MH-EMIT-NL
  S"           *q = (uint64_t)(uintptr_t)(buf + off);" MH-EMIT-S MH-EMIT-NL
  S"       }" MH-EMIT-S MH-EMIT-NL
  S"     }" MH-EMIT-S MH-EMIT-NL
  S"   }" MH-EMIT-S MH-EMIT-NL
  ;

\ Patch MOVZ+3×MOVK at byte offset `off` to load 64-bit imm into same Rd
: MH-EMIT-DATA-FIXUP-C  ( -- )
  [DEFINED] DATA-RELOC-N [IF]
    DATA-RELOC-N @ 0= IF EXIT THEN
    S"   /* Data cell addresses: MOVZ/MOVK host → data page + daddr */" MH-EMIT-S MH-EMIT-NL
    S"   {" MH-EMIT-S MH-EMIT-NL
    S"     static const uint32_t d_off[] = {" MH-EMIT-S
    0 MH-I !
    BEGIN MH-I @ DATA-RELOC-N @ < WHILE
      MH-I @ CELLS DATA-RELOC-OFF + @ MH-EMIT-U
      S" u," MH-EMIT-S
      1 MH-I +!
    REPEAT
    S" };" MH-EMIT-S MH-EMIT-NL
    S"     static const uint32_t d_adr[] = {" MH-EMIT-S
    0 MH-I !
    BEGIN MH-I @ DATA-RELOC-N @ < WHILE
      MH-I @ CELLS DATA-RELOC-D + @ MH-EMIT-U
      S" u," MH-EMIT-S
      1 MH-I +!
    REPEAT
    S" };" MH-EMIT-S MH-EMIT-NL
    S"     uint32_t ri;" MH-EMIT-S MH-EMIT-NL
    S"     for (ri = 0; ri < (uint32_t)(sizeof d_off/sizeof d_off[0]); ri++) {" MH-EMIT-S MH-EMIT-NL
    S"       uint32_t *w = (uint32_t *)(buf + d_off[ri]);" MH-EMIT-S MH-EMIT-NL
    S"       uint32_t rd = w[0] & 31u;" MH-EMIT-S MH-EMIT-NL
    S"       uint64_t a = (uint64_t)(uintptr_t)(data + d_adr[ri]);" MH-EMIT-S MH-EMIT-NL
    S"       w[0] = 0xD2800000u | ((uint32_t)(a & 0xFFFFu) << 5) | rd;" MH-EMIT-S MH-EMIT-NL
    S"       w[1] = 0xF2A00000u | ((uint32_t)((a >> 16) & 0xFFFFu) << 5) | rd;" MH-EMIT-S MH-EMIT-NL
    S"       w[2] = 0xF2C00000u | ((uint32_t)((a >> 32) & 0xFFFFu) << 5) | rd;" MH-EMIT-S MH-EMIT-NL
    S"       w[3] = 0xF2E00000u | ((uint32_t)((a >> 48) & 0xFFFFu) << 5) | rd;" MH-EMIT-S MH-EMIT-NL
    S"     }" MH-EMIT-S MH-EMIT-NL
    S"   }" MH-EMIT-S MH-EMIT-NL
  [THEN]
  ;

\ Patch HOST-CALL .quad sites to absolute &host_fn[slot]
: MH-EMIT-HOST-FIXUP-C  ( -- )
  [DEFINED] HOST-RELOC-N [IF]
    HOST-RELOC-N @ 0= IF EXIT THEN
    S"   /* Host-call: .quad MAGIC|slot -> host_fn[slot] */" MH-EMIT-S MH-EMIT-NL
    S"   {" MH-EMIT-S MH-EMIT-NL
    S"     static const uint32_t h_off[] = {" MH-EMIT-S
    0 MH-I !
    BEGIN MH-I @ HOST-RELOC-N @ < WHILE
      MH-I @ CELLS HOST-RELOC-OFF + @ MH-EMIT-U
      S" u," MH-EMIT-S
      1 MH-I +!
    REPEAT
    S" };" MH-EMIT-S MH-EMIT-NL
    S"     static const uint32_t h_slot[] = {" MH-EMIT-S
    0 MH-I !
    BEGIN MH-I @ HOST-RELOC-N @ < WHILE
      MH-I @ CELLS HOST-RELOC-SLOT + @ MH-EMIT-U
      S" u," MH-EMIT-S
      1 MH-I +!
    REPEAT
    S" };" MH-EMIT-S MH-EMIT-NL
    S"     uint32_t hi;" MH-EMIT-S MH-EMIT-NL
    S"     for (hi = 0; hi < (uint32_t)(sizeof h_off/sizeof h_off[0]); hi++) {" MH-EMIT-S MH-EMIT-NL
    S"       uint32_t s = h_slot[hi];" MH-EMIT-S MH-EMIT-NL
    S"       uint64_t *q = (uint64_t *)(buf + h_off[hi]);" MH-EMIT-S MH-EMIT-NL
    S"       if (s < (uint32_t)(sizeof host_fn / sizeof host_fn[0]) && host_fn[s])" MH-EMIT-S MH-EMIT-NL
    S"         *q = (uint64_t)(uintptr_t)host_fn[s];" MH-EMIT-S MH-EMIT-NL
    S"     }" MH-EMIT-S MH-EMIT-NL
    S"   }" MH-EMIT-S MH-EMIT-NL
  [THEN]
  ;

: MH-EMIT-DATA-ARRAY  ( -- )
  S" static const uint8_t tcom_data[] = {" MH-EMIT-S MH-EMIT-NL
  HERE-D 0= IF
    S"   0" MH-EMIT-S MH-EMIT-NL
  ELSE
    0 MH-I !
    BEGIN MH-I @ HERE-D U< WHILE
      MH-I @ 15 AND 0= IF S"   " MH-EMIT-S THEN
      S" 0x" MH-EMIT-S
      T-DATA-BASE MH-I @ + C@ MH-EMIT-HEX2
      S" ," MH-EMIT-S
      MH-I @ 15 AND 15 = IF MH-EMIT-NL ELSE S" " MH-EMIT-S THEN
      1 MH-I +!
    REPEAT
    MH-EMIT-NL
  THEN
  S" };" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  S" #define TCOM_DATA_LEN ((uint32_t)sizeof(tcom_data))" MH-EMIT-S MH-EMIT-NL
  ;

: MH-EMIT-CODE-ARRAY  ( -- )
  S" static const uint8_t tcom_code[] = {" MH-EMIT-S MH-EMIT-NL
  0 MH-I !
  BEGIN MH-I @ MH-LEN @ U< WHILE
    MH-I @ 15 AND 0= IF S"   " MH-EMIT-S THEN
    S" 0x" MH-EMIT-S
    MH-BUF @ MH-I @ + C@ MH-EMIT-HEX2
    S" ," MH-EMIT-S
    MH-I @ 15 AND 15 = IF MH-EMIT-NL ELSE S" " MH-EMIT-S THEN
    1 MH-I +!
  REPEAT
  MH-EMIT-NL
  S" };" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  S" #define TCOM_CODE_LEN ((uint32_t)sizeof(tcom_code))" MH-EMIT-S MH-EMIT-NL
  ;

: MH-EMIT-COMMON-DEFS  ( -- )
  S" #define TCOM_ENTRY " MH-EMIT-S MACHO-ENTRY-T@ MH-EMIT-U MH-EMIT-NL
  S" #define TCOM_PAGE 0x4000u" MH-EMIT-S MH-EMIT-NL
  S" #define TCOM_ARGC_OFF 0u" MH-EMIT-S MH-EMIT-NL
  S" #define TCOM_ARGS_OFF 8u" MH-EMIT-S MH-EMIT-NL
  S" #define TCOM_ARG_STRIDE 256u" MH-EMIT-S MH-EMIT-NL
  S" #define TCOM_MAX_ARGS 16u" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  ;

\ Shared: argv fill + CALL/DATA/HOST fixups + mprotect (inside main, buf/data live)
: MH-EMIT-LOAD-FIXUPS  ( -- )
  S"   /* Layer 2: user argv[1..] as counted strings (max 16 x 255) */" MH-EMIT-S MH-EMIT-NL
  S"   {" MH-EMIT-S MH-EMIT-NL
  S"     int n = argc > 1 ? argc - 1 : 0;" MH-EMIT-S MH-EMIT-NL
  S"     int i;" MH-EMIT-S MH-EMIT-NL
  S"     if (n > (int)TCOM_MAX_ARGS) n = (int)TCOM_MAX_ARGS;" MH-EMIT-S MH-EMIT-NL
  S"     *(uint64_t *)(data + TCOM_ARGC_OFF) = (uint64_t)(uint32_t)n;" MH-EMIT-S MH-EMIT-NL
  S"     for (i = 0; i < n; i++) {" MH-EMIT-S MH-EMIT-NL
  S"       const char *s = argv[i + 1] ? argv[i + 1] : " MH-EMIT-S
  34 MH-EMIT-B 34 MH-EMIT-B S" ;" MH-EMIT-S MH-EMIT-NL
  S"       size_t len = strlen(s);" MH-EMIT-S MH-EMIT-NL
  S"       uint8_t *slot = data + TCOM_ARGS_OFF + (size_t)i * TCOM_ARG_STRIDE;" MH-EMIT-S MH-EMIT-NL
  S"       if (len > 255u) len = 255u;" MH-EMIT-S MH-EMIT-NL
  S"       slot[0] = (uint8_t)len;" MH-EMIT-S MH-EMIT-NL
  S"       if (len) memcpy(slot + 1, s, len);" MH-EMIT-S MH-EMIT-NL
  S"     }" MH-EMIT-S MH-EMIT-NL
  S"   }" MH-EMIT-S MH-EMIT-NL
  [DEFINED] ?INLINE-CALLS [IF]
    ?INLINE-CALLS 0= IF MH-EMIT-FIXUP-C THEN
  [ELSE]
    MH-EMIT-FIXUP-C
  [THEN]
  MH-EMIT-DATA-FIXUP-C
  MH-EMIT-HOST-FIXUP-C
  S"   if (mprotect(buf, code_bytes, 5) != 0) return 126;" MH-EMIT-S MH-EMIT-NL
  S" #if defined(__APPLE__)" MH-EMIT-S MH-EMIT-NL
  S"   sys_icache_invalidate(buf, code_bytes);" MH-EMIT-S MH-EMIT-NL
  S" #endif" MH-EMIT-S MH-EMIT-NL
  ;

: MH-EMIT-RUN-ASM  ( -- )
  S"   void *dsp = buf + total - 64;" MH-EMIT-S MH-EMIT-NL
  S"   void *entry = buf + TCOM_ENTRY;" MH-EMIT-S MH-EMIT-NL
  S"   uint64_t result;" MH-EMIT-S MH-EMIT-NL
  S"   __asm__ volatile(" MH-EMIT-S MH-EMIT-NL
  S"     " MH-EMIT-S 34 MH-EMIT-B S" mov x19, %1" MH-EMIT-S
    92 MH-EMIT-B S" n" MH-EMIT-S 92 MH-EMIT-B S" t" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
  S"     " MH-EMIT-S 34 MH-EMIT-B S" mov x0, xzr" MH-EMIT-S
    92 MH-EMIT-B S" n" MH-EMIT-S 92 MH-EMIT-B S" t" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
  S"     " MH-EMIT-S 34 MH-EMIT-B S" blr %2" MH-EMIT-S
    92 MH-EMIT-B S" n" MH-EMIT-S 92 MH-EMIT-B S" t" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
  S"     " MH-EMIT-S 34 MH-EMIT-B S" mov %0, x0" MH-EMIT-S
    92 MH-EMIT-B S" n" MH-EMIT-S 92 MH-EMIT-B S" t" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
  S"     : " MH-EMIT-S 34 MH-EMIT-B S" =r" MH-EMIT-S 34 MH-EMIT-B
  S" (result) : " MH-EMIT-S 34 MH-EMIT-B S" r" MH-EMIT-S 34 MH-EMIT-B
  S" (dsp), " MH-EMIT-S 34 MH-EMIT-B S" r" MH-EMIT-S 34 MH-EMIT-B S" (entry)" MH-EMIT-S MH-EMIT-NL
  S"     : " MH-EMIT-S 34 MH-EMIT-B S" x0" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x1" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x2" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x3" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x16" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x17" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x19" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" x30" MH-EMIT-S 34 MH-EMIT-B S" ," MH-EMIT-S
  34 MH-EMIT-B S" memory" MH-EMIT-S 34 MH-EMIT-B S" );" MH-EMIT-S MH-EMIT-NL
  ;

: MH-EMIT-CLI-HOST  ( -- )
  S" typedef int64_t (*tcom_host_fn)(int64_t, int64_t);" MH-EMIT-S MH-EMIT-NL
  S" static int tcom_gui_opened = 0;" MH-EMIT-S MH-EMIT-NL
  S" static char tcom_app_name[256] = " MH-EMIT-S 34 MH-EMIT-B S" 64TCOM" MH-EMIT-S 34 MH-EMIT-B S" ;" MH-EMIT-S MH-EMIT-NL
  S" static int64_t tcom_host_window(int64_t a, int64_t b) { (void)a; (void)b; (void)tcom_gui_opened; return -1; }" MH-EMIT-S MH-EMIT-NL
  S" static int64_t tcom_host_app_name(int64_t ca, int64_t u) {" MH-EMIT-S MH-EMIT-NL
  S"   size_t n = (size_t)u; if (n > 255u) n = 255u;" MH-EMIT-S MH-EMIT-NL
  S"   if (!ca || n == 0) { strcpy(tcom_app_name, " MH-EMIT-S 34 MH-EMIT-B S" 64TCOM" MH-EMIT-S 34 MH-EMIT-B S" ); return 0; }" MH-EMIT-S MH-EMIT-NL
  S"   memcpy(tcom_app_name, (const void *)(uintptr_t)ca, n); tcom_app_name[n] = 0; return 0;" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  S" static tcom_host_fn host_fn[] = { tcom_host_window, tcom_host_app_name };" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  ;

: MH-EMIT-GUI-HOST  ( -- )
  S" typedef int64_t (*tcom_host_fn)(int64_t, int64_t);" MH-EMIT-S MH-EMIT-NL
  S" static int tcom_gui_opened = 0;" MH-EMIT-S MH-EMIT-NL
  S" static char tcom_app_name[256] = " MH-EMIT-S 34 MH-EMIT-B S" 64TCOM" MH-EMIT-S 34 MH-EMIT-B S" ;" MH-EMIT-S MH-EMIT-NL
  S" @interface TcomAppDelegate : NSObject <NSApplicationDelegate>" MH-EMIT-S MH-EMIT-NL
  S" @end" MH-EMIT-S MH-EMIT-NL
  S" @implementation TcomAppDelegate" MH-EMIT-S MH-EMIT-NL
  S" - (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {" MH-EMIT-S MH-EMIT-NL
  S"   (void)sender; return YES;" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  S" @end" MH-EMIT-S MH-EMIT-NL
  \ Menubar from tcom_app_name (default 64TCOM) + Quit (Cmd-Q).
  S" static void tcom_install_main_menu(NSApplication *app) {" MH-EMIT-S MH-EMIT-NL
  S"   NSString *name = [NSString stringWithUTF8String:tcom_app_name];" MH-EMIT-S MH-EMIT-NL
  S"   NSString *quit = [@" MH-EMIT-S 34 MH-EMIT-B S" Quit " MH-EMIT-S 34 MH-EMIT-B
  S"  stringByAppendingString:name];" MH-EMIT-S MH-EMIT-NL
  S"   if ([app mainMenu] != nil) {" MH-EMIT-S MH-EMIT-NL
  S"     NSMenuItem *appItem = [[app mainMenu] itemAtIndex:0];" MH-EMIT-S MH-EMIT-NL
  S"     NSMenu *appMenu = [appItem submenu];" MH-EMIT-S MH-EMIT-NL
  S"     [appMenu setTitle:name];" MH-EMIT-S MH-EMIT-NL
  S"     if ([appMenu numberOfItems] > 0) [[appMenu itemAtIndex:0] setTitle:quit];" MH-EMIT-S MH-EMIT-NL
  S"     return;" MH-EMIT-S MH-EMIT-NL
  S"   }" MH-EMIT-S MH-EMIT-NL
  S"   NSMenu *menubar = [NSMenu new];" MH-EMIT-S MH-EMIT-NL
  S"   NSMenuItem *appItem = [NSMenuItem new];" MH-EMIT-S MH-EMIT-NL
  S"   [menubar addItem:appItem];" MH-EMIT-S MH-EMIT-NL
  S"   NSMenu *appMenu = [[NSMenu alloc] initWithTitle:name];" MH-EMIT-S MH-EMIT-NL
  S"   NSMenuItem *quitItem = [[NSMenuItem alloc]" MH-EMIT-S MH-EMIT-NL
  S"     initWithTitle:quit action:@selector(terminate:) keyEquivalent:@" MH-EMIT-S
    34 MH-EMIT-B S" q" MH-EMIT-S 34 MH-EMIT-B S" ];" MH-EMIT-S MH-EMIT-NL
  S"   [quitItem setTarget:app];" MH-EMIT-S MH-EMIT-NL
  S"   [appMenu addItem:quitItem];" MH-EMIT-S MH-EMIT-NL
  S"   [appItem setSubmenu:appMenu];" MH-EMIT-S MH-EMIT-NL
  S"   [app setMainMenu:menubar];" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  S" static int64_t tcom_host_app_name(int64_t ca, int64_t u) {" MH-EMIT-S MH-EMIT-NL
  S"   size_t n = (size_t)u; if (n > 255u) n = 255u;" MH-EMIT-S MH-EMIT-NL
  S"   if (!ca || n == 0) strcpy(tcom_app_name, " MH-EMIT-S 34 MH-EMIT-B S" 64TCOM" MH-EMIT-S 34 MH-EMIT-B S" );" MH-EMIT-S MH-EMIT-NL
  S"   else { memcpy(tcom_app_name, (const void *)(uintptr_t)ca, n); tcom_app_name[n] = 0; }" MH-EMIT-S MH-EMIT-NL
  S"   NSApplication *app = [NSApplication sharedApplication];" MH-EMIT-S MH-EMIT-NL
  S"   if ([app mainMenu] != nil) tcom_install_main_menu(app);" MH-EMIT-S MH-EMIT-NL
  S"   return 0;" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  S" static int64_t tcom_host_window(int64_t a, int64_t b) {" MH-EMIT-S MH-EMIT-NL
  S"   (void)a; (void)b;" MH-EMIT-S MH-EMIT-NL
  S"   NSApplication *app = [NSApplication sharedApplication];" MH-EMIT-S MH-EMIT-NL
  S"   [app setActivationPolicy:NSApplicationActivationPolicyRegular];" MH-EMIT-S MH-EMIT-NL
  S"   static TcomAppDelegate *delegate = nil;" MH-EMIT-S MH-EMIT-NL
  S"   if (!delegate) { delegate = [TcomAppDelegate new]; [app setDelegate:delegate]; }" MH-EMIT-S MH-EMIT-NL
  S"   tcom_install_main_menu(app);" MH-EMIT-S MH-EMIT-NL
  S"   NSRect frame = NSMakeRect(200, 200, 480, 320);" MH-EMIT-S MH-EMIT-NL
  S"   NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |" MH-EMIT-S MH-EMIT-NL
  S"                      NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;" MH-EMIT-S MH-EMIT-NL
  S"   NSWindow *win = [[NSWindow alloc] initWithContentRect:frame" MH-EMIT-S MH-EMIT-NL
  S"     styleMask:style backing:NSBackingStoreBuffered defer:NO];" MH-EMIT-S MH-EMIT-NL
  S"   [win setTitle:[NSString stringWithUTF8String:tcom_app_name]];" MH-EMIT-S MH-EMIT-NL
  S"   [win makeKeyAndOrderFront:nil];" MH-EMIT-S MH-EMIT-NL
  S"   [app activateIgnoringOtherApps:YES];" MH-EMIT-S MH-EMIT-NL
  S"   tcom_gui_opened = 1;" MH-EMIT-S MH-EMIT-NL
  S"   return 0;" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  S" static tcom_host_fn host_fn[] = { tcom_host_window, tcom_host_app_name };" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  ;

: MH-WRITE-C-BODY  ( -- )
  S" /* Generated by 64TCOM MACHOARM64 — public domain */" MH-EMIT-S MH-EMIT-NL
  S" #include <stdint.h>" MH-EMIT-S MH-EMIT-NL
  S" #include <string.h>" MH-EMIT-S MH-EMIT-NL
  S" #include <sys/mman.h>" MH-EMIT-S MH-EMIT-NL
  S" #if defined(__APPLE__)" MH-EMIT-S MH-EMIT-NL
  S" #include <libkern/OSCacheControl.h>" MH-EMIT-S MH-EMIT-NL
  S" #endif" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  MH-EMIT-CODE-ARRAY
  MH-EMIT-DATA-ARRAY
  MH-EMIT-COMMON-DEFS
  MH-EMIT-CLI-HOST
  S" int main(int argc, char **argv) {" MH-EMIT-S MH-EMIT-NL
  S"   uint32_t code_bytes = (TCOM_CODE_LEN + TCOM_PAGE - 1u) & ~(TCOM_PAGE - 1u);" MH-EMIT-S MH-EMIT-NL
  S"   uint32_t total = code_bytes + TCOM_PAGE;" MH-EMIT-S MH-EMIT-NL
  S"   uint8_t *buf = (uint8_t *)mmap(NULL, total, 3, 0x1002, -1, 0);" MH-EMIT-S MH-EMIT-NL
  S"   if (buf == (void *)(uintptr_t)-1) return 127;" MH-EMIT-S MH-EMIT-NL
  S"   memcpy(buf, tcom_code, TCOM_CODE_LEN);" MH-EMIT-S MH-EMIT-NL
  S"   uint8_t *data = buf + code_bytes;" MH-EMIT-S MH-EMIT-NL
  S"   if (TCOM_DATA_LEN > 1u) memcpy(data, tcom_data, TCOM_DATA_LEN);" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-LOAD-FIXUPS
  MH-EMIT-RUN-ASM
  S"   return (int)(result & 255u);" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  ;

: MH-WRITE-GUI-BODY  ( -- )
  S" /* Generated by 64TCOM MACHOARM64 GUI — public domain */" MH-EMIT-S MH-EMIT-NL
  S" #include <stdint.h>" MH-EMIT-S MH-EMIT-NL
  S" #include <string.h>" MH-EMIT-S MH-EMIT-NL
  S" #include <sys/mman.h>" MH-EMIT-S MH-EMIT-NL
  S" #if defined(__APPLE__)" MH-EMIT-S MH-EMIT-NL
  S" #include <libkern/OSCacheControl.h>" MH-EMIT-S MH-EMIT-NL
  S" #import <Cocoa/Cocoa.h>" MH-EMIT-S MH-EMIT-NL
  S" #endif" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-NL
  MH-EMIT-CODE-ARRAY
  MH-EMIT-DATA-ARRAY
  MH-EMIT-COMMON-DEFS
  MH-EMIT-GUI-HOST
  S" int main(int argc, char **argv) {" MH-EMIT-S MH-EMIT-NL
  S"   uint32_t code_bytes = (TCOM_CODE_LEN + TCOM_PAGE - 1u) & ~(TCOM_PAGE - 1u);" MH-EMIT-S MH-EMIT-NL
  S"   uint32_t total = code_bytes + TCOM_PAGE;" MH-EMIT-S MH-EMIT-NL
  S"   uint8_t *buf = (uint8_t *)mmap(NULL, total, 3, 0x1002, -1, 0);" MH-EMIT-S MH-EMIT-NL
  S"   if (buf == (void *)(uintptr_t)-1) return 127;" MH-EMIT-S MH-EMIT-NL
  S"   memcpy(buf, tcom_code, TCOM_CODE_LEN);" MH-EMIT-S MH-EMIT-NL
  S"   uint8_t *data = buf + code_bytes;" MH-EMIT-S MH-EMIT-NL
  S"   if (TCOM_DATA_LEN > 1u) memcpy(data, tcom_data, TCOM_DATA_LEN);" MH-EMIT-S MH-EMIT-NL
  MH-EMIT-LOAD-FIXUPS
  MH-EMIT-RUN-ASM
  S"   if (tcom_gui_opened) {" MH-EMIT-S MH-EMIT-NL
  S"     [NSApp run];" MH-EMIT-S MH-EMIT-NL
  S"     return 0;" MH-EMIT-S MH-EMIT-NL
  S"   }" MH-EMIT-S MH-EMIT-NL
  S"   return (int)(result & 255u);" MH-EMIT-S MH-EMIT-NL
  S" }" MH-EMIT-S MH-EMIT-NL
  ;

CREATE MH-NAME  128 ALLOT

: MH-HOLD-NAME  ( c-addr u -- )
  120 UMIN MH-NAME PLACE
  ;

: MH-WRITE-SH  ( -- )  \ uses MH-NAME leaf — no S" with embedded quotes
  S" #!/bin/sh" MH-EMIT-S MH-EMIT-NL
  S" # Build standalone Mach-O from 64TCOM output" MH-EMIT-S MH-EMIT-NL
  S" set -e" MH-EMIT-S MH-EMIT-NL
  S" NAME=" MH-EMIT-S  34 MH-EMIT-B  MH-NAME COUNT MH-EMIT-S  34 MH-EMIT-B  MH-EMIT-NL
  ?MACHO-GUI IF
    S" cc -arch arm64 -O2 -fobjc-arc -framework AppKit -o " MH-EMIT-S
    34 MH-EMIT-B S" $NAME" MH-EMIT-S 34 MH-EMIT-B
    S"  " MH-EMIT-S
    34 MH-EMIT-B S" $NAME.m" MH-EMIT-S 34 MH-EMIT-B
    MH-EMIT-NL
    \ Minimal .app bundle for Finder double-click (no Terminal)
    S" BIN=$(basename " MH-EMIT-S 34 MH-EMIT-B S" $NAME" MH-EMIT-S 34 MH-EMIT-B S" )" MH-EMIT-S MH-EMIT-NL
    S" APP=" MH-EMIT-S 34 MH-EMIT-B S" $NAME.app" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S" rm -rf " MH-EMIT-S 34 MH-EMIT-B S" $APP" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S" mkdir -p " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/MacOS" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S" cp " MH-EMIT-S 34 MH-EMIT-B S" $NAME" MH-EMIT-S 34 MH-EMIT-B S"  " MH-EMIT-S
      34 MH-EMIT-B S" $APP/Contents/MacOS/$BIN" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S" chmod +x " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/MacOS/$BIN" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S" cat > " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/Info.plist" MH-EMIT-S 34 MH-EMIT-B S" <<EOF" MH-EMIT-S MH-EMIT-NL
    S" <?xml version=" MH-EMIT-S 34 MH-EMIT-B S" 1.0" MH-EMIT-S 34 MH-EMIT-B
      S"  encoding=" MH-EMIT-S 34 MH-EMIT-B S" UTF-8" MH-EMIT-S 34 MH-EMIT-B S" ?>" MH-EMIT-S MH-EMIT-NL
    S" <!DOCTYPE plist PUBLIC " MH-EMIT-S
      34 MH-EMIT-B S" -//Apple//DTD PLIST 1.0//EN" MH-EMIT-S 34 MH-EMIT-B S"  " MH-EMIT-S
      34 MH-EMIT-B S" http://www.apple.com/DTDs/PropertyList-1.0.dtd" MH-EMIT-S 34 MH-EMIT-B S" >" MH-EMIT-S MH-EMIT-NL
    S" <plist version=" MH-EMIT-S 34 MH-EMIT-B S" 1.0" MH-EMIT-S 34 MH-EMIT-B S" >" MH-EMIT-S MH-EMIT-NL
    S" <dict>" MH-EMIT-S MH-EMIT-NL
    S"   <key>CFBundleExecutable</key><string>$BIN</string>" MH-EMIT-S MH-EMIT-NL
    S"   <key>CFBundleIdentifier</key><string>com.win32forth.64tcom.$BIN</string>" MH-EMIT-S MH-EMIT-NL
    S"   <key>CFBundleName</key><string>$BIN</string>" MH-EMIT-S MH-EMIT-NL
    S"   <key>CFBundlePackageType</key><string>APPL</string>" MH-EMIT-S MH-EMIT-NL
    S"   <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>" MH-EMIT-S MH-EMIT-NL
    S"   <key>CFBundleShortVersionString</key><string>0.3</string>" MH-EMIT-S MH-EMIT-NL
    S"   <key>NSHighResolutionCapable</key><true/>" MH-EMIT-S MH-EMIT-NL
    S"   <key>NSPrincipalClass</key><string>NSApplication</string>" MH-EMIT-S MH-EMIT-NL
    S" </dict>" MH-EMIT-S MH-EMIT-NL
    S" </plist>" MH-EMIT-S MH-EMIT-NL
    S" EOF" MH-EMIT-S MH-EMIT-NL
    \ Optional icon: drop NAME.png (ideally 1024x1024) beside the .tfth / output.
    \ Build converts PNG → .icns into Contents/Resources and sets CFBundleIconFile.
    S" if [ -f " MH-EMIT-S 34 MH-EMIT-B S" $NAME.png" MH-EMIT-S 34 MH-EMIT-B S"  ]; then" MH-EMIT-S MH-EMIT-NL
    S"   mkdir -p " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/Resources" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   ICONSET=" MH-EMIT-S 34 MH-EMIT-B S" $NAME.iconset" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   rm -rf " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   mkdir -p " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   PNG=" MH-EMIT-S 34 MH-EMIT-B S" $NAME.png" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   sips -z 16 16     " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_16x16.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 32 32     " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_16x16@2x.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 32 32     " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_32x32.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 64 64     " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_32x32@2x.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 128 128   " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_128x128.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 256 256   " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_128x128@2x.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 256 256   " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_256x256.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 512 512   " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_256x256@2x.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 512 512   " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_512x512.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   sips -z 1024 1024 " MH-EMIT-S 34 MH-EMIT-B S" $PNG" MH-EMIT-S 34 MH-EMIT-B S"  --out " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET/icon_512x512@2x.png" MH-EMIT-S 34 MH-EMIT-B S"  >/dev/null" MH-EMIT-S MH-EMIT-NL
    S"   iconutil -c icns " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET" MH-EMIT-S 34 MH-EMIT-B S"  -o " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/Resources/$BIN.icns" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   rm -rf " MH-EMIT-S 34 MH-EMIT-B S" $ICONSET" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   /usr/libexec/PlistBuddy -c " MH-EMIT-S 34 MH-EMIT-B S" Add :CFBundleIconFile string $BIN" MH-EMIT-S 34 MH-EMIT-B
      S"  " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/Info.plist" MH-EMIT-S 34 MH-EMIT-B
      S"  >/dev/null 2>&1 || /usr/libexec/PlistBuddy -c " MH-EMIT-S 34 MH-EMIT-B S" Set :CFBundleIconFile $BIN" MH-EMIT-S 34 MH-EMIT-B
      S"  " MH-EMIT-S 34 MH-EMIT-B S" $APP/Contents/Info.plist" MH-EMIT-S 34 MH-EMIT-B MH-EMIT-NL
    S"   echo Icon: ./$NAME.png → $APP/Contents/Resources/$BIN.icns" MH-EMIT-S MH-EMIT-NL
    S" fi" MH-EMIT-S MH-EMIT-NL
    S" codesign --force -s - " MH-EMIT-S 34 MH-EMIT-B S" $APP" MH-EMIT-S 34 MH-EMIT-B
      S"  >/dev/null 2>&1 || true" MH-EMIT-S MH-EMIT-NL
    S" echo Built ./$NAME and ./$APP" MH-EMIT-S MH-EMIT-NL
    S" echo Run: ./$NAME   or   open ./$APP   #(Finder double-click OK)" MH-EMIT-S MH-EMIT-NL
  ELSE
    S" cc -arch arm64 -O2 -o " MH-EMIT-S
    34 MH-EMIT-B S" $NAME" MH-EMIT-S 34 MH-EMIT-B
    S"  " MH-EMIT-S
    34 MH-EMIT-B S" $NAME.c" MH-EMIT-S 34 MH-EMIT-B
    MH-EMIT-NL
    S" echo Built ./$NAME" MH-EMIT-S MH-EMIT-NL
    S" echo Run: ./$NAME then check exit status" MH-EMIT-S MH-EMIT-NL
  THEN
  ;

: MH-MAKE-C-NAME  ( -- c-addr u )
  MH-NAME C@ MH-OFF !
  0 MH-I !
  BEGIN MH-I @ MH-OFF @ < WHILE
    MH-NAME 1 + MH-I @ + C@  PAD MH-I @ + C!
    1 MH-I +!
  REPEAT
  [CHAR] . PAD MH-OFF @ + C!
  ?MACHO-GUI IF
    [CHAR] m PAD MH-OFF @ + 1 + C!
  ELSE
    [CHAR] c PAD MH-OFF @ + 1 + C!
  THEN
  PAD  MH-OFF @ 2 +
  ;

: MH-MAKE-SH-NAME  ( -- c-addr u )
  MH-NAME C@ MH-OFF !
  0 MH-I !
  BEGIN MH-I @ MH-OFF @ < WHILE
    MH-NAME 1 + MH-I @ + C@  PAD MH-I @ + C!
    1 MH-I +!
  REPEAT
  \ append -build.sh (9 chars)
  [CHAR] - PAD MH-OFF @ + C!
  [CHAR] b PAD MH-OFF @ + 1 + C!
  [CHAR] u PAD MH-OFF @ + 2 + C!
  [CHAR] i PAD MH-OFF @ + 3 + C!
  [CHAR] l PAD MH-OFF @ + 4 + C!
  [CHAR] d PAD MH-OFF @ + 5 + C!
  [CHAR] . PAD MH-OFF @ + 6 + C!
  [CHAR] s PAD MH-OFF @ + 7 + C!
  [CHAR] h PAD MH-OFF @ + 8 + C!
  PAD  MH-OFF @ 9 +
  ;

\ Build "sh NAME-build.sh" on PAD for SYSTEM (no embedded S" quotes).
: MH-MAKE-SYS-CMD  ( -- c-addr u )
  [CHAR] s PAD C!
  [CHAR] h PAD 1 + C!
  BL        PAD 2 + C!
  3 MH-OFF !
  0 MH-I !
  BEGIN MH-I @ MH-NAME C@ < WHILE
    MH-NAME 1 + MH-I @ + C@  PAD MH-OFF @ + C!
    1 MH-OFF +!
    1 MH-I +!
  REPEAT
  [CHAR] - PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] b PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] u PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] i PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] l PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] d PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] . PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] s PAD MH-OFF @ + C!  1 MH-OFF +!
  [CHAR] h PAD MH-OFF @ + C!  1 MH-OFF +!
  PAD MH-OFF @
  ;

VARIABLE MH-SYS-N

: MH-RUN-BUILD  ( -- )
  [DEFINED] SYSTEM [IF]
    ?MACHO-BUILD IF
      MH-MAKE-SYS-CMD
      ?QUIET 0= IF
        S" MACHO: SYSTEM " TYPE 2DUP TYPE CR
      THEN
      SYSTEM MH-SYS-N !
      ?QUIET 0= IF
        MH-SYS-N @ 0= IF
          S" MACHO: built ./" TYPE MH-NAME COUNT TYPE
          S"  (cc exit 0)" TYPE CR
          S"   Run:  ./" TYPE MH-NAME COUNT TYPE
          S"  ; echo $?" TYPE CR
        ELSE
          S" MACHO: build failed (SYSTEM exit " TYPE
          MH-SYS-N @ 0 .R S" )" TYPE CR
        THEN
      THEN
    ELSE
      ?QUIET 0= IF
        S" MACHO: skip build (/NOMACHO-BUILD). Manual:" TYPE CR
        S"   sh " TYPE MH-NAME COUNT TYPE S" -build.sh" TYPE CR
      THEN
    THEN
  [ELSE]
    ?QUIET 0= IF
      S" MACHO: no SYSTEM (need 64Forth 1.0.5+). Manual:" TYPE CR
      S"   sh " TYPE MH-NAME COUNT TYPE S" -build.sh" TYPE CR
    THEN
  [THEN]
  ;

: SAVE-MACHO-AS  ( c-addr u -- )
  HERE-T 0= IF
    S" MACHO: empty CODE — compile something first" TYPE CR
    2DROP EXIT
  THEN
  MH-HOLD-NAME
  MH-COPY-IMAGE
  MH-REWRITE-CALLS
  MH-MAKE-C-NAME
  W/O CREATE-FILE IF
    DROP
    S" MACHO: CREATE-FILE source failed" TYPE CR
    MH-FREE EXIT
  THEN
  MH-FID !
  ?MACHO-GUI IF MH-WRITE-GUI-BODY ELSE MH-WRITE-C-BODY THEN
  MH-FID @ CLOSE-FILE DROP
  MH-MAKE-SH-NAME
  W/O CREATE-FILE IF
    DROP
    S" MACHO: CREATE-FILE build.sh failed" TYPE CR
    MH-FREE EXIT
  THEN
  MH-FID !
  MH-WRITE-SH
  MH-FID @ CLOSE-FILE DROP
  ?QUIET 0= IF
    S" MACHO: wrote " TYPE MH-NAME COUNT TYPE
    ?MACHO-GUI IF S" .m  (" ELSE S" .c  (" THEN TYPE
    MH-LEN @ 0 .R S"  code bytes, " TYPE
    MH-N @ 0 .R
    [DEFINED] ?INLINE-CALLS [IF]
      ?INLINE-CALLS IF
        S"  calls inlined)" TYPE CR
      ELSE
        S"  calls; C fixup true BLR)" TYPE CR
      THEN
    [ELSE]
      S"  calls; C fixup true BLR)" TYPE CR
    [THEN]
    ?MACHO-GUI IF S"        GUI AppKit shell" TYPE CR THEN
    S"        " TYPE MH-NAME COUNT TYPE S" -build.sh" TYPE CR
    S"   Entry taddr=" TYPE MACHO-ENTRY-T@ . CR
  THEN
  MH-RUN-BUILD
  MH-FREE
  ;

: SAVE-MACHO-FILE  ( -- )
  MACHO-FILENAME COUNT SAVE-MACHO-AS
  ;

: .MACHOARM64  ( -- )
  S" MACHOARM64: SAVE-MACHO-FILE / SAVE-MACHO-AS  /MACHO" TYPE CR
  S"   Phase 3.5: true BLR via C fixup (default); /INLINE-CALLS = paste leaves" TYPE CR
  S"   Emits NAME.c|.m + NAME-build.sh; auto-cc via SYSTEM if ?MACHO-BUILD" TYPE CR
  S"   /MACHO-BUILD (default)  /NOMACHO-BUILD  (emit sources only)" TYPE CR
  S"   /MACHO-GUI  → AppKit .m + .app (TCOM primary; TCOM-CLI is CLI)" TYPE CR
  S"   Entry: use  S" TYPE 34 EMIT S" ANS" TYPE 34 EMIT
  S"  MACHO-ENTRY-SET  or MACHO-ENTRY-COLD" TYPE CR
  S"   Requires 64Forth 1.0.5+ for SYSTEM auto-build" TYPE CR
  ;

FORTH DEFINITIONS
S" MACHOARM64 loaded (C→Mach-O; Phase 3.5 true BLR; SYSTEM auto-build)." TYPE CR
