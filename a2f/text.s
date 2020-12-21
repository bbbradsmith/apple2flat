; text
;
; Some shared routines for text output.
;   text_out
;   text_outs

.export text_out
.export text_outs

.export video_text_x
.export video_text_y
.export video_text_w
.export video_text_h
.export video_text_xr
.export video_text_yr
.export text_inverse

.importzp draw_ptr
.import text_out_
.import text_scroll

video_text_x:  .byte 0
video_text_y:  .byte 0
video_text_w:  .byte 40
video_text_h:  .byte 24
video_text_xr: .byte 0
video_text_yr: .byte 0
text_inverse:  .byte $80

.proc text_out
	; A = ASCII character to print
	;     13 = newline
	;     14 = shift to normal
	;     15 = shift to inverse
	; Advances text out position.
	cmp #$20 ; first 32 values are considered control codes
	bcs ready
	cmp #10 ; newline
	bne :+
		lda video_text_xr
		sta video_text_x
		inc video_text_y
		rts
	:
	cmp #14 ; normal
	bne :+
		lda #$80
		sta text_inverse
		rts
	:
	cmp #15 ; inverse
	bne :+
		lda #$00
		sta text_inverse
		rts
	:
	; allow other control codes to pass through?
ready:
	ldx video_text_x
	cpx video_text_w
	bcc :+ ; wrap to next line
		ldx video_text_xr
		stx video_text_x
		inc video_text_y
	:
	ldy video_text_y
	cpy video_text_h
	bcc :+ ; scroll and keep to bottom
		ldy video_text_h
		dey
		sty video_text_y
		pha
		txa
		pha
		tya
		pha
		lda #1
		jsr text_scroll
		pla
		tay
		pla
		tax
		pla
	:
	jsr text_out_
	inc video_text_x
	rts
.endproc

.proc text_outs
	sta draw_ptr+0
	stx draw_ptr+1
	tay ; keep pointer on stack to avoid conflicts with text_scroll in text_out
	txa
	pha
	tya
	pha
	jmp @enter
	@loop:
		jsr text_out
		pla
		clc
		adc #<1
		sta draw_ptr+0
		tay
		pla
		adc #>1
		sta draw_ptr+1
		pha
		tya
		pha
	@enter:
		ldy #0
		lda (draw_ptr), Y
		bne @loop
	pla
	pla
	rts
.endproc
