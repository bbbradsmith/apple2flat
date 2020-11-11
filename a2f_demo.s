
.export start
.exportzp disksys_ptr
.exportzp disksys_temp

.import disksys_read
.import disksys_error
.import boot_couts
.import MPOS
.import BSEC

.segment "ZEROPAGE"
disksys_ptr: .res 2
disksys_temp: .res 2

.segment "LOWRAM"


.segment "CODE"

start:
	lda #<message
	ldx #>message
	jsr couts
	jmp $FF69 ; MONZ

message:
	.asciiz "YOU ARE READING THIS!"

.proc couts
; X:A = pointer to ASCII string to print, 0 terminated
	ptr = $06 ; any 2 ZP bytes not used by COUT
	sta ptr+0
	stx ptr+1
	ldy #0
	:
		lda (ptr), Y
		beq :+
		ora #$80
		jsr $FDED ; COUT monitor output character
		iny
		jmp :-
	:
	jmp $FD8E ; CROUT monitor output newline
.endproc
