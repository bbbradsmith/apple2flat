; brk_fatal / brk_message
;
; Like exit but triggered by a BRK instruction.
; Load the address of brk_fatal to $3F0 (BRKV) before using.
; If replaced with brk_message, a message from brk_message_ptr will be printed instead of "BRK".

.export brk_fatal
; PCL/PCH location of BRK (+2) stored by monitor
; Works like exit but prints "BRK" then the program counter

.export brk_message
; brk_message_ptr pointer to message
; Does brk_fatal with that message instead of BRK

.exportzp brk_message_ptr
; ZP pointer for message to print

.import exit_common_start
.import exit_common_end

brk_message_ptr = $06 ; 2 bytes on ZP the monitor doesn't use

brk_message_brk:
.asciiz "BRK"

brk_couts: ; prints a string to monitor's COUT
	ldy #0
	:
		lda (brk_message_ptr), Y
		beq :+
		ora #$80
		jsr $FDED ; COUT
		iny
		bne :-
	:
	jmp $FD8E ; CROUT newline

brk_fatal:
	lda #<brk_message_brk
	sta brk_message_ptr+0
	lda #>brk_message_brk
	sta brk_message_ptr+1
brk_message:
	lda $3A ; PCL
	sec
	sbc #<2
	pha
	lda $3B ; PCH
	sbc #>2
	pha
	jsr exit_common_start
	jsr brk_couts
	jmp exit_common_end
