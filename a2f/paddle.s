; paddles
;
; paddle axis and buttons

.include "../a2f.inc"

.export paddle_buttons_poll ; poll just paddle buttons
.export paddle0_poll ; poll paddle 0 + buttons
.export paddle01_poll ; poll both paddles and buttons

; variables updated by polling
.export paddle_buttons
.export paddle0_x
.export paddle0_y
.export paddle1_x
.export paddle1_y

.segment "CODE"
paddle_buttons: .byte 0
paddle0_x: .byte 128
paddle0_y: .byte 128
paddle1_x: .byte 128
paddle1_y: .byte 128

.assert paddle1_x = paddle0_x + 2, error, "paddle1 result must be 2 bytes after paddle0"
.assert paddle1_y = paddle0_y + 2, error, "paddle1 result must be 2 bytes after paddle0"

.segment "ALIGN"

.align 32
.proc paddle_poll_aligned_
	; X = 0 (paddle 0) or 2 (paddle 1)
	; Y = 0
@loop: ; 43 cycle loop
	; X axis increment
	lda $C064, X
	asl
	lda #0
	adc a2f_temp+0
	sta a2f_temp+0
	; Y axis increment
	lda $C065, X
	asl
	lda #0
	adc a2f_temp+1
	sta a2f_temp+1
	; early exit if both axes finished
	lda $C064, X
	ora $C065, X
	bpl @finish
	iny
	bpl @loop ; timeout at 128
	.assert >(@loop) = >*, error, "Page crossed!"
	.assert (*-@loop)<32, error, "paddle_poll_aligned_ loop may not cross 32 byte alignment."
	; NOTE: alignment isn't critical for this to work, but it gives a tiny bit of extra consistency
@finish:
	rts
.endproc

.segment "CODE"

paddle_buttons_poll:
	ldx #0
	stx paddle_buttons
	lda $C063
	asl
	rol paddle_buttons
	lda $C062
	asl
	rol paddle_buttons
	lda $C061
	asl
	rol paddle_buttons
	lda paddle_buttons
	rts ; result in X:A for C calls

paddle01_poll:
	ldx #2
	jsr paddle_poll_ ; poll axes 2,3 (X=2)
paddle0_poll:
	; poll buttons first to allow extra discharge time before next read
	jsr paddle_buttons_poll ; NOTE: result X=0
	; poll axes 0,1 (X=0)
paddle_poll_:
	; pre-charge read: make sure both axes have returned to 0 (or timeout)
	ldy #0
	jsr paddle_poll_aligned_
	cpy #128
	bcs @timeout ; Y=128 indicates timeout, likely no paddle attached
	; charge capacitors (NOTE: PREAD waits at least 6 cycles before first poll after charge)
	lda $C070
	; reset counters
	ldy #0
	sty a2f_temp+0
	sty a2f_temp+1
	; read the axes
	; Y=0
	jsr paddle_poll_aligned_
	; store the result
	lda a2f_temp+0
	sta paddle0_x, X
	lda a2f_temp+1
	sta paddle0_y, X
	rts
@timeout:
	tya
	sta paddle0_x, X
	sta paddle0_y, X
	rts
