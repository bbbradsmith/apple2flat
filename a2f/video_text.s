; video_text
;
; Video driver for text mode

.include "../a2f.inc"

.export video_mode_text
.export _video_mode_text

; shared for mixed/double modes
.export text_out_text
.export text_copy_row_text
.export text_copy_row_draw_ptr0_draw_ptr1
.export text_clear_row_text
.export text_clear_row_draw_ptr0
.export text_row_addr_x_draw_ptr0
.export text_row_addr_y_draw_ptr1
.export draw_pixel_text_addr
.export draw_pixel_text
.export draw_getpixel_text

.import video_cls_page
.import video_page_copy_low
.import video_page_apply

.import video_rowpos0
.import video_rowpos1
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
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

.proc video_mode_text
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_mode_set_text
	.word video_page_copy_low
	.word video_cls_text
	.word text_out_text
	.word text_copy_row_text
	.word text_clear_row_text
	.word draw_pixel_text
	.word draw_getpixel_text
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_text()
_video_mode_text = video_mode_text

.proc video_mode_set_text
	; set mode
	sta $C051 ; text mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C056 ; low-res (HIRES)
	; double/RGB settings
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00C ; 40 columns (80COL)
	sta $C05E ; RGB 00 = mono
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	jmp video_page_apply
.endproc

.proc video_cls_text
	; reset cursor
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	; clear page
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #$A0 ; space, normal
	jmp video_cls_page
.endproc

.proc draw_pixel_text_addr ; X/Y coordinate to draw_ptr, clobbers A
	lda video_page_w
	and #$0C
	eor #$04 ; $04 or $08
	ora video_rowpos1, Y
	sta draw_ptr+1
	txa
	clc
	adc video_rowpos0, Y
	sta draw_ptr+0
	rts
.endproc

.proc text_row_addr_x_draw_ptr0 ; X = row to draw_ptr0, clobbers A
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, X
	sta draw_ptr0+1
	lda video_rowpos0, X
	sta draw_ptr0+0
	rts
.endproc

.proc text_row_addr_y_draw_ptr1 ; Y = row to draw_ptr1, clobbers A
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, Y
	sta draw_ptr1+1
	lda video_rowpos0, Y
	sta draw_ptr1+0
	rts
.endproc

text_out_text:
	eor text_inverse
draw_pixel_text:
	; X/Y = coordinate
	; A = value
	pha
	jsr draw_pixel_text_addr
	ldy #0
	pla
	sta (draw_ptr), Y
	rts

.proc draw_getpixel_text
	; X/Y = coordinate
	jsr draw_pixel_text_addr
	ldy #0
	lda (draw_ptr), Y
	rts
.endproc

text_copy_row_text:
	; X = copy from
	; Y = copy to
	jsr text_row_addr_x_draw_ptr0
	jsr text_row_addr_y_draw_ptr1
text_copy_row_draw_ptr0_draw_ptr1:
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		lda (draw_ptr0), Y
		sta (draw_ptr1), Y
		iny
		jmp :-
	:
	rts

text_clear_row_text:
	; X = row to clear
	jsr text_row_addr_x_draw_ptr0
text_clear_row_draw_ptr0:
	lda #$A0 ; space, normal
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		sta (draw_ptr0), Y
		iny
		jmp :-
	:
	rts
