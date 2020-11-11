; TODO A2F library public interface

; disk_error codes
DISK_ERROR_FIND    = $01 ; could not find sector
DISK_ERROR_DATA    = $02 ; found sector, but could not find data field
DISK_ERROR_PARTIAL = $04 ; sector read but only partially correct (checksum fail)

.globalzp a2f_temp ; 4 bytes of temporary space on zero-page
.globalzp disk_ptr ; parameter for disk_read, alias of a2f_temp
.global disk_error ; last error code from disk routine

.global exit ; X:A = exit code, prints error code and enters monitor * prompt
.global zero_intialize ; call at start to clear uninitialized RAM regions (not including stack, use STACK_INITIALIZE instead)
.global disk_read ; X:A = segment to read, Y = segment count, disk_ptr = destination, returns disk_error

; user after zero_initialize to set up the stack
.macro STACK_INITIALIZE
	ldx #0
	txa
	:
	sta $100, X
	inx
	bne :-
	dex ; $FF
	txs
.endmacro
