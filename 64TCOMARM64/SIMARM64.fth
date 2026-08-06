\ SIMARM64.fth — Host-safe run of our A64 subset
\
\ Public domain. Requires pack image in T-CODE-BASE.
\ Does not BLR into the buffer (would smash 64Forth VM X19–X24).

TCOM-ANEW SIMARM64

FORTH DEFINITIONS
DECIMAL

VARIABLE SIM-PC
VARIABLE SIM-HALT
VARIABLE SIM-STEPS
VARIABLE SIM-MAX
VARIABLE SIM-Z          \ last SUBS/ADDS zero flag (true = Z set)
100000 SIM-MAX !

CREATE SIM-X  32 CELLS ALLOT     \ X0..X31 (31 = XZR reads 0 / ignores write)

CREATE SIM-R  64 CELLS ALLOT
VARIABLE SIM-RP

VARIABLE SD
VARIABLE SN
VARIABLE SM

: SIM-R-CLEAR  ( -- )  SIM-R SIM-RP ! ;
: SIM-R-PUSH   ( x -- )
  SIM-RP @ SIM-R 64 CELLS + U>= IF S" SIM R overflow" TCOM-ABORT THEN
  SIM-RP @ !  CELL SIM-RP +!
  ;
: SIM-R-POP    ( -- x )
  SIM-RP @ SIM-R U<= IF S" SIM R underflow" TCOM-ABORT THEN
  CELL NEGATE SIM-RP +!  SIM-RP @ @
  ;
: SIM-R-EMPTY? ( -- f )  SIM-RP @ SIM-R = ;

: SIM-W@  ( taddr -- u32 )
  DUP C@-T
  OVER 1 + C@-T  8 LSHIFT OR
  OVER 2 + C@-T 16 LSHIFT OR
  SWAP 3 + C@-T 24 LSHIFT OR
  ;

: SIM-X!  ( x reg -- )
  $1F AND
  DUP 31 = IF  2DROP EXIT  THEN     \ XZR: ignore write
  CELLS SIM-X + !
  ;

: SIM-X@  ( reg -- x )
  $1F AND
  DUP 31 = IF  DROP 0 EXIT  THEN    \ XZR: read 0
  CELLS SIM-X + @
  ;

: HOST>T  ( host -- taddr )  T-CODE-BASE - TARGET-ORIGIN - ;

: SIM-LOAD64  ( host -- x )
  0  8 0 DO  OVER I + C@  I 8 * LSHIFT OR  LOOP  NIP
  ;

: SIM-STORE64  ( x host -- )
  8 0 DO
    OVER $FF AND OVER C!
    SWAP 8 RSHIFT SWAP 1+
  LOOP 2DROP
  ;

: SIM-INIT  ( -- )
  SIM-X 32 CELLS 0 FILL
  T-DATA-BASE T-DATA-MAX + 64 -  19 SIM-X!
  FALSE SIM-Z !
  SIM-R-CLEAR  0 SIM-STEPS !  FALSE SIM-HALT !
  ;

: SIM-RD    ( insn -- r )  $1F AND ;
: SIM-RN    ( insn -- r )  5 RSHIFT $1F AND ;
: SIM-RM    ( insn -- r )  16 RSHIFT $1F AND ;
: SIM-IMM16 ( insn -- u )  5 RSHIFT $FFFF AND ;
: SIM-HW    ( insn -- u )  21 RSHIFT 3 AND ;
: SIM-IMM9  ( insn -- n )
  12 RSHIFT $1FF AND
  DUP 256 AND IF  512 -  THEN
  ;
: SIM-IMM19 ( insn -- n )
  5 RSHIFT $7FFFF AND
  DUP $40000 AND IF  $80000 -  THEN
  ;
: SIM-IMM26 ( insn -- n )
  \ Sign-extend 26-bit imm to a full cell (64-bit safe).
  \ Old "$FC000000 OR" only extended to 32 bits → bad PC on negative BL/B.
  $3FFFFFF AND
  DUP $2000000 AND IF  $4000000 -  THEN
  ;

