; video_double_text
;
; Video driver for 80 column text mode

.include "../a2f.inc"

.export video_mode_double_text
.export _video_mode_double_text

.import video_page_copy_double_low
.import video_page_apply
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.import video_double_read_aux
.import video_double_write_aux
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.import draw_pixel_text
.import draw_getpixel_text
.import draw_pixel_text_addr

.proc video_mode_double_text
	lda #<table
	ldx #>table
	jsr video_mode_setup
	asl video_text_w ; 40 << 1 = 80
	jmp video_double_rw_aux_setup
table:
	.word video_page_double_text
	.word video_page_copy_double_low
	.word video_cls_double_text
	.word text_out_double_text
	.word text_out_double_scroll_text
	.word draw_pixel_double_text
	.word draw_getpixel_double_text
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_text()
_video_mode_double_text = video_mode_double_text

.proc video_page_double_text
	sta $C051 ; text mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C056 ; low-res (HIRES)
	sta $C00D ; 80 columns (80COL)
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C05F ; double-hires off (AN3/DHIRES)
	jmp video_page_apply
.endproc

.proc video_cls_double_text
	; reset cursor
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	lda video_page_w
	; clear page
	and #1
	eor #CLS_DLOW0
	tax
	lda #$A0 ; space, normal
	jmp video_cls_page
.endproc

.proc text_out_double_scroll_text
	; TODO
	rts
.endproc

text_out_double_text:
	eor text_inverse
draw_pixel_double_text: ; A = value, X/Y = coordinate
	pha
	txa
	lsr
	tax
	bcs :+
		sta $C005 ; aux (RAMWRT)
		pla
		jsr draw_pixel_text
		sta $C004 ; main (RAMWRT)
		rts
	:
		pla
		jmp draw_pixel_text
	;

.proc draw_getpixel_double_text ; A/Y = coordinate
	txa
	lsr
	tax
	bcs :+
		jsr draw_pixel_text_addr
		ldy #0
		jmp video_double_read_aux
	:
		jmp draw_getpixel_text
	;
.endproc
