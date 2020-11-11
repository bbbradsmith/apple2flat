; crt0
;
; This provides the pre-main setup for C programs, and then calls main().
; NOTE: void main() or int main() is expected
;   int main(argc,argv) should not fail, but argc=argv=0 and the C-stack may shift upward by 4 bytes.
;
; For assembly-only programs:
;   If start and a2f_temp are exported before this library is loaded,
;   this module will be ignored and no C code will be executed.

.include "../a2f.inc"
.include "zeropage.inc"

.export start
.exportzp a2f_temp

.export _exit
.export __STARTUP__ : absolute = 1 ; CC65 will forceimport this from main()

.import __STACKSIZE__
.import zero_initialize
.import _main
.import exit

.segment "ZEROPAGE"
a2f_temp = ptr3
.assert ptr4 = (ptr3+2), error, "cc65 zeropage variable ptr4 not contiguous with ptr3?"

.segment "CODE"

start:
	; clear uninitialized RAM areas (except stack)
	jsr zero_initialize
	STACK_INITIALIZE
	; set C-stack position (lower half of hardware stack)
	lda #<($100 + __STACKSIZE__)
	ldx #>($100 + __STACKSIZE__)
	sta sp+0
	stx sp+1
	; NOTES vs standard cc65 crt0:
	;  zerobss - already taken care of by zero_initialize
	;  initlib/donelib - CONDES features not needed
	;  callmain - no command line, no arguments
	; call int main()
	lda #0
	tax
	tay
	jsr _main
	jmp exit

_exit = exit ; C access to exit
