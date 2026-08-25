\ TCOMDBG-ED.fth — SZ-EDITOR bindings for TCOMDBG
\
\ Public domain. Load AFTER SZ-EDITOR and AFTER FLOAD TARGETARM64.fth.
\
\ Location model (classic TCOM index):
\   TCOMNDX records PC↔source during compile (.NDX listing is the map).
\   TDBG opens the **source .fth** and uses the index to GOTO line + highlight
\   the token — reading the .NDX alone is not the debugging UX.

TCOM-ANEW TCOMDBG-ED

ONLY FORTH ALSO EDITOR
FORTH-WORDLIST SET-CURRENT
DECIMAL

: TDBG-ED-SAME-FILE?  ( c-addr u -- f )
  SZ-HAS-NAME? 0= IF  2DROP FALSE EXIT  THEN
  SZ-GET-NAME COMPARE 0=
  ;

VARIABLE TDBG-TRACE
-1 TDBG-TRACE !

: TDBG-TR  ( c-addr u -- )
  TDBG-TRACE @ 0= IF  2DROP EXIT  THEN
  ." [TDBG] " TYPE ."  d=" DEPTH . CR
  ;

: TDBG-ED-GO  ( -- )
  S" ED-GO enter" TDBG-TR
  TDBG-CLEAR-STACK
  S" ED-GO cleared" TDBG-TR
  TDBG-PEND-ADDR @ DUP 0= IF  DROP EXIT  THEN
  0 TDBG-PEND-ADDR !
  -1 TDBG-QUIET !
  S" ED-GO DBG-START" TDBG-TR
  DBG-START
  S" ED-GO RUN-LOOP" TDBG-TR
  TDBG-RUN-LOOP
  S" ED-GO leave" TDBG-TR
  ;

