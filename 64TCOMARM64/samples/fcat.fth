\ fcat.fth — file read sample (OPEN-R READ CLOSE)
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/fcat.fth
\   ./samples/fcat samples/hello.fth
\
\ Exit 0 ok, 1 usage, 2 open fail.
\ TWHILE treats TOS as flag and keeps under as new TOS — keep a pad 0 under the loop.

VARIABLE FD
VARIABLE N

: MAIN
  ARGCOUNT 1 =
  IF
    ARG1 OPEN-R
    DUP FD !
    DUP 0 <
    IF
      DROP
      S" fcat: cannot open
" ETYPE
      2
    ELSE
      0
      BEGIN
        DROP
        LINE-BUF 200 FD @ READ
        DUP N !
      WHILE
        LINE-BUF N @ TYPE
        0
      REPEAT
      DROP
      FD @ CLOSE DROP
      0
    THEN
  ELSE
    S" usage: fcat file
" ETYPE
    1
  THEN
;
