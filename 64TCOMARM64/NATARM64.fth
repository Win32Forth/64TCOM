\ NATARM64.fth — Native run of compiled A64 (64Forth 1.0.4+)
\
\ Public domain. Phase 3.5: true BLR by default.
\
\ Path:
\   1) mmap RW buffer = page-round(HERE) code + 1 DSP page
\   2) byte-copy image from T-CODE-BASE
\   3) default: fixup each CALL-ABS .quad  offset → (base + taddr)
\      optional /INLINE-CALLS: paste leaf body over call site (old 3.3)
\   4) mprotect code pages RX; DSP page stays RW
\   5) CALL-NATIVE ( 0  dsp  entry )
\
\ SIM keeps LDR/BLR/.quad(taddr). Image in T-CODE stays offsets.

TCOM-ANEW NATARM64

FORTH DEFINITIONS
DECIMAL

\ Default: true BLR (Phase 3.5). /INLINE-CALLS restores 3.3 paste path.
FALSE VALUE ?INLINE-CALLS
: /INLINE-CALLS    ( -- )  TRUE  TO ?INLINE-CALLS ;
: /NOINLINE-CALLS  ( -- )  FALSE TO ?INLINE-CALLS ;

VARIABLE NAT-IOR
VARIABLE NAT-EXEC
VARIABLE NAT-LEN
VARIABLE NAT-TADDR
VARIABLE NAT-RES
VARIABLE NAT-ALLOC
VARIABLE NAT-CODE-BYTES
VARIABLE NAT-DSP
VARIABLE NAT-ENTRY
VARIABLE NAT-A
VARIABLE NAT-P
VARIABLE NAT-T
VARIABLE NAT-N
VARIABLE NAT-I
VARIABLE NAT-W
VARIABLE NAT-SRC
VARIABLE NAT-DST

0 NAT-IOR !
0 NAT-EXEC !

16384 CONSTANT HOST-PAGE
5 CONSTANT PROT-RX

