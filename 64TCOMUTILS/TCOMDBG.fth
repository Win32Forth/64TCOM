\ TCOMDBG.fth — Phase 4.0 shared TCOM debugger UI
\
\ Public domain. TARGETARM64 loads this, then DBGARM64 (which IS's the hooks).
\ Does not touch ITC DEBUG / DBG-ON.
\
\ Public: BREAK UNBREAK UNBREAK-ALL WHERE STEP GO TDEBUG TDBG .S-T R.S-T
\
\ DBG-* are DEFERs so TDEBUG sees IS updates at runtime.
\ Editor: load TCOMDBG-ED after SZ-EDITOR for highlight, quiet console, side pane.

TCOM-ANEW TCOMDBG

FORTH DEFINITIONS
DECIMAL

DEFER DBG-PC@       \ ( -- taddr )
DEFER DBG-STACK     \ ( addr u -- n )
DEFER DBG-RSTACK    \ ( addr u -- n )
DEFER DBG-RLABEL    \ ( i addr u -- )
DEFER DBG-FETCH     \ ( taddr -- x )
DEFER DBG-STORE     \ ( x taddr -- )
DEFER DBG-BREAK!    \ ( taddr f -- )
DEFER DBG-STEP-INTO \ ( -- )
DEFER DBG-STEP-OVER \ ( -- )
DEFER DBG-GO        \ ( -- )
DEFER DBG-SYM@      \ ( taddr -- ca u )
DEFER DBG-START     \ ( taddr -- )
DEFER DBG-ARMED?    \ ( -- f )
DEFER DBG-HALTED?   \ ( -- f )
DEFER DBG-X0@       \ ( -- x )

: (DBG-STUB)  S" TCOMDBG: load DBGARM64" TYPE CR ABORT ;
' (DBG-STUB) IS DBG-PC@
' (DBG-STUB) IS DBG-STACK
' (DBG-STUB) IS DBG-RSTACK
' (DBG-STUB) IS DBG-RLABEL
' (DBG-STUB) IS DBG-FETCH
' (DBG-STUB) IS DBG-STORE
' (DBG-STUB) IS DBG-BREAK!
' (DBG-STUB) IS DBG-STEP-INTO
' (DBG-STUB) IS DBG-STEP-OVER
' (DBG-STUB) IS DBG-GO
' (DBG-STUB) IS DBG-SYM@
' (DBG-STUB) IS DBG-START
' (DBG-STUB) IS DBG-ARMED?
' (DBG-STUB) IS DBG-HALTED?
' (DBG-STUB) IS DBG-X0@

VARIABLE TDBG-QUIET
VARIABLE TDBG-SESSION
VARIABLE TDBG-DONE
VARIABLE TDBG-ACT
VARIABLE TDBG-PEND-ADDR      \ taddr for editor-deferred start (0 = none)
VARIABLE TDBG-OPENED-EDITOR  \ true if TDBG-UI-OPEN entered SZ-EDIT-LOOP
0 TDBG-QUIET !
0 TDBG-SESSION !
0 TDBG-DONE !
0 TDBG-PEND-ADDR !
0 TDBG-OPENED-EDITOR !

CREATE TDBG-NAME  64 ALLOT
CREATE TDBG-SBUF  16 CELLS ALLOT
CREATE TDBG-RBUF  16 CELLS ALLOT
CREATE TDBG-LAB   32 ALLOT

DEFER TDBG-UI-OPEN
DEFER TDBG-UI-PAUSE
DEFER TDBG-UI-DONE
DEFER TDBG-HOST-ARM
DEFER TDBG-HOST-DISARM

: TDBG-UI-OPEN-D  ( -- )  ;
: TDBG-UI-DONE-D  ( -- )  ;

\ Optional kernel words (rebuild 64Forth for F6/F7 steal while editor focused).
\ Do NOT use S" … FIND — FIND wants a counted string; S" length 13 was
\ treated as pointer 0xd → EXC_BAD_ACCESS in XFIND.
[UNDEFINED] TDBG-ARM-KEYS [IF]
: TDBG-HOST-ARM-D  ( -- )  ;
[ELSE]
: TDBG-HOST-ARM-D  ( -- )  TDBG-ARM-KEYS ;
[THEN]
[UNDEFINED] TDBG-DISARM-KEYS [IF]
: TDBG-HOST-DISARM-D  ( -- )  ;
[ELSE]
: TDBG-HOST-DISARM-D  ( -- )  TDBG-DISARM-KEYS ;
[THEN]

: TDBG-UI-PAUSE-D  ( -- )
  TDBG-QUIET @ IF EXIT THEN
  S" >> " TYPE
  DBG-PC@ DBG-SYM@ TYPE
  SPACE DBG-PC@ .
  SPACE
  TDBG-SBUF 16 DBG-STACK
  S" S" TYPE DUP .
  0 ?DO  SPACE TDBG-SBUF I CELLS + @ .  LOOP
  S"  [F6=over F7=into g=go q=quit]" TYPE CR
  ;

' TDBG-UI-OPEN-D     IS TDBG-UI-OPEN
' TDBG-UI-PAUSE-D    IS TDBG-UI-PAUSE
' TDBG-UI-DONE-D     IS TDBG-UI-DONE
' TDBG-HOST-ARM-D    IS TDBG-HOST-ARM
' TDBG-HOST-DISARM-D IS TDBG-HOST-DISARM

: .S-T  ( -- )
  TDBG-SBUF 16 DBG-STACK
  S" S-T " TYPE DUP . S" :" TYPE
  0 ?DO  SPACE TDBG-SBUF I CELLS + @ .  LOOP  CR
  ;

: R.S-T  ( -- )
  TDBG-RBUF 16 DBG-RSTACK
  S" R-T " TYPE DUP . S" :" TYPE
  0 ?DO
    SPACE  I TDBG-LAB 31 DBG-RLABEL  TDBG-LAB COUNT TYPE
  LOOP  CR
  ;

: WHERE  ( -- )
  S" WHERE PC=" TYPE  DBG-PC@ DUP .  SPACE
  DBG-SYM@ TYPE
  S"  X0=" TYPE  DBG-X0@ . CR
  ;

: BREAK-AT    ( taddr -- )  TRUE  DBG-BREAK! ;
: UNBREAK-AT  ( taddr -- )  FALSE DBG-BREAK! ;

: BREAK  ( "name" -- )
  PARSE-NAME DUP 0= IF  2DROP S" BREAK needs a name" TYPE CR EXIT  THEN
  SYM-FIND IF  SYM-ADDR@ BREAK-AT  S" BREAK set" TYPE CR
  ELSE  TYPE S"  ?" TYPE CR  THEN
  ;

: UNBREAK  ( "name" -- )
  PARSE-NAME DUP 0= IF  2DROP S" UNBREAK needs a name" TYPE CR EXIT  THEN
  SYM-FIND IF  SYM-ADDR@ UNBREAK-AT  S" BREAK cleared" TYPE CR
  ELSE  TYPE S"  ?" TYPE CR  THEN
  ;

: UNBREAK-ALL  ( -- )
  SIM-BRK-CLEAR
  S" all breaks cleared" TYPE CR
  ;

$02000000 CONSTANT TDBG-FKEY-TAG
16 CONSTANT TDBG-K-F6
17 CONSTANT TDBG-K-F7
134 CONSTANT TDBG-K-GO

: TDBG-HANDLE-KEY  ( u -- action )
  \ Host pushKey may deliver tagged EKEY-style (2<<24)|id or low byte only.
  DUP TDBG-FKEY-TAG AND TDBG-FKEY-TAG = IF
    $FFFFFF AND
    DUP TDBG-K-F6 = IF DROP 2 EXIT THEN
    DUP TDBG-K-F7 = IF DROP 1 EXIT THEN
    DROP 0 EXIT
  THEN
  DUP 255 AND
  DUP TDBG-K-F6 = IF  2DROP 2 EXIT  THEN
  DUP TDBG-K-F7 = IF  2DROP 1 EXIT  THEN
  DROP
  DUP TDBG-K-GO = IF DROP 3 EXIT THEN
  DUP [CHAR] g = OVER [CHAR] G = OR IF DROP 3 EXIT THEN
  DUP [CHAR] q = OVER [CHAR] Q = OR IF DROP 4 EXIT THEN
  DUP [CHAR] o = OVER [CHAR] O = OR IF DROP 2 EXIT THEN   \ over (Xcode-safe)
  DUP [CHAR] i = OVER [CHAR] I = OR IF DROP 1 EXIT THEN   \ into (Xcode-safe)
  DUP BL = IF DROP 2 EXIT THEN
  DUP 13 = IF DROP 2 EXIT THEN
  DROP 0
  ;

\ Host F6/F7 land on the KEY queue while TDBG-ARM-KEYS is set. Default EKEY
\ for console; TCOMDBG-ED replaces this with KEY when the editor is up.
DEFER TDBG-WAIT-KEY
: TDBG-WAIT-KEY-D  ( -- u )  EKEY ;
' TDBG-WAIT-KEY-D IS TDBG-WAIT-KEY

: TDBG-PAUSE  ( -- action )
  TDBG-UI-PAUSE
  TDBG-HOST-ARM
  BEGIN
    TDBG-WAIT-KEY TDBG-HANDLE-KEY
    DUP IF  TDBG-HOST-DISARM EXIT  THEN
    DROP
  AGAIN
  ;

: STEP  ( -- )
  DBG-HALTED? IF  S" already halted" TYPE CR EXIT  THEN
  DBG-STEP-INTO
  DBG-HALTED? IF  S" halted X0=" TYPE DBG-X0@ . CR  ELSE  WHERE  THEN
  ;

: GO  ( -- )
  DBG-HALTED? IF  S" already halted" TYPE CR EXIT  THEN
  DBG-GO
  S" GO done X0=" TYPE DBG-X0@ . CR  WHERE
  ;

\ True if PC's symbol name ends in '#' (FETCH# STORE# PLUS# …).
\ Those are real CALLs, but source-level step treats them as one opaque word.
\ (Do not use SYM-LIBRARY alone — too broad / easy to mis-classify.)
: TDBG-LIB-STOP?  ( -- f )
  DBG-PC@ DBG-SYM@
  DUP 0= IF  2DROP FALSE EXIT  THEN
  2DUP + 1- C@ [CHAR] # =
  NIP NIP
  ;

\ Leave FETCH#/STORE#/… without simulating their bodies (many use
\ unimplemented opcodes / HOST-CALL). Snap to the sim return link.
\ Space then ≈ one user-source word, not prim plumbing.
: TDBG-SKIP-LIB  ( -- )
  32 0 DO
    DBG-HALTED? IF  UNLOOP EXIT  THEN
    TDBG-LIB-STOP? 0= IF  UNLOOP EXIT  THEN
    [DEFINED] SIM-R-EMPTY? [IF]
      SIM-R-EMPTY? IF
        DBG-STEP-INTO                   \ no link — try one real step
      ELSE
        SIM-R-POP SIM-PC !              \ return to caller
      THEN
    [ELSE]
      DBG-STEP-INTO
    [THEN]
  LOOP
  ;

