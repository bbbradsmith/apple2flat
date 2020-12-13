; video_text
;
; Video driver for text mode

.include "../a2f.inc"

.export video_mode_text
.export _video_mode_text

.export video_cls_text
.export text_out_text
.export text_scroll_text
.export draw_pixel_text
.export draw_getpixel_text

.import video_cls_page

.import video_rowpos0
.import video_rowpos1
.import video_null
.import video_function_table_copy
.import VIDEO_FUNCTION_MAX

.import text_inverse
.import draw_y
.import draw_y0
.import draw_y1
.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1

TEXT_CLEAR = $A0 ; space, normal

.proc video_mode_text
	lda #<table
	ldx #>table
	jsr video_function_table_copy
	; TODO set video registers
	rts
table:
	.word video_cls_text
	.word text_out_text
	.word text_scroll_text
	.word draw_pixel_text
	.word draw_getpixel_text
	.word video_null ; draw_hline
	.word video_null ; draw_vline
	.word video_null ; draw_box
	.word video_null ; draw_fillbox
	.word video_null ; blit_tile
	.word video_null ; blit_coarse
	.word video_null ; blit_fine
	.word video_null ; blit_mask
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_text()
_video_mode_text = video_mode_text

.proc video_cls_text
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #TEXT_CLEAR
	jmp video_cls_page
.endproc

text_out_text:
	eor text_inverse
draw_pixel_text:
	; X/Y = coordinate
	; A = value
	cpx #40
	bcs :+
	cpy #24
	bcs :+
	pha
	lda video_page_w
	and #$0C
	eor #$04 ; $04 or $08
	ora video_rowpos1, Y
	sta draw_ptr+1
	txa
	clc
	adc video_rowpos0, Y
	sta draw_ptr+0
	ldy #0
	pla
	sta (draw_ptr), Y
:
	rts

.proc draw_getpixel_text
	; X/Y = coordinate
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, Y
	sta draw_ptr+1
	txa
	clc
	adc video_rowpos0, Y
	sta draw_ptr+0
	lda (draw_ptr), Y
	rts
.endproc

.proc text_copy_row_text
	; X = copy to
	; Y = copy from
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, X
	sta draw_ptr0+1
	lda video_rowpos0, X
	sta draw_ptr0+0
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, Y
	sta draw_ptr1+1
	lda video_rowpos0, Y
	sta draw_ptr1+0
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		lda (draw_ptr1), Y
		sta (draw_ptr0), Y
		iny
		jmp :-
	:
	rts
.endproc

.proc text_clear_row_text
	; X = row to clear
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, X
	sta draw_ptr+1
	lda video_rowpos0, X
	sta draw_ptr+0
	lda #TEXT_CLEAR
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		sta (draw_ptr), Y
		iny
		jmp :-
	:
	rts
.endproc

.proc text_scroll_text
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
		ldx draw_y0
		txa
		clc
		adc lines
		cmp video_text_h
		bcs :+
		tay
		jsr text_copy_row_text
		inc draw_y0
		jmp :-
	:
	ldx video_text_h
	dex
	stx draw_y0
	:
		ldx draw_y0
		jsr text_clear_row_text
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
		ldx draw_y0
		txa
		clc
		adc lines
		bmi :+ ; in case yr=0
		cmp video_text_yr
		bcc :+
		tay
		jsr text_copy_row_text
		dec draw_y0
		jmp :-
	:
	ldx video_text_yr
	stx draw_y0
	:
		ldx draw_y0
		jsr text_clear_row_text
		inc draw_y0
		inc lines ; count up to 0
		bne :-
	rts
.endproc
