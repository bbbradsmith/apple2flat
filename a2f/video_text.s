; video_text
;
; Video driver for text mode

.include "../a2f.inc"

.export video_mode_text
.export _video_mode_text

; shared for mixed modes
.export text_out_text
.export text_scroll_text

.import video_cls_page
.import video_page_copy_low
.import video_page_apply

.import video_rowpos0
.import video_rowpos1
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_MAX
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.import text_inverse
.import draw_y
.import draw_y0
.import draw_y1
.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1

TEXT_CLEAR = $A0 ; space, normal

.proc video_mode_text
	lda #40
	sta video_text_w
	lda #24
	sta video_text_h
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_page_text
	.word video_page_copy_low
	.word video_cls_text
	.word text_out_text
	.word text_scroll_text
	.word draw_pixel_text
	.word draw_getpixel_text
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word video_null ; blit_coarse
	.word video_null ; blit_fine
	.word video_null ; blit_mask
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_text()
_video_mode_text = video_mode_text

.proc video_page_text
	; TODO: disable IIe double resolution features
	;sta $C00C ; 40-column display (80COL)
	;sta $C000 ; disable 80-column paging (80STORE)
	;sta $C05F ; disable double resolution
	; TODO: what dpes IOUDIS do?
	; set text mode
	sta $C052 ; non-mixed (MIXED)
	sta $C051 ; text mode (TEXT)
	jmp video_page_apply
.endproc

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
	ldy #0
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
