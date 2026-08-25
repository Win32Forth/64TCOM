\ TCOMNDX.fth — Port of classic TCOM index (TCOMNDX.SEQ / .INX) for 64TCOM
\
\ Public domain. Concepts from F-PC TCOM `TCOMNDX.FTH` (Zimmer/Boutelle):
\   index! ( type taddr -- ) records target address + source location + type
\   Types: call / inst / host / ret / other (nibble taxonomy preserved in spirit)
\   Output: image-stem.INX (binary records) + image-stem.NDX (text for SZ-EDITOR)
\
\ Source location comes from TSRC when compiling .fth:
\   TSRC-CUR-PATH, TSRC-LINE, TSRC-TOK-AT
\
\ Load after 64HOST/64DIR/64SRC (or at least HERE-T). ARM64 hooks CALL-ABS,/RET,.

TCOM-ANEW TCOMNDX

FORTH DEFINITIONS
DECIMAL

\ ----- Classic-inspired type codes (low nibble; $8 bit = in-colon context) -----
0 CONSTANT NDX-NOTYPE
1 CONSTANT NDX-OTHER
2 CONSTANT NDX-INST
3 CONSTANT NDX-CALL          \ Forth / CALL-ABS call site (xCC, / calltype)
4 CONSTANT NDX-BYTE
5 CONSTANT NDX-WORD
6 CONSTANT NDX-STRING
7 CONSTANT NDX-END
8 CONSTANT NDX-BRANCH
9 CONSTANT NDX-HOST          \ HOST-CALL, stub (64TCOM extension of call family)
10 CONSTANT NDX-RET           \ RET, / ;T
11 CONSTANT NDX-ENTRY         \ colon entry / landing (optional)

\ ----- In-memory table (growable via ALLOCATE) -----
4096 CONSTANT NDX-MAX
VARIABLE NDX-N
0 NDX-N !
VARIABLE NDX-ON
-1 NDX-ON !                   \ /INDEX default ON (classic TCOM default)

\ Parallel arrays — 64-bit cells (classic had 2-byte taddr)
VARIABLE NDX-TADDR-A          \ base of taddr[] 
VARIABLE NDX-RET-A            \ ret-taddr[] (link addr after BLR; 0 if N/A)
VARIABLE NDX-TYPE-A
VARIABLE NDX-LINE-A
VARIABLE NDX-TOK-A
VARIABLE NDX-FILE-A           \ index into NDX-FILES
0 NDX-TADDR-A !
0 NDX-RET-A !
0 NDX-TYPE-A !
0 NDX-LINE-A !
0 NDX-TOK-A !
0 NDX-FILE-A !

