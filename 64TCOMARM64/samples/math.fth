\ math.fth — helpers included by other target sources (FLOAD)
\
\ Not a standalone program (no MAIN). Built only via FLOAD from another .fth.

: DOUBLE
  DUP +
;

: SQUARE
  DUP *
;
