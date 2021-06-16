; text
;
; Some shared routines for text output.
;   text_out
;   text_outs
;   text_charset

.export text_out
.export text_outs
.export text_charset
.export text_scroll

.export video_text_x
.export video_text_y
.export video_text_w
.export video_text_h
.export video_text_xr
.export video_text_yr
.export text_inverse

.import draw_xh
.importzp draw_ptr
.import draw_y0
.import draw_y1

.import text_out_
.import text_copy_row
.import text_clear_row

video_text_x:  .word 0
video_text_y:  .byte 0
video_text_w:  .word 40
video_text_h:  .byte 24
video_text_xr: .word 0
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
		lda video_text_xr+0
		sta video_text_x+0
		lda video_text_xr+1
		sta video_text_x+1
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
	pha
	ldx video_text_x+0
	cpx video_text_w+0
	lda video_text_x+1
	sta draw_xh
	sbc video_text_w+1
	bcc :+ ; wrap to next line
		ldx video_text_xr+0
		stx video_text_x+0
		lda video_text_xr+1
		sta video_text_x+1
		sta draw_xh
		inc video_text_y
	:
	ldy video_text_y
	cpy video_text_h
	bcc :+ ; scroll and keep to bottom
		ldy video_text_h
		dey
		sty video_text_y
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
	:
	pla
	jsr text_out_
	inc video_text_x+0
	bne :+
		inc video_text_x+1
	:
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

.proc text_charset
	and #1
	tax
	sta $C00E, X
	rts
.endproc

.proc text_scroll
	; A = number of lines to scroll (signed)
lines = draw_y1
	sta lines
	cmp #0
	beq scroll_none
	bmi scroll_up
scroll_down:
	lda video_text_yr
	sta draw_y0
	:
		ldy draw_y0
		tya
		clc
		adc lines
		cmp video_text_h
		bcs :+
		tax
		jsr text_copy_row
		inc draw_y0
		jmp :-
	:
	ldx video_text_h
	dex
	stx draw_y0
	:
		ldx draw_y0
		jsr text_clear_row
		dec draw_y0
		dec lines
		bne :-
	;rts
scroll_none:
	rts
scroll_up:
	ldx video_text_h
	dex
	stx draw_y0
	:
		ldy draw_y0
		tya
		clc
		adc lines
		bmi :+ ; in case yr=0
		cmp video_text_yr
		bcc :+
		tax
		jsr text_copy_row
		dec draw_y0
		jmp :-
	:
	ldx video_text_yr
	stx draw_y0
	:
		ldx draw_y0
		jsr text_clear_row
		inc draw_y0
		inc lines ; count up to 0
		bne :-
	rts
.endproc
