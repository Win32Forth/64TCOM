\ NATARM64.fth — Native run of compiled A64 (64Forth 1.0.4+)
\
\ Public domain.
\
\ WORKING path (ANS => 5 verified):
\   1) mmap RW buffer = page-round(HERE) code + 1 DSP page
\   2) byte-copy image from T-CODE-BASE
\   3) rewrite each CALL-ABS site: inline callee until RET (no BL/BLR)
\   4) mprotect code pages RX; DSP page stays RW
\   5) CALL-NATIVE ( 0  dsp  entry )
\
\ SIM keeps LDR/BLR/.quad(taddr). True native BL/BLR is future work.

TCOM-ANEW NATARM64

FORTH DEFINITIONS
DECIMAL

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
$14000003 CONSTANT (A64-B+3)
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

\ Inline callee body (until RET, max 5 insns) over 20-byte call site
: (NAT-INLINE-ONE)  ( dst-host taddr -- )
  NAT-T !  NAT-DST !
  NAT-EXEC @ NAT-T @ + NAT-SRC !
  0 NAT-I !
  BEGIN NAT-I @ 5 < WHILE
    NAT-SRC @ NAT-I @ 4 * + (NAT-W@) NAT-W !
    NAT-W @ NAT-DST @ NAT-I @ 4 * + (NAT-W!)
    NAT-W @ (A64-RET) = IF
      1 NAT-I +!
      BEGIN NAT-I @ 5 < WHILE
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
  BEGIN NAT-A @ NAT-LEN @ 20 - U< WHILE
    NAT-EXEC @ NAT-A @ + NAT-P !
    NAT-P @ 4 + (NAT-W@) DUP (A64-BLR-X16) = SWAP (A64-BR-X16) = OR IF
      NAT-P @ 8 + (NAT-W@) (A64-B+3) = IF
        NAT-P @ 12 + @ NAT-T !
        NAT-T @ NAT-LEN @ U< IF
          NAT-P @ NAT-T @ (NAT-INLINE-ONE)
          1 NAT-N +!
        THEN
      THEN
    THEN
    4 NAT-A +!
  REPEAT
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
    (NAT-INLINE-CALLS)
    NAT-EXEC @ NAT-TADDR @ + NAT-ENTRY !

    S" RUN-NATIVE: taddr=" TYPE NAT-TADDR @ .
    S"  entry=" TYPE NAT-ENTRY @ H.
    S"  inlined=" TYPE NAT-N @ . CR
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
  S" RUN-ANS-N: OK (native)" TYPE CR
  ;

: .NATARM64  ( -- )
  S" NATARM64: inline callees for native (no BL/BLR)" TYPE CR
  ;

[ELSE]

: NATIVE-KERNEL?  ( -- f )  FALSE ;
: RUN-NATIVE  ( taddr -- x0 )  DROP 0 ;
: RUN-SYM-N  ( c-addr u -- x0 )  2DROP 0 ;
: RUN-ANS-N  ( -- x0 )  0 ;
: .RUN-ANS-N  ( -- )  S" need CALL-NATIVE" TYPE CR ;
: .NATARM64  ( -- )  S" NATARM64: stub" TYPE CR ;

[THEN]

FORTH DEFINITIONS
[DEFINED] CALL-NATIVE [IF]
S" NATARM64 loaded (inline callees)." TYPE CR
[ELSE]
S" NATARM64 loaded (stub)." TYPE CR
[THEN]