: SIM-STEP  ( -- )
  SIM-HALT @ IF EXIT THEN
  1 SIM-STEPS +!
  SIM-STEPS @ SIM-MAX @ > IF
    TRUE SIM-HALT !  S" SIM: step limit" TYPE CR EXIT
  THEN
  SIM-PC @ DUP 0< OVER T-CODE-MAX U>= OR IF
    DROP TRUE SIM-HALT !  S" SIM: bad PC " TYPE SIM-PC @ . CR EXIT
  THEN
  DUP SIM-W@
  SWAP 4 + SIM-PC !
  \ insn on stack; SIM-PC = next sequential

  DUP $D503201F = IF DROP EXIT THEN

  \ BTI / HINT as NOP (D503241F bti, other HINTs in same family)
  DUP $FFFFF01F AND $D503201F = IF DROP EXIT THEN

  \ B imm26
  DUP $FC000000 AND $14000000 = IF
    SIM-IMM26 4 * SIM-PC @ 4 - + SIM-PC !
    DROP EXIT
  THEN

  \ BL imm26  (link = addr after BL = current SIM-PC)
  DUP $FC000000 AND $94000000 = IF
    SIM-PC @ SIM-R-PUSH
    SIM-IMM26 4 * SIM-PC @ 4 - + SIM-PC !
    DROP EXIT
  THEN

  \ B.cond  top byte 0x54; cond in bits 3:0; EQ=0 NE=1
  DUP 24 RSHIFT $FF AND $54 = IF
    DUP $F AND SD !
    SD @ 0 = IF  SIM-Z @  ELSE
    SD @ 1 = IF  SIM-Z @ 0=  ELSE
    SD @ 14 = IF TRUE  ELSE
    FALSE THEN THEN THEN
    IF  SIM-IMM19 4 * SIM-PC @ 4 - + SIM-PC !  THEN
    DROP EXIT
  THEN

  \ RET Xn
  DUP $FFFFFC1F AND $D65F0000 = IF
    DROP
    SIM-R-EMPTY? IF TRUE SIM-HALT ! EXIT THEN
    SIM-R-POP SIM-PC !
    EXIT
  THEN

  \ BR Xn  — X may be host addr (BRANCH#) or taddr (JMP-ABS .quad)
  DUP $FFFFFC1F AND $D61F0000 = IF
    SIM-RN SIM-X@
    DUP T-CODE-BASE U>= IF HOST>T ELSE THEN
    SIM-PC !
    DROP EXIT
  THEN

  \ BLR Xn  — CALL-ABS loads taddr into Xn from .quad; B skips .quad
  DUP $FFFFFC1F AND $D63F0000 = IF
    SIM-PC @ SIM-R-PUSH
    SIM-RN SIM-X@
    DUP T-CODE-BASE U>= IF HOST>T ELSE THEN
    SIM-PC !
    DROP EXIT
  THEN

  \ LDR Xt literal 64
  DUP 24 RSHIFT $FF AND $58 = IF
    DUP SIM-RD SD !
    DUP SIM-IMM19 4 * SIM-PC @ 4 - + @-T
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ MOVZ
  DUP $FF800000 AND $D2800000 = IF
    DUP SIM-RD SD !
    DUP SIM-IMM16
    OVER SIM-HW 16 * LSHIFT
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ MOVK
  DUP $FF800000 AND $F2800000 = IF
    DUP SIM-RD SD !
    DUP SIM-HW 16 * SN !
    DUP SIM-IMM16 SM !
    SD @ SIM-X@
    $FFFF SN @ LSHIFT INVERT AND
    SM @ SN @ LSHIFT OR
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ MOV Xd,Xm
  DUP $FFE0FFE0 AND $AA0003E0 = IF
    DUP SIM-RD SD !
    SIM-RM SIM-X@ SD @ SIM-X!
    DROP EXIT
  THEN

  \ ADD
  DUP $FF200000 AND $8B000000 = IF
    DUP SIM-RD SD !
    DUP SIM-RN SIM-X@ SN !
    SIM-RM SIM-X@ SN @ +
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ SUB  Xd = Xn - Xm
  DUP $FF200000 AND $CB000000 = IF
    DUP SIM-RD SD !
    DUP SIM-RN SIM-X@ SN !
    SN @  SIM-RM SIM-X@  -
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ SUBS (incl CMP)  mask matches EB0xxxxx
  DUP 24 RSHIFT $FF AND $EB = IF
    DUP SIM-RD SD !
    DUP SIM-RN SIM-X@ SN !
    SN @ SIM-RM SIM-X@ -  SM !
    SD @ 31 <> IF  SM @ SD @ SIM-X!  THEN
    SM @ 0= SIM-Z !
    DROP EXIT
  THEN

  \ ADDS
  DUP 24 RSHIFT $FF AND $AB = IF
    DUP SIM-RD SD !
    DUP SIM-RN SIM-X@ SN !
    SN @ SIM-RM SIM-X@ +  SM !
    SD @ 31 <> IF  SM @ SD @ SIM-X!  THEN
    SM @ 0= SIM-Z !
    DROP EXIT
  THEN

  \ ADD imm  91000000
  DUP $FF000000 AND $91000000 = IF
    DUP SIM-RD SD !
    DUP SIM-RN SIM-X@
    SWAP 10 RSHIFT $FFF AND +
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ SUB imm  D1000000
  DUP $FF000000 AND $D1000000 = IF
    DUP SIM-RD SD !
    DUP SIM-RN SIM-X@
    SWAP 10 RSHIFT $FFF AND -
    SD @ SIM-X!
    DROP EXIT
  THEN

  \ STR pre-index
  DUP $FFC00C00 AND $F8000C00 = IF
    DUP SIM-RD SD !
    DUP SIM-RN SN !
    SIM-IMM9 SM !
    SN @ SIM-X@ SM @ +
    DUP SN @ SIM-X!
    SD @ SIM-X@ SWAP SIM-STORE64
    DROP EXIT
  THEN

  \ LDR post-index
  DUP $FFC00C00 AND $F8400400 = IF
    DUP SIM-RD SD !
    DUP SIM-RN SN !
    SIM-IMM9 SM !
    SN @ SIM-X@
    DUP SIM-LOAD64 SD @ SIM-X!
    SM @ + SN @ SIM-X!
    DROP EXIT
  THEN

  \ LDR [n,#0]
  DUP $FFC00000 AND $F9400000 = IF
    DUP SIM-RD SD !
    SIM-RN SIM-X@ SIM-LOAD64 SD @ SIM-X!
    DROP EXIT
  THEN

  \ STR [n,#0]
  DUP $FFC00000 AND $F9000000 = IF
    DUP SIM-RD SIM-X@
    SWAP SIM-RN SIM-X@ SIM-STORE64
    DROP EXIT
  THEN

  \ CBNZ
  DUP 24 RSHIFT $FF AND $B5 = IF
    DUP SIM-RD SIM-X@ 0= IF DROP EXIT THEN
    SIM-IMM19 4 * SIM-PC @ 4 - + SIM-PC !
    DROP EXIT
  THEN

  \ CBZ
  DUP 24 RSHIFT $FF AND $B4 = IF
    DUP SIM-RD SIM-X@ IF DROP EXIT THEN
    SIM-IMM19 4 * SIM-PC @ 4 - + SIM-PC !
    DROP EXIT
  THEN

  S" SIM: unknown " TYPE DUP SYM-HEX. S" PC=" TYPE SIM-PC @ 4 - . CR
  TRUE SIM-HALT !
  DROP
  ;

: SIM-RUN  ( taddr -- x0 )
  SIM-INIT  SIM-PC !
  BEGIN SIM-HALT @ 0= WHILE SIM-STEP REPEAT
  0 SIM-X@
  ;

: RUN-T    ( taddr -- x0 )  SIM-RUN ;
: RUN-SYM  ( ca u -- x0 )  SYM-FIND-IX SYM-ADDR@ RUN-T ;
: RUN-ANS  ( -- x0 )  S" ANS" RUN-SYM ;

: .RUN-ANS  ( -- )
  RUN-ANS
  S" RUN-ANS => " TYPE DUP . CR
  5 <> IF S" RUN-ANS fail: expected 5" TYPE CR ABORT THEN
  S" RUN-ANS: OK" TYPE CR
  ;

FORTH DEFINITIONS
S" SIMARM64 loaded (RUN-T RUN-ANS .RUN-ANS)." TYPE CR
