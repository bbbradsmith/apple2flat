; video_double_high_color_notext
;
; Video driver for double high resolution colour with no text support

.export video_mode_double_high_color_notext
.export _video_mode_double_high_color_notext

.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup

.import video_mode_set_double_high_color
.import video_page_copy_double_high
.import video_cls_double_high
.import video_null
.import draw_pixel_double_high_color
.import draw_getpixel_double_high_color
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.proc video_mode_double_high_color_notext
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_color
	.word video_page_copy_double_high
	.word video_cls_double_high
	.word video_null ; text_out
	.word video_null ; text_copy_row
	.word video_null ; text_clear_row
	.word draw_pixel_double_high_color
	.word draw_getpixel_double_high_color
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word 140
	.byte 192
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_color_notext()
_video_mode_double_high_color_notext = video_mode_double_high_color_notext