\ File path table (classic .FIL / curfil#)
32 CONSTANT NDX-FILES-MAX
CREATE NDX-FILES  NDX-FILES-MAX 256 * ALLOT
VARIABLE NDX-FILE-N
0 NDX-FILE-N !

CREATE NDX-PATH  256 ALLOT    \ last written path (counted)
CREATE NDX-CALLEE 64 ALLOT    \ optional name for text listing
CREATE NDX-NAME-A  0 ,        \ optional: base of name records — see emit

\ Name strings for listing (counted, max 31 like classic)
32 CONSTANT /NDX-NAME
VARIABLE NDX-NAMES-A
0 NDX-NAMES-A !

: /INDEX     ( -- )  -1 NDX-ON ! ;
: /NOINDEX   ( -- )   0 NDX-ON ! ;
: /IND       ( -- )  /INDEX ;
: /NOIND     ( -- )  /NOINDEX ;

: NDX-BOOT  ( -- )
  NDX-TADDR-A @ IF EXIT THEN
  NDX-MAX CELLS ALLOCATE 0= IF NDX-TADDR-A ! ELSE 0 NDX-TADDR-A ! THEN
  NDX-MAX CELLS ALLOCATE 0= IF NDX-RET-A !   ELSE 0 NDX-RET-A ! THEN
  NDX-MAX CELLS ALLOCATE 0= IF NDX-TYPE-A !  ELSE 0 NDX-TYPE-A ! THEN
  NDX-MAX CELLS ALLOCATE 0= IF NDX-LINE-A !  ELSE 0 NDX-LINE-A ! THEN
  NDX-MAX CELLS ALLOCATE 0= IF NDX-TOK-A !   ELSE 0 NDX-TOK-A ! THEN
  NDX-MAX CELLS ALLOCATE 0= IF NDX-FILE-A !  ELSE 0 NDX-FILE-A ! THEN
  NDX-MAX /NDX-NAME * ALLOCATE 0= IF NDX-NAMES-A ! ELSE 0 NDX-NAMES-A ! THEN
  ;

: NDX-CLEAR  ( -- )
  NDX-BOOT
  0 NDX-N !
  0 NDX-FILE-N !
  NDX-FILES NDX-FILES-MAX 256 * ERASE
  0 NDX-PATH C!
  ;

\ Find or add path → file# (1-based; 0 = none)
: NDX-FILE#  ( c-addr u -- fil# )
  DUP 0= IF  2DROP 0 EXIT  THEN
  NDX-FILE-N @ 0 DO
    I 256 * NDX-FILES + COUNT
    2OVER COMPARE 0= IF  2DROP I 1+ EXIT  THEN
  LOOP
  NDX-FILE-N @ NDX-FILES-MAX >= IF  2DROP 0 EXIT  THEN
  NDX-FILE-N @ 256 * NDX-FILES + PLACE
  1 NDX-FILE-N +!
  NDX-FILE-N @
  ;

: NDX-HAVE-TSRC?  ( -- f )
  [DEFINED] TSRC-CUR-PATH [IF]
    TSRC-CUR-PATH C@ 0<>
  [ELSE]
    FALSE
  [THEN]
  ;

: NDX-SRC-SNAP  ( -- line tok fil# )
  NDX-HAVE-TSRC? 0= IF  0 0 0 EXIT  THEN
  \ Remember path once (avoid COMPARE/PLACE during every INDEX!)
  NDX-FILE-N @ 0= IF
    TSRC-CUR-PATH COUNT DUP IF
      NDX-FILES PLACE
      1 NDX-FILE-N !
    ELSE  2DROP  THEN
  THEN
  TSRC-LINE @
  TSRC-TOK-AT @
  NDX-FILE-N @
  ;

: NDX-PUT-NAME  ( c-addr u i -- )
  NDX-NAMES-A @ 0= IF  DROP 2DROP EXIT  THEN
  /NDX-NAME * NDX-NAMES-A @ +
  >R  31 MIN  DUP R@ C!  R@ CHAR+ SWAP MOVE  R> DROP
  ;

VARIABLE NDX-T0
VARIABLE NDX-T1
VARIABLE NDX-T2
CREATE NDX-TN  64 ALLOT

\ Classic: index! ( type taddr -- )
: INDEX!  ( type taddr -- )
  NDX-ON @ 0= IF  2DROP EXIT  THEN
  NDX-BOOT
  NDX-TADDR-A @ 0= IF  2DROP EXIT  THEN
  NDX-N @ NDX-MAX >= IF  2DROP EXIT  THEN
  NDX-T0 !                               \ taddr
  NDX-T1 !                               \ type
  NDX-N @ CELLS NDX-TADDR-A @ + NDX-T0 @ SWAP !
  NDX-N @ CELLS NDX-TYPE-A @ +  NDX-T1 @ SWAP !
  NDX-N @ CELLS NDX-RET-A @ +  0 SWAP !
  NDX-SRC-SNAP                           \ line tok fil#
  NDX-N @ CELLS NDX-FILE-A @ + !
  NDX-N @ CELLS NDX-TOK-A @ + !
  NDX-N @ CELLS NDX-LINE-A @ + !
  NDX-NAMES-A @ IF
    S" -" NDX-N @ NDX-PUT-NAME
  THEN
  1 NDX-N +!
  ;

\ Full record: ( type taddr ret c-addr u -- )
: NDX-RECORD  ( type taddr ret c-addr u -- )
  NDX-ON @ 0= IF  2DROP DROP 2DROP EXIT  THEN
  NDX-BOOT
  NDX-TADDR-A @ 0= IF  2DROP DROP 2DROP EXIT  THEN
  NDX-N @ NDX-MAX >= IF  2DROP DROP 2DROP EXIT  THEN
  NDX-TN PLACE                           \ name
  NDX-T2 !                               \ ret
  NDX-T0 !                               \ taddr
  NDX-T1 !                               \ type
  NDX-N @ >R
  NDX-T0 @ R@ CELLS NDX-TADDR-A @ + !
  NDX-T1 @ R@ CELLS NDX-TYPE-A @ + !
  NDX-T2 @ R@ CELLS NDX-RET-A @ + !
  NDX-SRC-SNAP
  R@ CELLS NDX-FILE-A @ + !
  R@ CELLS NDX-TOK-A @ + !
  R@ CELLS NDX-LINE-A @ + !
  NDX-TN COUNT R@ NDX-PUT-NAME
  R> DROP
  1 NDX-N +!
  ;

: NDX-TYPE-NAME  ( type -- ca u )
  DUP NDX-CALL  = IF DROP S" CALL" EXIT THEN
  DUP NDX-HOST  = IF DROP S" HOST" EXIT THEN
  DUP NDX-RET   = IF DROP S" RET" EXIT THEN
  DUP NDX-ENTRY = IF DROP S" ENTRY" EXIT THEN
  DUP NDX-INST  = IF DROP S" INST" EXIT THEN
  DROP S" OTHER"
  ;

VARIABLE NDX-BASE-SAVE
: NDX-HEX8  ( u -- ca u )
  BASE @ NDX-BASE-SAVE !
  HEX
  0 <# # # # # # # # # #>
  NDX-BASE-SAVE @ BASE !
  ;

VARIABLE NDX-FID
\ Write text listing for SZ-EDITOR (classic fields: taddr + source + type)
\ NOTE: fileid must not live on R during DO/LOOP (classic pitfall).
: NDX-WRITE-TEXT  ( c-addr u -- ior )
  W/O CREATE-FILE ?DUP IF  NIP EXIT  THEN
  NDX-FID !
  S" # TCOM-NDX 1 (port of TCOMNDX.SEQ /INDEX; call/ret sites)" NDX-FID @ WRITE-FILE DROP
  S\" \n# taddr     ret      type file             line  tok   name\n" NDX-FID @ WRITE-FILE DROP
  BASE @ NDX-BASE-SAVE !
  NDX-N @ 0 DO
    I CELLS NDX-TADDR-A @ + @ NDX-HEX8 NDX-FID @ WRITE-FILE DROP
    S"  " NDX-FID @ WRITE-FILE DROP
    I CELLS NDX-RET-A @ + @ NDX-HEX8 NDX-FID @ WRITE-FILE DROP
    S"  " NDX-FID @ WRITE-FILE DROP
    I CELLS NDX-TYPE-A @ + @ NDX-TYPE-NAME NDX-FID @ WRITE-FILE DROP
    S"  " NDX-FID @ WRITE-FILE DROP
    I CELLS NDX-FILE-A @ + @ DUP IF
      1- 256 * NDX-FILES + COUNT NDX-FID @ WRITE-FILE DROP
    ELSE  DROP S" -" NDX-FID @ WRITE-FILE DROP  THEN
    S"  " NDX-FID @ WRITE-FILE DROP
    DECIMAL
    I CELLS NDX-LINE-A @ + @ 0 <# #S #> NDX-FID @ WRITE-FILE DROP
    S"  " NDX-FID @ WRITE-FILE DROP
    I CELLS NDX-TOK-A @ + @ 0 <# #S #> NDX-FID @ WRITE-FILE DROP
    S"  " NDX-FID @ WRITE-FILE DROP
    NDX-NAMES-A @ IF
      I /NDX-NAME * NDX-NAMES-A @ + COUNT NDX-FID @ WRITE-FILE DROP
    THEN
    S\" \n" NDX-FID @ WRITE-FILE DROP
  LOOP
  NDX-BASE-SAVE @ BASE !
  NDX-FID @ CLOSE-FILE
  ;

VARIABLE NDX-DOT
\ Path → NDX-PATH with .NDX (replace final extension)
: NDX-STEM>NDX  ( c-addr u -- c-addr2 u2 )
  DUP 0= IF  2DROP S" out.NDX" NDX-PATH PLACE NDX-PATH COUNT EXIT  THEN
  250 UMIN NDX-PATH PLACE
  0 NDX-DOT !
  NDX-PATH COUNT 0 DO
    NDX-PATH 1+ I + C@
    DUP [CHAR] / = OVER [CHAR] \ = OR IF  DROP 0 NDX-DOT !
    ELSE [CHAR] . = IF  I NDX-DOT !  THEN THEN   \ length before '.'
  LOOP
  NDX-DOT @ IF  NDX-DOT @ NDX-PATH C!  THEN
  S" .NDX"
  NDX-PATH COUNT + SWAP MOVE
  NDX-PATH C@ 4 + NDX-PATH C!
  NDX-PATH COUNT
  ;

: NDX-SAVE-AS  ( c-addr u -- )
  NDX-STEM>NDX
  2DUP NDX-PATH PLACE
  NDX-WRITE-TEXT IF
    S" NDX: write failed for " TYPE NDX-PATH COUNT TYPE CR
  ELSE
    S" NDX: wrote " TYPE NDX-PATH COUNT TYPE
    S"  (" TYPE NDX-N @ 0 .R S"  records)" TYPE CR
  THEN
  ;

\ Lookup: exact taddr/ret, or key inside [taddr,ret] (SIM link sits mid CALL-ABS stub)
VARIABLE NDX-FIND-KEY
VARIABLE NDX-FIND-IX
VARIABLE NDX-FIND-TA
VARIABLE NDX-FIND-RA
: NDX-FIND  ( taddr -- ix|-1 )
  NDX-FIND-KEY !
  -1 NDX-FIND-IX !
  NDX-N @ 0 DO
    I CELLS NDX-TADDR-A @ + @ NDX-FIND-TA !
    I CELLS NDX-RET-A @ + @ NDX-FIND-RA !
    NDX-FIND-KEY @ NDX-FIND-TA @ = IF  I NDX-FIND-IX !
    ELSE NDX-FIND-KEY @ NDX-FIND-RA @ = IF  I NDX-FIND-IX !
    ELSE
      NDX-FIND-RA @ IF
        NDX-FIND-KEY @ NDX-FIND-TA @ U< 0=
        NDX-FIND-KEY @ NDX-FIND-RA @ U> 0= AND
        IF  I NDX-FIND-IX !  THEN
      THEN
    THEN THEN
  LOOP
  NDX-FIND-IX @
  ;

: NDX-NEAREST<=  ( taddr -- ix|-1 )
  NDX-FIND-KEY !
  -1 NDX-FIND-IX !
  NDX-N @ 0 DO
    I CELLS NDX-TADDR-A @ + @ DUP NDX-FIND-KEY @ U> IF  DROP
    ELSE
      NDX-FIND-IX @ 0< IF  DROP I NDX-FIND-IX !
      ELSE
        I CELLS NDX-TADDR-A @ + @
        NDX-FIND-IX @ CELLS NDX-TADDR-A @ + @ U> IF  I NDX-FIND-IX !  THEN
      THEN
    THEN
  LOOP
  NDX-FIND-IX @
  ;

S" TCOMNDX loaded (/INDEX — port of classic TCOM .INX concepts)." TYPE CR
