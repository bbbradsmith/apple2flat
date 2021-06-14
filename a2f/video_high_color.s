; video_high_color
;
; Video driver for high resolution colour

.include "../a2f.inc"

.export video_mode_high_color
.export _video_mode_high_color

.import video_page_apply
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import draw_hline_generic
.import draw_fillbox_generic

.import video_mode_set_high_color
.import video_page_copy_high
.import video_cls_high
.import text_out_high
.import text_copy_row_high
.import text_clear_row_high
.import draw_pixel_high_color
.import draw_getpixel_high_color
.import draw_vline_high_color

.proc video_mode_high_color
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_mode_set_high_color
	.word video_page_copy_high
	.word video_cls_high
	.word text_out_high
	.word text_copy_row_high
	.word text_clear_row_high
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_color()
_video_mode_high_color = video_mode_high_color
