; video_high_color_notext
;
; Video driver for high resolution colour with no text support

.export video_mode_high_color_notext
.export _video_mode_high_color_notext

.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE

.import video_mode_set_high_color
.import video_page_copy_high
.import video_cls_high
.import video_null
.import draw_pixel_high_color
.import draw_getpixel_high_color
.import draw_vline_high_color
.import draw_hline_generic
.import draw_fillbox_generic
.import blit_high_color

.proc video_mode_high_color_notext
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_mode_set_high_color
	.word video_page_copy_high
	.word video_cls_high
	.word video_null ; text_out
	.word video_null ; text_copy_row
	.word video_null ; text_clear_row
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.word blit_high_color
	.word 140
	.byte 192
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_color_notext()
_video_mode_high_color_notext = video_mode_high_color_notext
