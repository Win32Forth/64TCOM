\ ASMGEN.fth — Stub assembler vocabulary for 64TCOM GEN
\
\ Public domain.
\ Classic analogue: tcom25/TCOMGEN/ASMGEN.FTH
\
\ GEN does not encode real machine instructions. This file provides a
\ lightweight ASMGEN vocabulary and no-op assembler lifecycle words so
\ CODE-shaped definitions and OPTGEN hooks have something to call.
\
\ Requires: 64HOST.fth already loaded.

TCOM-ANEW ASMGEN

FORTH DEFINITIONS
DECIMAL

VOCABULARY ASMGEN
: [ASMGEN]  ( -- )  ASMGEN ; IMMEDIATE

\ Assembler lifecycle (stubs)
FALSE VALUE ?ASM-ACTIVE

DEFER SETASSEM
DEFER A;
DEFER END-CODE

: (SETASSEM)  ( -- )
  TRUE TO ?ASM-ACTIVE
  ALSO ASMGEN
  ;
' (SETASSEM) IS SETASSEM

: (A;)  ( -- )
  \ classic a; finishes an instruction — nothing for GEN
  ;
' (A;) IS A;

: (END-CODE)  ( -- )
  ?ASM-ACTIVE IF  PREVIOUS  FALSE TO ?ASM-ACTIVE  THEN
  ;
' (END-CODE) IS END-CODE

\ Aliases used by classic sources
: C;  ( -- )  END-CODE ; IMMEDIATE

\ Local-label style no-ops (real labels arrive with a real assembler later)
: LLAB-INIT   ( -- )  ;
: LL-GLOBAL?  ( -- flag )  FALSE ;
: LL-ERRS?    ( -- )  ;
: LLSET-      ( -- )  ;

\ Emit helpers that write into the *target* image (via 64HOST), not host HERE.
\ Used if someone assembles “bytes” under GEN.
: IC,  ( b -- )  C,-T ;     \ first/opcode-ish byte
: OC,  ( b -- )  C,-T ;     \ other bytes
: CC,  ( b -- )  C,-T ;     \ call opcode byte (GEN: same)
: O,   ( x -- )  ,-T  ;     \ cell-sized operand

: .ASMGEN  ( -- )
  CR ." ASMGEN: stub assembler for 64TCOM GEN  active=" ?ASM-ACTIVE . CR
  ;

FORTH DEFINITIONS
." ASMGEN loaded." CR
