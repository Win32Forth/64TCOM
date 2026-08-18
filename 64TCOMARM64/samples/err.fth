\ err.fth — stderr sample (ETYPE)
\
\   FLOAD TARGETARM64.fth
\   TCOM-CLI samples/err.fth
\   ./samples/err           → message on stderr, exit 1
\   ./samples/err 2>/tmp/e  → /tmp/e has the message

: MAIN
  S" error: this is stderr
" ETYPE
  1
;
