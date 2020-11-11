; a2p_seek
;
; Test of disk read and seek routines.
; Fills the whole disk with numbered sectors.
; Reads all 16 sectors from each track.
; Jumps between tracks in a zipper pattern: 0, 34, 1, 33, 2, 32, etc.
; The jumping tests longer seeks across the disk.

.export start
.exportzp disk_ptr
.exportzp disk_temp

.import disk_read
.import disk_error
.import boot_couts
.import MPOS
.import BSEC

.segment "ZEROPAGE"
disk_ptr: .res 2
disk_temp: .res 2

.segment "LOWRAM"
test_buf: .res 256
read_seg: .res 1
read_track: .res 1
read_combo: .res 2

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
	sta read_seg
	sta read_track
	@loop:
		jsr test
		jsr pick_next
		lda read_track
		cmp #35
		bcc @loop
	jsr $FD8E ; CROUT
	MESSAGE msg_pass
	jmp $FF69 ; MONZ monitor * prompt

track_order:
.repeat 17, I
	.byte I
	.byte 34-I
.endrepeat
	.byte 17

pick_next:
	inc read_seg
	lda read_seg
	cmp #16
	bcc :+
		inc read_track
		lda #0
		sta read_seg
	:
	rts

test:
	ldx read_track
	lda track_order, X
	asl
	asl
	asl
	asl
	ora read_seg
	sta read_combo+0
	lda track_order, X
	lsr
	lsr
	lsr
	lsr
	sta read_combo+1
	jsr $FE80 ; SETINV
	lda read_combo+1
	jsr $FDDA ; PRBYTE
	lda read_combo+0
	jsr $FDDA
	jsr $FE84 ; SETNORM
	; read the sector
	lda #<test_buf
	sta disk_ptr+0
	lda #>test_buf
	sta disk_ptr+1
	lda read_combo+0
	ldx read_combo+1
	ldy #1
	jsr disk_read
	lda test_buf+0
	jsr $FDDA
	lda disk_error
	jsr $FDDA
	lda disk_error
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