\ Space/OVER = one *source* token. Default: one CALL + skip #.
\ NDXARM64 replaces this so multi-CALL macros (e.g. / → TOR#…NIP#)
\ count as a single Space.
DEFER TDBG-STEP-OVER-SRC
: TDBG-STEP-OVER-SRC-D  ( -- )
  DBG-STEP-OVER
  TDBG-SKIP-LIB
  ;
' TDBG-STEP-OVER-SRC-D IS TDBG-STEP-OVER-SRC

: TDBG-RUN-LOOP  ( -- )
  -1 TDBG-SESSION !
  0 TDBG-DONE !
  BEGIN
    DBG-HALTED? IF
      S" TDBG done X0=" TYPE DBG-X0@ . CR
      -1 TDBG-DONE !
    ELSE
      TDBG-PAUSE TDBG-ACT !
      TDBG-ACT @ 1 = IF
        S" [TDBG] INTO " TYPE DBG-PC@ DBG-SYM@ TYPE CR
        DBG-STEP-INTO
        TDBG-SKIP-LIB
      ELSE
      TDBG-ACT @ 2 = IF
        S" [TDBG] OVER " TYPE DBG-PC@ DBG-SYM@ TYPE CR
        TDBG-STEP-OVER-SRC
      ELSE
      TDBG-ACT @ 3 = IF
        DBG-GO
        S" TDBG done X0=" TYPE DBG-X0@ . CR
        -1 TDBG-DONE !
      ELSE
      TDBG-ACT @ 4 = IF
        S" TDBG quit" TYPE CR
        -1 TDBG-DONE !
      THEN THEN THEN THEN
    THEN
    TDBG-DONE @
  UNTIL
  0 TDBG-SESSION !
  TDBG-HOST-DISARM
  TDBG-UI-DONE
  ;

: TDBG-CLEAR-STACK  ( -- )
  \ TCOM often leaves a stray 0 (or more) on the host stack; that poisons
  \ later CMOVE/C@ in editor highlight (XCFETCH bad access).
  BEGIN DEPTH WHILE DROP REPEAT
  ;

: TDEBUG  ( "name" -- )
  TDBG-CLEAR-STACK
  PARSE-NAME
  DUP 0= IF  2DROP S" TDEBUG needs a name" TYPE CR EXIT  THEN
  2DUP TDBG-NAME PLACE
  SYM-FIND 0= IF
    TDBG-NAME COUNT TYPE S"  ?" TYPE CR EXIT
  THEN
  SYM-ADDR@
  DUP TDBG-PEND-ADDR !
  DROP                       \ do not leave taddr under UI-OPEN / SZ-LOAD
  0 TDBG-OPENED-EDITOR !
  TDBG-UI-OPEN
  \ If UI opened the editor loop, TDBG already ran inside it via SZ-TDBG-XT.
  TDBG-OPENED-EDITOR @ IF  0 TDBG-PEND-ADDR !  EXIT  THEN
  TDBG-PEND-ADDR @ DBG-START
  0 TDBG-PEND-ADDR !
  TDBG-RUN-LOOP
  ;

: TDBG  ( "name" -- )  TDEBUG ;

\ ----- SEE-T — inspect a TCOM SYM (not host SEE) -----
VARIABLE SEE-T-IX
VARIABLE SEE-T-A
VARIABLE SEE-T-END
VARIABLE SEE-T-I
VARIABLE SEE-T-W

: SEE-T-TYPE.  ( typ -- )
  DUP SYM-TARGET  = IF DROP S" TARGET" TYPE EXIT THEN
  DUP SYM-LIBRARY = IF DROP S" LIB" TYPE EXIT THEN
  DUP SYM-CODE    = IF DROP S" CODE" TYPE EXIT THEN
  DUP SYM-FORWARD = IF DROP S" FWD" TYPE EXIT THEN
  DUP SYM-DATA    = IF DROP S" DATA" TYPE EXIT THEN
  DUP SYM-VALUE   = IF DROP S" VALUE" TYPE EXIT THEN
  DUP SYM-CONST   = IF DROP S" CONST" TYPE EXIT THEN
  . 
  ;

\ Lowest SYM addr strictly > a (or HERE-T if none)
: SEE-T-NEXT-ADDR  ( a -- a2 )
  SEE-T-A !
  HERE-T SEE-T-END !
  SYM-N @ 0 DO
    I SYM-ADDR@ DUP SEE-T-A @ U> IF
      DUP SEE-T-END @ U< IF  SEE-T-END !  ELSE  DROP  THEN
    ELSE  DROP  THEN
  LOOP
  SEE-T-END @
  ;

: SEE-T-INSN.  ( w -- )
  DUP SYM-HEX.
  DUP SIM-IS-RET?  IF  S" RET" TYPE  THEN
  DUP SIM-IS-BLR?  IF  S" BLR" TYPE  THEN
  DUP SIM-IS-BL?   IF  S" BL" TYPE  THEN
  DROP
  ;

: (SEE-T)  ( c-addr u -- )
  SYM-FIND 0= IF  TYPE S"  ?" TYPE CR EXIT  THEN
  DUP SEE-T-IX !
  S" SEE-T " TYPE  DUP SYM-GET-NAME TYPE
  S"  (" TYPE  DUP SYM-TYPE@ SEE-T-TYPE.  S" ) @" TYPE
  SYM-ADDR@ DUP .  DUP SYM-HEX. CR
  \ start; lim = min(next-symbol, start+128)
  DUP SEE-T-NEXT-ADDR
  OVER 128 + UMIN
  SEE-T-END !
  BEGIN
    DUP SEE-T-END @ U<
  WHILE
    DUP SYM-HEX. S" : " TYPE
    DUP SIM-W@ SEE-T-INSN. CR
    4 +
  REPEAT
  DROP
  ;

: SEE-T  ( "name" -- )
  PARSE-NAME
  DUP 0= IF  2DROP S" SEE-T needs a name" TYPE CR EXIT  THEN
  (SEE-T)
  ;

FORTH DEFINITIONS
S" TCOMDBG loaded (BREAK WHERE STEP GO TDEBUG/TDBG SEE-T)." TYPE CR
