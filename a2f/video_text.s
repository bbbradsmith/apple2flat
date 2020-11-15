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
.importzp draw_ptr

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
	lda #$A0 ; space, normal
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
	rts

draw_getpixel_text:
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

.proc text_scroll_text
	; TODO
	rts
.endproc
