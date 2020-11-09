
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
test_buf: .res 256
read_seg: .res 2

SECTORS = 35 * 16

.macro MESSAGE msg_
	lda #<(msg_)
	ldx #>(msg_)
	jsr boot_couts
.endmacro

.segment "ALIGN"
start:
	jsr $FD8E ; CROUT
	MESSAGE msg_start
	lda #0
	sta read_seg+0
	sta read_seg+1
	@loop:
		jsr test
		jsr invert
		jsr test
		jsr invert
		inc read_seg+0
		bne :+
			inc read_seg+1
		:
		lda read_seg+0
		cmp #<(SECTORS/2)
		lda read_seg+1
		sbc #>(SECTORS/2)
		bcc @loop
	jsr $FD8E ; CROUT
	MESSAGE msg_pass
	jmp $FF69 ; MONZ monitor * prompt

invert:
	lda #<(SECTORS-1)
	sec
	sbc read_seg+0
	sta read_seg+0
	lda #>(SECTORS-1)
	sbc read_seg+1
	sta read_seg+1
	rts

test:
	jsr $FE80 ; SETINV
	lda read_seg+1
	jsr $FDDA ; PRBYTE
	lda read_seg+0
	jsr $FDDA
	jsr $FE84 ; SETNORM
	; read the sector
	lda #<test_buf
	sta disksys_ptr+0
	lda #>test_buf
	sta disksys_ptr+1
	lda read_seg+0
	ldx read_seg+1
	ldy #1
	jsr disksys_read
	lda test_buf+0
	jsr $FDDA
	lda disksys_error
	jsr $FDDA
	lda disksys_error
	bne fail
	rts
fail:
	jsr $FD8E
	MESSAGE msg_fail
	jmp $FF69

msg_start:
	.byte "SEEK TEST READS EVERY SECTOR ON DISK", 13
	.byte "0123 SECTOR NUMBER", 13
	.byte "  23 DATA (6+ IS SAME AS SECTOR LSB)", 13
	.byte "  00 ERROR (SHOULD BE 00)", 0
msg_fail:  .asciiz "FAIL!"
msg_pass:  .asciiz "PASS"

; fill rest of MAIN with sector number
.align 256
.repeat 90, I
	.repeat 256, J
		.byte <(((*-MPOS)>>8)+BSEC)
	.endrepeat
.endrepeat

; fill EXTRA with sector number
.segment "EXTRA"
.repeat 560-96, I
	.repeat 256, J
		.byte <(*>>8)
	.endrepeat
.endrepeat
