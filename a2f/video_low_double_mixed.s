; video_low_double_mixed
;
; Video driver for low resolution + double (80 column) mixed text

.include "../a2f.inc"

.export video_mode_low_double_mixed
.export _video_mode_low_double_mixed

.import video_page_copy_low
.import video_page_copy_double_mixed
.import video_page_apply
.import text_out_double_text
.import text_copy_row_double_text
.import text_clear_row_double_text
.import draw_pixel_low
.import draw_getpixel_low

.import video_mode_setup
.import video_mode_mixed_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp draw_ptr

.proc video_mode_low_double_mixed
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jsr video_mode_mixed_setup
	asl video_text_w ; 40 << 1 = 80
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_low_double_mixed
	.word video_page_copy_low_double_mixed
	.word video_cls_low_double_mixed
	.word text_out_double_text
	.word text_copy_row_double_text
	.word text_clear_row_double_text
	.word draw_pixel_low
	.word draw_getpixel_low
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word 40
	.byte 40
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_low_double_mixed()
_video_mode_low_double_mixed = video_mode_low_double_mixed

.proc video_mode_set_low_double_mixed
	sta $C050 ; graphics mode (TEXT)
	sta $C056 ; low-res (HIRES)
	sta $C052
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00D ; 80 columns (80COL)
	sta $C05E ; RGB 11 = color
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	sta $C053 ; mixed (MIXED)
	jmp video_page_apply
.endproc

.proc video_cls_low_double_mixed
	; reset cursor
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	; clear graphics
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #0
	jsr video_cls_page ; NOTE: mixed text area will be briefly filled with @ (0)
	; clear mixed text
	lda video_page_w
	and #1
	eor #CLS_DMIXED0
	tax
	lda #$A0 ; space, normal
	jmp video_cls_page
.endproc

.proc video_page_copy_low_double_mixed
	jsr video_page_copy_low
	jmp video_page_copy_double_mixed
.endproc