: TDBG-ED-OPEN-FILE  ( c-addr u -- )
  S" OPEN-FILE enter" TDBG-TR
  SZ-HYPER-HITS-OFF
  SZ-BUF-BOOT
  S" OPEN-FILE after-boot" TDBG-TR
  S" OPEN-FILE load" TDBG-TR
  2DUP ['] SZ-LOAD CATCH
  ?DUP IF
    ." TDBG: SZ-LOAD THROW " . CR
    2DROP  0 TDBG-OPENED-EDITOR !  0 SZ-TDBG-XT !  EXIT
  THEN
  DUP IF
    ." TDBG: cannot load " TYPE CR
    2DROP  0 TDBG-OPENED-EDITOR !  0 SZ-TDBG-XT !  EXIT
  THEN DROP
  2DROP
  S" OPEN-FILE reset" TDBG-TR
  SZ-VIEW-RESET
  ['] TDBG-ED-GO SZ-TDBG-ARM
  -1 TDBG-OPENED-EDITOR !
  S" OPEN-FILE edit-loop" TDBG-TR
  SZ-EDIT-LOOP
  S" OPEN-FILE leave" TDBG-TR
  ;

\ Primary view = source .fth (index is the map, not the document)
: TDBG-ED-VIEW-PATH  ( -- c-addr u f )
  [DEFINED] TSRC-CUR-PATH [IF]
    TSRC-CUR-PATH C@ IF  TSRC-CUR-PATH COUNT TRUE EXIT  THEN
  [THEN]
  [DEFINED] NDX-PATH [IF]
    NDX-PATH C@ IF  NDX-PATH COUNT TRUE EXIT  THEN
  [THEN]
  0 0 FALSE
  ;

: TDBG-ED-OPEN  ( -- )
  S" ED-OPEN enter" TDBG-TR
  0 TDBG-OPENED-EDITOR !
  TDBG-ED-VIEW-PATH 0= IF
    ." TDBG: no source/NDX path — console step only" CR
    EXIT
  THEN
  ." TDBG: source " 2DUP TYPE CR
  [DEFINED] NDX-PATH [IF]
    NDX-PATH C@ IF
      ." TDBG: index  " NDX-PATH COUNT TYPE
      ."  (" NDX-N @ 0 .R ."  sites)" CR
    THEN
  [THEN]
  S" ED-OPEN after-path" TDBG-TR
  SZ-EDITOR-ACTIVE @ IF
    2DUP TDBG-ED-SAME-FILE? IF
      2DROP SZ-VIEW-RESET
    ELSE
      SZ-TBUF-ADDR @ 0= IF  SZ-BUF-BOOT  THEN
      SZ-LOAD IF  ." TDBG: SZ-LOAD failed" CR  2DROP EXIT  THEN
      2DROP SZ-VIEW-RESET
    THEN
    -1 TDBG-QUIET !
  ELSE
    [DEFINED] SZ-TDBG-ARM [IF]
      S" ED-OPEN → OPEN-FILE" TDBG-TR
      TDBG-ED-OPEN-FILE
    [ELSE]
      ." TDBG: rebuild 64Forth for SZ-TDBG-ARM — console step only" CR
      2DROP
    [THEN]
  THEN
  S" ED-OPEN leave" TDBG-TR
  ;

\ Current SYM index for PC (-1 if none). Uses same nearest-≤ rule as DBG-SYM@.
VARIABLE TDBG-SYM-IX
VARIABLE TDBG-SYM-LO
VARIABLE TDBG-SYM-HI
: TDBG-SYM-BOUNDS  ( -- )
  -1 TDBG-SYM-IX !
  0 TDBG-SYM-LO !
  HERE-T TDBG-SYM-HI !
  [DEFINED] SYM-N [IF]
    DBG-PC@
    SYM-N @ 0 DO
      I SYM-ADDR@ OVER U> IF
        DROP
      ELSE
        TDBG-SYM-IX @ 0< IF
          I TDBG-SYM-IX !  I SYM-ADDR@ TDBG-SYM-LO !
        ELSE
          I SYM-ADDR@ TDBG-SYM-LO @ U> IF
            I TDBG-SYM-IX !  I SYM-ADDR@ TDBG-SYM-LO !
          THEN
        THEN
      THEN
    LOOP DROP
    TDBG-SYM-IX @ 0< 0= IF
      HERE-T TDBG-SYM-HI !
      SYM-N @ 0 DO
        I SYM-ADDR@ TDBG-SYM-LO @ U> IF
          I SYM-ADDR@ DUP TDBG-SYM-HI @ U< IF  TDBG-SYM-HI !  ELSE  DROP  THEN
        THEN
      LOOP
    THEN
  [THEN]
  ;

\ Best NDX row with taddr in [SYM-LO, SYM-HI) and taddr ≤ PC (stay in callee).
: TDBG-ED-NDX-IN-SYM  ( -- ix|-1 )
  -1 NDX-FIND-IX !
  [DEFINED] NDX-N [IF]
    DBG-PC@
    NDX-N @ 0 DO
      I CELLS NDX-TADDR-A @ + @            \ pc taddr
      DUP TDBG-SYM-LO @ U< IF  DROP
      ELSE DUP TDBG-SYM-HI @ U>= IF  DROP
      ELSE 2DUP U> IF  DROP               \ taddr > pc
      ELSE
        NDX-FIND-IX @ 0< IF
          DROP I NDX-FIND-IX !
        ELSE
          DUP NDX-FIND-IX @ CELLS NDX-TADDR-A @ + @ U>
          IF  DROP I NDX-FIND-IX !  ELSE  DROP  THEN
        THEN
      THEN THEN THEN
    LOOP DROP
  [THEN]
  NDX-FIND-IX @
  ;

\ Map pause → NDX row inside the *current* symbol only.
\ Do NOT fall back to R-link call site — that yo-yo'd the editor:
\   inside !, → fill-notes CALL !, → inside !, → fill-notes …
: TDBG-ED-NDX-IX  ( -- ix|-1 )
  [DEFINED] NDX-FIND [IF]
    \ If we ever pause inside FETCH#/STORE#, show the *call site* in user source.
    [DEFINED] TDBG-LIB-STOP? [IF]
      TDBG-LIB-STOP? IF
        TDBG-RBUF 16 DBG-RSTACK IF
          DROP TDBG-RBUF @ NDX-FIND EXIT
        ELSE  DROP  THEN
      THEN
    [THEN]
    TDBG-SYM-BOUNDS
    TDBG-SYM-IX @ 0< IF  -1 EXIT  THEN
    DBG-PC@ NDX-FIND
    DUP 0< IF  DROP
    ELSE
      DUP CELLS NDX-TADDR-A @ + @
      DUP TDBG-SYM-LO @ U< SWAP TDBG-SYM-HI @ U>= OR IF  DROP
      ELSE  EXIT  THEN
    THEN
    TDBG-ED-NDX-IN-SYM
  [ELSE]
    -1
  [THEN]
  ;

: TDBG-ED-HIGHLIGHT  ( -- )
  S" HL enter" TDBG-TR
  SZ-EDITOR-ACTIVE @ 0= IF EXIT THEN
  SZ-TBUF 0= IF EXIT THEN
  BEGIN DEPTH WHILE DROP REPEAT

  TDBG-ED-NDX-IX DUP 0< IF
    DROP
    DBG-PC@ DBG-SYM@
    DUP 0= IF  2DROP EXIT  THEN
    S" HL sym=" TYPE 2DUP TYPE CR
    [DEFINED] SZ-HIGHLIGHT-NAME-LAST [IF]
      ['] SZ-HIGHLIGHT-NAME-LAST CATCH IF  2DROP 0 SZ-SEL-OK !  ELSE  DROP  THEN
    [ELSE]
      [DEFINED] SZ-HIGHLIGHT-NAME [IF]
        ['] SZ-HIGHLIGHT-NAME CATCH IF  2DROP 0 SZ-SEL-OK !  ELSE  DROP  THEN
      [ELSE]
        2DROP
      [THEN]
    [THEN]
    EXIT
  THEN

  \ Have index row → goto source line, highlight token from index
  DUP CELLS NDX-LINE-A @ + @
  S" HL line=" TYPE DUP . SPACE
  DUP IF  SZ-GOTO-LINE  ELSE  DROP  THEN

  NDX-NAMES-A @ IF
    /NDX-NAME * NDX-NAMES-A @ + COUNT
    DUP IF
      S" token=" TYPE 2DUP TYPE CR
      [DEFINED] SZ-HIGHLIGHT-NAME [IF]
        \ Search from current line (CUR after GOTO), not whole-file last
        ['] SZ-HIGHLIGHT-NAME CATCH IF  2DROP 0 SZ-SEL-OK !  ELSE  DROP  THEN
      [ELSE]
        2DROP
      [THEN]
    ELSE
      2DROP CR
    THEN
  ELSE
    DROP CR
  THEN
  S" HL ok" TDBG-TR
  ;

VARIABLE TDBG-PAINT-ROW
VARIABLE TDBG-PAINT-N

: TDBG-ED-PAINT-SIDE  ( -- )
  SZ-EDITOR-ACTIVE @ 0= IF EXIT THEN
  TDBG-SESSION @ 0= IF EXIT THEN
  BEGIN DEPTH WHILE DROP REPEAT
  SZ-TEXT-TOP
  BEGIN  DUP SZ-TEXT-BOT @ > 0= WHILE
    SZ-SIDE-LEFT OVER AT-XY
    SZ-SIDE-WIDTH 0 DO  BL EMIT  LOOP
    1+
  REPEAT DROP
  DBG-PC@ DBG-SYM@
  63 MIN
  DUP TDBG-NAME C!
  TDBG-NAME CHAR+ SWAP CMOVE
  SZ-SIDE-LEFT SZ-TEXT-TOP AT-XY
  S" >> " TYPE  TDBG-NAME COUNT TYPE
  TDBG-SBUF 16 DBG-STACK TDBG-PAINT-N !
  SZ-SIDE-LEFT SZ-TEXT-TOP 1+ AT-XY
  S" Data " TYPE  TDBG-PAINT-N @ .
  SZ-TEXT-TOP 2 + TDBG-PAINT-ROW !
  0
  BEGIN  DUP TDBG-PAINT-N @ < WHILE
    TDBG-PAINT-ROW @ SZ-TEXT-BOT @ > IF  DROP LEAVE  THEN
    SZ-SIDE-LEFT TDBG-PAINT-ROW @ AT-XY
    DUP 0= IF  S" T " TYPE  ELSE  S"   " TYPE  THEN
    TDBG-SBUF OVER CELLS + @ .
    1 TDBG-PAINT-ROW +!
    1+
  REPEAT DROP
  SZ-SIDE-LEFT TDBG-PAINT-ROW @ AT-XY  S" Return " TYPE
  1 TDBG-PAINT-ROW +!
  TDBG-RBUF 16 DBG-RSTACK TDBG-PAINT-N !
  0
  BEGIN  DUP TDBG-PAINT-N @ < WHILE
    TDBG-PAINT-ROW @ SZ-TEXT-BOT @ > IF  DROP LEAVE  THEN
    SZ-SIDE-LEFT TDBG-PAINT-ROW @ AT-XY
    DUP TDBG-LAB 31 DBG-RLABEL
    TDBG-LAB COUNT TYPE
    1 TDBG-PAINT-ROW +!
    1+
  REPEAT DROP
  TERMINAL-REFRESH
  ;

: TDBG-ED-SIDE-HOOK  ( -- )  TDBG-ED-PAINT-SIDE ;

: TDBG-ED-PAUSE  ( -- )
  SZ-EDITOR-ACTIVE @ IF
    -1 TDBG-QUIET !
    BEGIN DEPTH WHILE DROP REPEAT
    S" PAUSE" TDBG-TR
    TDBG-ED-HIGHLIGHT
    S" PAUSE after-HL" TDBG-TR
    SZ-REDRAW
    BEGIN DEPTH WHILE DROP REPEAT
    S" PAUSE after-REDRAW" TDBG-TR
    ['] TDBG-ED-PAINT-SIDE CATCH IF  DROP  THEN
    BEGIN DEPTH WHILE DROP REPEAT
    S" PAUSE after-PAINT" TDBG-TR
  ELSE
    0 TDBG-QUIET !
    TDBG-UI-PAUSE-D
  THEN
  ;

: TDBG-ED-DONE  ( -- )
  0 TDBG-QUIET !
  0 SZ-SEL-OK !
  SZ-EDITOR-ACTIVE @ IF  SZ-REDRAW  THEN
  ;

: TDBG-WAIT-KEY-ED  ( -- u )  KEY ;

ONLY FORTH ALSO EDITOR
' TDBG-ED-OPEN  IS TDBG-UI-OPEN
' TDBG-ED-PAUSE IS TDBG-UI-PAUSE
' TDBG-ED-DONE  IS TDBG-UI-DONE
' TDBG-WAIT-KEY-ED IS TDBG-WAIT-KEY
[DEFINED] SZ-SIDE-HOOK [IF]
  ' TDBG-ED-SIDE-HOOK IS SZ-SIDE-HOOK
[THEN]

ONLY FORTH
FORTH-WORDLIST SET-CURRENT
S" TCOMDBG-ED loaded (source via NDX map + quiet + side pane)." TYPE CR
