\ NATARM64.fth — Native BLR of compiled A64 (64Forth 1.0.4+)
\
\ Public domain.
\
\ Strategy (Apple Silicon, no MAP_JIT):
\   T-CODE-BASE = malloc (safe compile).
\   RUN-NATIVE:
\     1) ALLOCATE-EXEC  — mmap RW (not malloc, not MAP_JIT)
\     2) copy image + fix absolute .quad pointers
\     3) MPROTECT R+X (prot 5)  — needs allow-unsigned-executable-memory
\     4) ICACHE-INVAL
\     5) CALL-NATIVE
\     6) FREE-EXEC
\
\ First check:  NATIVE-SMOKE  → 0 means kernel BLR path works.
\
\ ABI: X0 = TOS, X19 = DSP.

TCOM-ANEW NATARM64

FORTH DEFINITIONS
DECIMAL

VARIABLE NAT-IOR
VARIABLE NAT-EXEC
VARIABLE NAT-OLD
VARIABLE NAT-LEN
VARIABLE NAT-DELTA
VARIABLE NAT-I
VARIABLE NAT-TADDR
VARIABLE NAT-DSP
VARIABLE NAT-X0
VARIABLE NAT-RES
VARIABLE NAT-ALLOC  \ rounded allocation size for FREE-EXEC

0 NAT-IOR !
0 NAT-EXEC !

5 CONSTANT PROT-RX   \ PROT_READ|PROT_EXEC for MPROTECT

[DEFINED] CALL-NATIVE [IF]

: NATIVE-KERNEL?  ( -- f )  TRUE ;

: (NAT-PAGE-UP)  ( u -- u' )
  4095 + 4095 INVERT AND
  ;

: (NAT-RELOC)  ( -- )
  T-CODE-BASE NAT-OLD !
  HERE-T NAT-LEN !
  0 NAT-I !
  BEGIN NAT-I @ NAT-LEN @ U< WHILE
    NAT-OLD @ NAT-I @ + C@
    NAT-EXEC @ NAT-I @ + C!
    1 NAT-I +!
  REPEAT
  NAT-EXEC @ NAT-OLD @ - NAT-DELTA !
  \ CALL-ABS stores .quad on a 4-byte boundary (after LDR/BLR/B), NOT
  \ always 8-byte aligned — step by 4 or we miss PLUS# and BLR to malloc.
  0 NAT-I !
  BEGIN NAT-I @ NAT-LEN @ 8 - U< WHILE
    NAT-EXEC @ NAT-I @ + @
    DUP NAT-OLD @ U>=
    OVER NAT-OLD @ NAT-LEN @ + U< AND IF
      NAT-DELTA @ +
      NAT-EXEC @ NAT-I @ + !
    ELSE
      DROP
    THEN
    4 NAT-I +!
  REPEAT
  ;

: CODE-MAKE-EXEC  ( -- ior )
  T-CODE-BASE 0= IF  -1 NAT-IOR !  NAT-IOR @ EXIT  THEN
  HERE-T 0= IF  -1 NAT-IOR !  NAT-IOR @ EXIT  THEN
  [DEFINED] ALLOCATE-EXEC [IF]
    0 NAT-IOR !  0
  [ELSE]
    -1 NAT-IOR !  -1
  [THEN]
  ;

: CODE-MAKE-EXEC?  ( -- )
  CODE-MAKE-EXEC
  IF  S" CODE-MAKE-EXEC: not ready" TYPE CR
  ELSE  ?QUIET 0= IF S" CODE-MAKE-EXEC: OK (mmap RW + mprotect RX at run)" TYPE CR THEN
  THEN
  ;

: RUN-NATIVE  ( taddr -- x0' )
  NAT-TADDR !
  [DEFINED] ALLOCATE-EXEC [IF]
    HERE-T (NAT-PAGE-UP) DUP NAT-ALLOC !
    ALLOCATE-EXEC                            \ a ior
    IF
      DROP
      S" RUN-NATIVE: ALLOCATE-EXEC (mmap RW) failed" TYPE CR
      0 EXIT
    THEN
    NAT-EXEC !
    (NAT-RELOC)
    \ Drop WRITE, enable EXEC (cannot be both on AS for reliable path)
    NAT-EXEC @ NAT-ALLOC @ PROT-RX MPROTECT
    DUP NAT-IOR !
    IF
      S" RUN-NATIVE: MPROTECT R+X failed ior=" TYPE NAT-IOR @ . CR
      NAT-EXEC @ NAT-ALLOC @ FREE-EXEC DROP
      0 NAT-EXEC !
      0 EXIT
    THEN
    NAT-EXEC @ NAT-ALLOC @ ICACHE-INVAL
    0 NAT-X0 !
    T-DATA-BASE T-DATA-MAX + 64 - NAT-DSP !
    NAT-X0 @
    NAT-DSP @
    NAT-EXEC @ NAT-TADDR @ +
    CALL-NATIVE
    NAT-RES !
    NAT-EXEC @ NAT-ALLOC @ FREE-EXEC DROP
    0 NAT-EXEC !
    NAT-RES @
  [ELSE]
    S" RUN-NATIVE: no ALLOCATE-EXEC" TYPE CR
    0
  [THEN]
  ;

: RUN-SYM-N  ( c-addr u -- x0 )  SYM-FIND-IX SYM-ADDR@ RUN-NATIVE ;
: RUN-ANS-N  ( -- x0 )  S" ANS" RUN-SYM-N ;

: .RUN-ANS-N  ( -- )
  [DEFINED] NATIVE-SMOKE [IF]
    NATIVE-SMOKE
    IF
      S" .RUN-ANS-N: NATIVE-SMOKE failed — entitlements/mprotect RX broken" TYPE CR
      EXIT
    THEN
    ?QUIET 0= IF S" NATIVE-SMOKE: OK" TYPE CR THEN
  [THEN]
  CODE-MAKE-EXEC
  IF
    S" .RUN-ANS-N: CODE-MAKE-EXEC failed" TYPE CR
    EXIT
  THEN
  RUN-ANS-N
  S" RUN-ANS-N => " TYPE DUP . CR
  5 <> IF
    S" RUN-ANS-N fail: expected 5" TYPE CR
    ABORT
  THEN
  S" RUN-ANS-N: OK (native)" TYPE CR
  ;

: .NATARM64  ( -- )
  S" NATARM64: mmap RW copy → MPROTECT R+X → CALL-NATIVE" TYPE CR
  S"   Try: NATIVE-SMOKE .  (want 0)   then ARM64-DEMO .RUN-ANS-N" TYPE CR
  ;

[ELSE]

: NATIVE-KERNEL?  ( -- f )  FALSE ;
: CODE-MAKE-EXEC  ( -- ior )  -1 ;
: CODE-MAKE-EXEC?  ( -- )  S" need CALL-NATIVE" TYPE CR ;
: RUN-NATIVE  ( taddr -- x0 )  DROP 0 ;
: RUN-SYM-N  ( c-addr u -- x0 )  2DROP 0 ;
: RUN-ANS-N  ( -- x0 )  0 ;
: .RUN-ANS-N  ( -- )  S" need CALL-NATIVE kernel" TYPE CR ;
: .NATARM64  ( -- )  S" NATARM64: stub" TYPE CR ;

[THEN]

FORTH DEFINITIONS
[DEFINED] CALL-NATIVE [IF]
S" NATARM64 loaded (mmap RW + mprotect RX)." TYPE CR
[ELSE]
S" NATARM64 loaded (stub)." TYPE CR
[THEN]