$D63F0200 CONSTANT (A64-BLR-X16)
$D61F0200 CONSTANT (A64-BR-X16)
$14000003 CONSTANT (A64-B+3)          \ skip .quad (new after LDP, and old layout)
$A9BF7FFE CONSTANT (A64-STP-LR)       \ STP X30,XZR,[SP,#-16]!
$A8C17FFE CONSTANT (A64-LDP-LR)       \ LDP X30,XZR,[SP],#16
$D503201F CONSTANT (A64-NOP)
$D65F03C0 CONSTANT (A64-RET)

[DEFINED] CALL-NATIVE [IF]

: NATIVE-KERNEL?  ( -- f )  TRUE ;

: (NAT-PAGE-UP)  ( u -- u' )
  HOST-PAGE 1- +  HOST-PAGE 1- INVERT AND
  ;

: (NAT-W@)  ( addr -- u32 )
  DUP C@
  OVER 1 + C@ 8 LSHIFT OR
  OVER 2 + C@ 16 LSHIFT OR
  SWAP 3 + C@ 24 LSHIFT OR
  ;

: (NAT-W!)  ( u32 addr -- )
  OVER $FF AND OVER C!
  OVER 8 RSHIFT $FF AND OVER 1 + C!
  OVER 16 RSHIFT $FF AND OVER 2 + C!
  SWAP 24 RSHIFT $FF AND SWAP 3 + C!
  ;

: (NAT-CLEAR)  ( -- )
  BEGIN DEPTH 0> WHILE DROP REPEAT
  ;

: (NAT-COPY)  ( -- )
  HERE-T NAT-LEN !
  0 NAT-A !
  BEGIN NAT-A @ NAT-LEN @ U< WHILE
    T-CODE-BASE NAT-A @ + C@
    NAT-EXEC @ NAT-A @ + C!
    1 NAT-A +!
  REPEAT
  ;

\ Recognize CALL-ABS site; leave NAT-P = host addr of .quad, NAT-T = taddr
\ New (3.5 LR-save): STP; LDR; BLR; LDP; B+3; .quad   (.quad at +20)
\ Old (3.3):          LDR; BLR; B+3; .quad             (.quad at +12)
: (NAT-FIND-CALL)  ( host-addr -- f )
  NAT-P !
  \ New pattern: BLR at +8, LDP at +12, B+3 at +16
  NAT-P @ 8 + (NAT-W@) (A64-BLR-X16) = IF
    NAT-P @ 12 + (NAT-W@) (A64-LDP-LR) = IF
      NAT-P @ 16 + (NAT-W@) (A64-B+3) = IF
        NAT-P @ 20 + @ NAT-T !
        NAT-P @ 20 + NAT-P !       \ NAT-P → .quad host addr
        TRUE EXIT
      THEN
    THEN
  THEN
  \ Old pattern: BLR at +4, B+3 at +8 (no LR save)
  NAT-P @ 4 + (NAT-W@) DUP (A64-BLR-X16) = SWAP (A64-BR-X16) = OR IF
    NAT-P @ 8 + (NAT-W@) (A64-B+3) = IF
      NAT-P @ 12 + @ NAT-T !
      NAT-P @ 12 + NAT-P !
      TRUE EXIT
    THEN
  THEN
  FALSE
  ;

\ Phase 3.5: .quad holds taddr offset → store absolute host address
: (NAT-FIXUP-CALLS)  ( -- )
  0 NAT-N !
  0 NAT-A !
  BEGIN NAT-A @ NAT-LEN @ 28 - U< WHILE
    NAT-EXEC @ NAT-A @ + (NAT-FIND-CALL) IF
      NAT-T @ NAT-LEN @ U< IF
        NAT-EXEC @ NAT-T @ +  NAT-P @ !
        1 NAT-N +!
      THEN
    THEN
    4 NAT-A +!
  REPEAT
  ;

\ Optional fallback: inline callee body (until RET, max 7 slots) at call start
: (NAT-INLINE-ONE)  ( dst-host taddr -- )
  NAT-T !  NAT-DST !
  NAT-EXEC @ NAT-T @ + NAT-SRC !
  0 NAT-I !
  BEGIN NAT-I @ 7 < WHILE
    NAT-SRC @ NAT-I @ 4 * + (NAT-W@) NAT-W !
    NAT-W @ NAT-DST @ NAT-I @ 4 * + (NAT-W!)
    NAT-W @ (A64-RET) = IF
      1 NAT-I +!
      BEGIN NAT-I @ 7 < WHILE
        (A64-NOP) NAT-DST @ NAT-I @ 4 * + (NAT-W!)
        1 NAT-I +!
      REPEAT
      EXIT
    THEN
    1 NAT-I +!
  REPEAT
  ;

: (NAT-INLINE-CALLS)  ( -- )
  0 NAT-N !
  0 NAT-A !
  BEGIN NAT-A @ NAT-LEN @ 28 - U< WHILE
    NAT-EXEC @ NAT-A @ + DUP NAT-DST !
    (NAT-FIND-CALL) IF
      NAT-T @ NAT-LEN @ U< IF
        NAT-DST @ NAT-T @ (NAT-INLINE-ONE)
        1 NAT-N +!
      THEN
    THEN
    4 NAT-A +!
  REPEAT
  ;

: (NAT-RELOC)  ( -- )
  ?INLINE-CALLS IF
    (NAT-INLINE-CALLS)
  ELSE
    (NAT-FIXUP-CALLS)
  THEN
  ;

: (NAT-CLEANUP)  ( -- )
  NAT-EXEC @ IF
    NAT-EXEC @ NAT-ALLOC @ FREE-EXEC DROP
    0 NAT-EXEC !
  THEN
  ;

: (NAT-PREP-RX)  ( -- )
  (NAT-CLEAR)
  NAT-EXEC @ NAT-CODE-BYTES @ PROT-RX MPROTECT
  IF TRUE NAT-IOR ! EXIT THEN
  0 NAT-IOR !
  0 NAT-A !
  BEGIN NAT-A @ NAT-LEN @ U< WHILE
    NAT-EXEC @ NAT-A @ + C@ DROP
    4 NAT-A +!
  REPEAT
  (NAT-CLEAR)
  NAT-EXEC @ NAT-CODE-BYTES @ ICACHE-INVAL
  (NAT-CLEAR)
  ;

: (NAT-GO)  ( -- x0' )
  (NAT-CLEAR)
  0 NAT-DSP @ NAT-ENTRY @ CALL-NATIVE
  ;

: RUN-NATIVE  ( taddr -- x0' )
  NAT-TADDR !
  (NAT-CLEAR)
  0 NAT-IOR !
  [DEFINED] ALLOCATE-EXEC [IF]
    HERE-T (NAT-PAGE-UP) NAT-CODE-BYTES !
    NAT-CODE-BYTES @ HOST-PAGE + NAT-ALLOC !
    NAT-ALLOC @ ALLOCATE-EXEC
    IF DROP S" RUN-NATIVE: ALLOCATE-EXEC failed" TYPE CR 0 EXIT THEN
    NAT-EXEC !
    NAT-EXEC @ NAT-ALLOC @ + 64 - NAT-DSP !
    (NAT-COPY)
    (NAT-RELOC)
    NAT-EXEC @ NAT-TADDR @ + NAT-ENTRY !

    S" RUN-NATIVE: taddr=" TYPE NAT-TADDR @ .
    S"  entry=" TYPE NAT-ENTRY @ H.
    ?INLINE-CALLS IF
      S"  inlined=" TYPE
    ELSE
      S"  fixed-up=" TYPE
    THEN
    NAT-N @ . CR
    S"   entry insn=" TYPE NAT-ENTRY @ (NAT-W@) H. CR

    (NAT-PREP-RX)
    NAT-IOR @ IF
      S" RUN-NATIVE: mprotect RX failed" TYPE CR
      (NAT-CLEANUP) 0 EXIT
    THEN

    S" RUN-NATIVE: calling..." TYPE CR
    (NAT-GO)
    NAT-RES !
    S" RUN-NATIVE: returned " TYPE NAT-RES @ . CR
    (NAT-CLEANUP)
    (NAT-CLEAR)
    NAT-RES @
  [ELSE]
    S" RUN-NATIVE: no ALLOCATE-EXEC" TYPE CR
    0
  [THEN]
  ;

: RUN-SYM-N  ( c-addr u -- x0 )  SYM-FIND-IX SYM-ADDR@ RUN-NATIVE ;
: RUN-ANS-N  ( -- x0 )  S" ANS" RUN-SYM-N ;

: .RUN-ANS-N  ( -- )
  (NAT-CLEAR)
  [DEFINED] NATIVE-SMOKE [IF]
    NATIVE-SMOKE IF
      S" .RUN-ANS-N: NATIVE-SMOKE failed" TYPE CR EXIT
    THEN
    DROP
    S" NATIVE-SMOKE: OK" TYPE CR
  [THEN]
  (NAT-CLEAR)
  RUN-ANS-N
  S" RUN-ANS-N => " TYPE DUP . CR
  5 <> IF
    S" RUN-ANS-N fail: expected 5" TYPE CR ABORT
  THEN
  ?INLINE-CALLS IF
    S" RUN-ANS-N: OK (native, inlined)" TYPE CR
  ELSE
    S" RUN-ANS-N: OK (native, true BLR)" TYPE CR
  THEN
  ;

: .NATARM64  ( -- )
  S" NATARM64 Phase 3.5: true BLR default (/NOINLINE-CALLS)" TYPE CR
  S"   /INLINE-CALLS  — paste leaf bodies (old 3.3 path)" TYPE CR
  S"   Fixup: CALL-ABS .quad taddr → base+taddr then BLR" TYPE CR
  ;

[ELSE]

: NATIVE-KERNEL?  ( -- f )  FALSE ;
: RUN-NATIVE  ( taddr -- x0 )  DROP 0 ;
: RUN-SYM-N  ( c-addr u -- x0 )  2DROP 0 ;
: RUN-ANS-N  ( -- x0 )  0 ;
: .RUN-ANS-N  ( -- )  S" need CALL-NATIVE" TYPE CR ;
: .NATARM64  ( -- )  S" NATARM64: stub" TYPE CR ;
: /INLINE-CALLS  ( -- )  ;
: /NOINLINE-CALLS  ( -- )  ;

[THEN]

FORTH DEFINITIONS
[DEFINED] CALL-NATIVE [IF]
S" NATARM64 loaded (Phase 3.5 true BLR; /INLINE-CALLS fallback)." TYPE CR
[ELSE]
S" NATARM64 loaded (stub)." TYPE CR
[THEN]
