; video_high_color_vwf
;
; Video driver for high resolution colour with variable width font

.include "../a2f.inc"

.export video_mode_high_color_vwf
.export _video_mode_high_color_vwf

.import video_page_apply
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import draw_hline_generic
.import draw_fillbox_generic

.import video_mode_set_high_color
.import video_page_copy_high
.import video_cls_high
.import text_out_high_vwf
.import text_copy_row_high_vwf
.import text_clear_row_high_vwf
.import draw_pixel_high_color
.import draw_getpixel_high_color
.import draw_vline_high_color

.proc video_mode_high_color_vwf
	lda #<table
	ldx #>table
	jsr video_mode_setup
	lda #<280
	sta video_text_w+0
	lda #>280
	sta video_text_w+1
	rts
table:
	.word video_mode_set_high_color
	.word video_page_copy_high
	.word video_cls_high
	.word text_out_high_vwf
	.word text_copy_row_high_vwf
	.word text_clear_row_high_vwf
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.word 140
	.byte 192
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_color_vwf()
_video_mode_high_color_vwf = video_mode_high_color_vwf
