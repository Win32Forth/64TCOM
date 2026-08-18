\ tetra.fth — Tetris for 64TCOM (64-bit cells)
\
\   FLOAD TARGETARM64.fth
\   TCOM tetra/tetra.fth
\   open tetra/tetra.app
\
\ Character Tetris after Marc Hawley (TCOM/F-PC). Retargeted for 8-byte cells.
\ GET-CHAR / AT / KEY? / TONE / CASE etc. are dialect / host prims.

\\
        Try to simulate the Nintendo game Tetris using character graphics.

        This version of FPC like 2.5 blanks a whole line after doing a screen
        print. This makes it no good for doing character graphics. Perhaps this
        feature can be disabled.

        Can't find a way to disable, however IF AT command is used to get cursor
        to bottom of screen the problem can be avoided.

        Need a way to rotate the figures while moving them.
        Plan: 1) keep the x,y position of a central square.
              2) build the figure from three additional x,y
                 coordinates offset, such as -1,0 1,0 0,1 for the tee.
              3) But each has 4 different subconfigurations

        Is it necessary to store all the subconfigs? Or can the rotations
        be calculated? 0,0 is unchanged. For a rotation to the right,
        +x becomes +y (top = y0), +y -> -x,
                                  -x -> -y,
                                  -y -> +x
                                  +x -> +y
        i.e. change the y sign, keep the  x sign.
{

: SQ   32  EMIT 32  EMIT ;  \ print a square dark

: BLSQ  219 EMIT 219 EMIT ; \ print a square white

: MY.AT ( x y -- x' y') \ move at to center
        5 +
        SWAP
        30 +
        SWAP
      AT
        ;


: FIELD ( -- )
      CLS
    16 0 DO
        20 0 DO I J MY.AT  BLSQ 2  +LOOP CR
      LOOP

      ;

: BORDER
        -1 -1 MY.AT 42 EMIT
        -1 16 MY.AT 42 EMIT
        21 -1 MY.AT 42 EMIT
        21 16 MY.AT 42 EMIT
        17 0 DO -1 I MY.AT 42 EMIT 21 I MY.AT 42 EMIT LOOP
        21 0 DO I -1 MY.AT 42 EMIT I 16 MY.AT 42 EMIT LOOP
        ;

\\
        It might be better to use position variables rather than vectors
        except when doing a rotate. The position information is needed to
        check the validity of every DOWN, left AND right moves.
{

CREATE FIGURE
        8 , 0 , 10 , 0 ,  8 , 1 , 10 , 1 ,      \ block   figure.no 0
        8 , 0 ,  6 , 0 , 10 , 0 , 12 , 0 ,      \ rod  x0,y0 is center of rot
        8 , 0 , 10 , 0 ,  6 , 0 ,  8 , 1 ,      \ tee               2
        8 , 0 ,  6 , 0 ,  8 , 1 , 10 , 1 ,      \ zee               3
        8 , 0 , 10 , 0 ,  8 , 1 ,  6 , 1 ,      \ es                4
        8 , 0 ,  8 , -1 , 8 , 1 , 10 , 1 ,      \ el                5
        8 , 0 ,  8 , -1 , 8 , 1 ,  6 , 1 ,      \ jay               6


CREATE CURR    64 ALLOT                   \ 1 cell per coordinate

0 VALUE FIGURE.NO       \ figures 0 through 6

: FILL.CURR      ( -- )
        FIGURE.NO 8 CELLS *         \ offset into figure array
        FIGURE +
        CURR                        \ destination
        8 CELLS CMOVE               \ from to bytes
        ;



: DRAW.CURR ( -- )
        CURR                    \ c
        DUP   DUP               \ c c c
        CELL+                   \ c c c+CELL
        @ SWAP @ SWAP MY.AT SQ     \ c         draw first square

        DUP 2 CELLS + DUP CELL+ \ c c+2cells c+3cells
        @ SWAP @ SWAP  MY.AT SQ    \ c         draw 2nd

        DUP 4 CELLS + DUP CELL+ \ c c+4cells c+5cells
        @ SWAP @ SWAP MY.AT SQ     \ c         draw 3rd

        6 CELLS + DUP CELL+     \ c+6cells c+7cells
        @ SWAP @ SWAP MY.AT SQ     \  --       draw 4th
        0 22 AT
        ;

: UNDRAW.CURR ( -- )
        CURR                 \ c
        DUP   DUP               \ c c c
        CELL+                   \ c c c+CELL
        @ SWAP @ SWAP MY.AT BLSQ   \ c         draw first square

        DUP 2 CELLS + DUP CELL+ \ c c+2cells c+3cells
        @ SWAP @ SWAP  MY.AT BLSQ  \ c         draw 2nd

        DUP 4 CELLS + DUP CELL+ \ c c+4cells c+5cells
        @ SWAP @ SWAP MY.AT BLSQ   \ c         draw 3rd

        6 CELLS + DUP CELL+     \ c+6cells c+7cells
        @ SWAP @ SWAP MY.AT BLSQ   \  --       draw 4th
        0 22 AT
        ;


: SEE.CURR
        CR ." offset |  x  ,  y  " CR
        4 0 DO
        I 2 CELLS * .   8 SPACES
        CURR I 2 CELLS * + @ .  6 SPACES
        CURR CELL+ I 2 CELLS * + @ .
        CR
        LOOP
        ;

\ validity / backup
CREATE BACKUP.ARRAY  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,

: BACKUP.CURR ( -- ) \ copy current array into backup array
        CURR BACKUP.ARRAY 8 CELLS CMOVE
        ;                               \ that was easy
: RESTORE.CURR
        BACKUP.ARRAY CURR 8 CELLS CMOVE
        ;


: SEE.BACK
        CR ." offset |  x  ,  y  " CR
        4 0 DO
        I 2 CELLS * .   8 SPACES
        BACKUP.ARRAY I 2 CELLS * + @ .  6 SPACES
        BACKUP.ARRAY CELL+ I 2 CELLS * + @ .
        CR
        LOOP
        ;



\\
        Should I store the points themselves OR just the point numbers ?
        Storing pairs seems always to get into a lot of SWAPing AND ROTing.
        Let's try storing offsets into the CURR array.

        Hold on a sec. here. To check whether there are any matches we neen
        to check c0=b0 ? c0=b1 ? c0=b2 ? c0=b3 ?
                 c1=b0 ? c1=b1 ? c1=b2 ? etc. etc. etc.
        sixteen combinations to check.

        COMP.NM  ( n m -- tf )
        Let's first make a general cross checking word for comparing a pair
        in CURRent with a pair in BACKUP. It should compare any xn,yn in
        CURR with any Xm,Ym in BACKUP. If they do NOT match an F flag should
        be left on the stack.

        CHECK   (  -- n OR nothing )
        The next level word could COMP all entries in BACKUP for each
        entry in CURR. If NO match is found ( no T flags ) THEN the offset
        for that entry in CURR is saved to stack.

        VALID?    ( nothing OR n0 n1 n2 n3 -- tf )
        The highest level word would THEN check all those entries on the
        stack for available space to move to, i.e. whether it is currently
        ASCII 219, AND return T IF valid.

        A left right OR rotate that is NOT valid is simply NOT performed,
        perhaps with a beep. CURR is restored  with BACKUP. A DOWN which is
        NOT valid is also NOT performed but triggers the end of movement for
        that figure, a check for full rows , etc.
{


: COMP.NM ( n m -- tf ) \ whether CURRnx=BACKmx  AND  CURRny=BACKmy
        2DUP                    \ n m n m --
        2 CELLS * BACKUP.ARRAY + @    \ n m n BACKmx --
        SWAP                    \ n m BACKmx n --
        2 CELLS * CURR +  @           \ n m BACKmx CURRnx --
        =                       \ n m tf --
        ROT ROT                 \ tf n m --
        2 CELLS * CELL+ BACKUP.ARRAY + @         \ tf n BACKmy
        SWAP                    \ tf BACKmy n
        2 CELLS * CELL+ CURR +   @      \ tf BACKmy CURRny
       =                        \ tf tf
       AND                      \ tf     only IF the x's are = AND y's are =
       ;

\\
        I don't find a Forth word to read the character at a certain screen
        position, I need this OR ELSE I will have to maintain some kind of
        separate array AND update it for every  move.

        BIOS int 10h sevice 8 reads attribute AND char at current cursor pos.
                input BH=page no.  AH=8
                output AL=character read (ASCII)  AH=Attribute(alphanumerics)

        GET-CHAR is a dialect / host prim (was DOS INT 10h CODE).

        This can be used with AT OR MY.AT to set the cursor, read the ASCII
        VALUE at tha position THEN return the cursor to the bottom of the
        screen out of the way of the game.

        VALID? takes the n's from the stack ( CURR entries w/o duplicates
        in BACK ) THEN uses GET-CHAR to check for ASCII, returning TRUE
        THEN ANDing, finally leaving a TRUE only IF all checks are true.

        It may be better to test each entry in CURR which does NOT have
        a match in BACK immediately. That is, it is valid IF matched OR
        IF open.
{

: CURR.OPEN?
        DUP 2 CELLS * CURR + @
        SWAP 2 CELLS * CELL+ CURR + @
        MY.AT GET-CHAR 219 =
        ;

: VALID?.CURR  ( -- tf ) \ check each entry in CURR for validity
        4 0 DO                  \ 0 1 2 3   the n's for CURR  J
         I 0 COMP.NM
         I 1 COMP.NM  OR
         I 2 COMP.NM  OR
         I 3 COMP.NM  OR        \ true IF any match for this n
         I CURR.OPEN?   OR      \ true IF match OR open
        LOOP AND AND AND        \ they ALL have to be valid
      0 23 AT                   \ move cursor
        ;

\\
        This combination looks much better that the separate words.
        No need to store the non-matches THEN go back AND look for
        openings. An entry is tested for match AND for opening.
        Then found valid IF there is a match OR an opening.
{

: DOWN.CURR  ( -- ) \ increase y's by one
        CURR CELL+ DUP @ 1 +  SWAP !
        CURR 3 CELLS + DUP @ 1 + SWAP !
        CURR 5 CELLS + DUP @ 1 + SWAP !
        CURR 7 CELLS + DUP @ 1 + SWAP !
        ;

 0 VALUE paused
 0 VALUE alldown

: DOWN
        paused alldown 0= AND ?EXIT
        BACKUP.CURR
        UNDRAW.CURR
        DOWN.CURR
        VALID?.CURR
        IF DRAW.CURR
        ELSE RESTORE.CURR DRAW.CURR
        THEN
        ;

: 2INC! ( -- ) \ increase variable by 2 (screen columns; NOT cell size)
        DUP @ 2 + SWAP !
        ;

: 2DEC! ( -- ) \ DEcrease variable by 2 (screen columns; NOT cell size)
        DUP @ 2 - SWAP !
        ;


: RIGHT.CURR  ( -- ) \ INcrease x's by 2
        CURR           2INC!
        CURR 2 CELLS + 2INC!
        CURR 4 CELLS + 2INC!
        CURR 6 CELLS + 2INC!
        ;

: RIGHT
        BACKUP.CURR
        UNDRAW.CURR
        RIGHT.CURR
        VALID?.CURR
        IF DRAW.CURR
        ELSE RESTORE.CURR DRAW.CURR
        THEN
        ;


: LEFT.CURR  ( -- ) \  DECrease x's by 2
        CURR           2DEC!
        CURR 2 CELLS + 2DEC!
        CURR 4 CELLS + 2DEC!
        CURR 6 CELLS + 2DEC!
        ;

: LEFT
        BACKUP.CURR
        UNDRAW.CURR
        LEFT.CURR
        VALID?.CURR
        IF DRAW.CURR
        ELSE RESTORE.CURR DRAW.CURR
        THEN
        ;


\\
        Keeping positions rather than vectors makes rotation more complicated.
        One way to do it is to calculate vectors, rotate vectors, the re-
        calculate positions.
{

: VECTOR.CURR ( n -- Dxn Dyn )
        CURR            \  n start of CURR array --
        SWAP 2 CELLS *  \ curr 2n cells --   offset to nth pair
        +               \ start of nth word
        DUP             \ start start
        @               \ start xn --
        SWAP            \ xn start
        CELL+ @         \ xn yn --
        CURR CELL+ @    \ xn yn y0 --
        -               \ xn Dy --
        SWAP            \ Dy xn --
        CURR @          \ Dy xn x0 --
        -               \ Dy Dx --
        SWAP            \ Dx Dy --
        ;

: RROT.VECTOR ( Dx Dy -- DX DY ) \ rotate right
        2*              \ Dx 2Dy
        NEGATE          \ Dx -2Dy
        SWAP            \ -2Dy Dx
        2/              \ -2Dy Dx/2   = new Dx Dy
        ;

: LROT.VECTOR ( Dx Dy -- DX DY ) \ rot left
        2*
        SWAP            \ 2Dy Dx
        2/
        NEGATE          \ 2Dy -Dx/2    new Dx Dy
        ;



: NEW.CURR ( Dx Dy n -- ) \ make new entry in CURR
        DUP >R >R       \ save n twice
        CURR
        2@  SWAP        \ Dx Dy x0 y0
        ROT             \ Dx x0 y0 Dy
        +               \ Dx x0 Yn
        ROT ROT         \ Yn Dx x0
        +               \ Yn Xn
        R>              \ Yn Xn n
        2 CELLS *       \ Yn Xn 2n cells
        CURR +          \ Yn Xn CURRnx
        !               \ Yn
        R>              \ Yn n
        2 CELLS * CELL+ \ Yn offst.ny
        CURR +          \ Yn CURRny
        !               \ --
        ;

: RROT.CURR
      4 1 DO
        I VECTOR.CURR
        RROT.VECTOR
        I NEW.CURR
      LOOP
        ;

: RROT
        BACKUP.CURR
        UNDRAW.CURR
        RROT.CURR
        VALID?.CURR
        IF DRAW.CURR
        ELSE RESTORE.CURR DRAW.CURR
        THEN
        ;

: LROT.CURR
        4 1 DO
        I VECTOR.CURR
        LROT.VECTOR
        I NEW.CURR
        LOOP
        ;

: LROT
        BACKUP.CURR
        UNDRAW.CURR
        LROT.CURR
        VALID?.CURR
        IF DRAW.CURR
        ELSE RESTORE.CURR DRAW.CURR
        THEN
        ;


\\
        On advantage of this vector method is that once the vector words
        were debugged left rotate followed trivially from right rotate
        AND both rotate words worked immediately for all figures.

        Now we need validity checking. Basicly we need to check whether
        drawing a figure into the proposed location would overwrite any
        existing figure - EXCEPT for the current figure. That is, it is ok
        AND common to overwrite part of the current figure.

        My original plan was to do modifications on an array called PROPOSED
        AND check it before writing into CURRent. But now that all the move-
        ment words are working, I hate to do that. So I think I will copy
        the current array into something like BACKUP before doing a move.
        Check the validity of CURRent before drawing it AND IF NOT valid
        restoring the previous values from the backup.

        Testing might be done thus: 1) look MY.AT each entry in current
        2) find those that are NOT also in backup 3) save those
        4) of those check IF the locations are clear 5) return a TRUE for
        valid OR a false for NOT valid.

        These testing words need to be moved to the beginning of the file
        to be used within the movement words.
{

\ : TEST ( n -- )
\         TO FIGURE.NO
\         FILL.CURR
\         DOWN
\         ;

5 VALUE TIME.LIMIT

: cnum 262  ;
: bnum cnum 15 * 16 / ;
: anum cnum 15 * 18 / ;
: gnum cnum 15 * 20 / ;
: fnum cnum 15 * 22 / ;
: enum cnum 15 * 24 / ;
: rest 30000 ;

CREATE NOTES 24 CELLS ALLOT
0 VALUE ncnt

: !,    ( n1 -- )
        NOTES ncnt + !
        ncnt CELL+ TO ncnt ;

: fill-notes            \ fill in the note array
        0 TO ncnt
     CNUM !, CNUM !, BNUM !, GNUM !, ANUM !, REST !,
     ANUM !, ANUM !, GNUM !, ENUM !, FNUM !, REST !,
     FNUM !, FNUM !, GNUM !, ANUM !, GNUM !, REST !,
     GNUM !, GNUM !, ANUM !, BNUM !, CNUM !, REST !, ;

\ original music by Marc Hawley. Rights reserved.


 0 VALUE NOTENUM
-1 VALUE sound_on

: MUSIC
        sound_on
        IF      NOTENUM NOTES + @ 1 TONE
                NOTENUM CELL+ 24 CELLS MOD TO NOTENUM
        ELSE    1 TENTHS
        THEN    ;

: whistle
        sound_on
        IF      8000 1 TONE
        THEN    ;


: MOVEMENT
        DOWN
        0 TO alldown
    BEGIN
        TIME-RESET
        BEGIN
     KEY?    \ host logs first KEY? on stderr
     IF
        KEY  CASE
                203 OF LEFT  whistle            ENDOF
                205 OF RIGHT whistle            ENDOF
                200 OF RROT  whistle            ENDOF
                208 OF LROT  whistle            ENDOF
                $20 OF -1 TO alldown            ENDOF
                $1B OF 0 23 AT BYE              ENDOF
                UPC
                [CHAR] S OF sound_on 0= TO sound_on  ENDOF
                [CHAR] P OF paused   0= TO paused    ENDOF
                DROP 1000 1 TONE ENDCASE
      THEN
                10TH-ELAPSED
                TIME.LIMIT >
                alldown OR
                UNTIL    DOWN
                alldown 0= IF MUSIC THEN
                BACKUP.CURR DOWN.CURR VALID?.CURR NOT RESTORE.CURR
                UNTIL
                  ;

0 VALUE ROW.NUM

: ROW.FULL? ( n -- tf ) \ check IF row n is full of 32 's   for a y vary x
        TO ROW.NUM                      \
        TRUE                            \ t
        20 0 DO                         \ t each x is I
        I ROW.NUM MY.AT                 \ t x y --
        GET-CHAR                        \ t ascii --
        32 =                            \ t tf --
        AND                             \ tf --
        LOOP
        ;                               \ TRUE IF FULL


0 VALUE SCORE
40 VALUE HIGH.SCORE   \ by M. Hawley 2-10-90
0 VALUE LEVEL

: ROW.DROP ( n  -- )                      \ use ROW.NUM
    TO ROW.NUM                          \ the row to be eliminated
      BEGIN
        20 0 DO                         \  x's    each x in the row
        I                               \ x --
        ROW.NUM 1-                      \ x y-1 --  the position above it
        MY.AT GET-CHAR                  \ ASCII     read that
        I ROW.NUM                       \ ascii x y --  write to space below
        MY.AT EMIT                      \ --
        LOOP                            \     next higher row
      ROW.NUM 1- DUP TO ROW.NUM         \ r   continue to zero
      1 < UNTIL
      80 2 TONE
      SCORE 1+ TO SCORE
      SCORE 10 / TO LEVEL
      5 LEVEL - TO TIME.LIMIT
      6 6 AT LEVEL .
       5 10 AT SCORE .
      SCORE HIGH.SCORE >
                IF SCORE TO HIGH.SCORE
                THEN
      3 16  AT HIGH.SCORE .
          ;

\\
        This is close. Appears to copy lower row onto upper.
{

: ROW.CHECK
        17 0 DO                         \ rows y
          I ROW.FULL?
          IF
             20 0 DO
              I J MY.AT 219 EMIT            \ whites the full row
             LOOP
          I ROW.DROP
          THEN
        LOOP
        ;

: SETUP
        0 TO SCORE
        27 0 AT ."    ***   T E T R A   ***"
        5 9 AT  ." *SCORE*"
        5 5 AT  ." *LEVEL*"
        6 6 AT   LEVEL  .
        3 12 AT ." you must score 10 "
        2 13 AT ." to move to next level"
        3 15 AT ." *HIGH SCORE*"
        3 16 AT HIGH.SCORE .
        55 13 AT ." Control With"
        55 14 AT ." Arrow Keys"
        55 16 AT ." DROP PIECE - SPACE"
        55 18 AT ." SOUND TGL  - S"
        55 19 AT ." PAUSE TGL  - P"
        55 17 AT ." QUIT       - ESC"
        55 10 AT ." by Marc Hawley"
        ;



\ End flag kept in a VALUE — do not leave VALID?.CURR on the stack across
\ MOVEMENT (IF/UNTIL pop a cell while testing X0; that leaked ~381 cells/piece).
0 VALUE dead?

: GAME
        fill-notes
      \ FIELD first (it CLSs). SETUP/BORDER paint labels around the field.
      \ End flag lives in VALUE dead? — never leave it under MOVEMENT on the
      \ stack (that leaked ~381 cells/piece into DSP → SIGBUS).
      FIELD SETUP BORDER
      BEGIN
        FIGURE.NO 1+ 6 MOD TO FIGURE.NO
        FILL.CURR
        BACKUP.CURR
        DOWN.CURR
        VALID?.CURR 0= TO dead?
        MOVEMENT
        ROW.CHECK
        dead?
      UNTIL
    ;

: MAIN
  S" TETRA" APP-NAME
  WINDOW
  GAME
  0
;
