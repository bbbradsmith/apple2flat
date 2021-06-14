; video_double_high_color
;
; Video driver for double high resolution colour

.include "../a2f.inc"

.export video_mode_double_high_color
.export _video_mode_double_high_color

.import video_page_apply
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.import video_mode_set_double_high_color
.import video_page_copy_double_high
.import video_cls_double_high
.import text_out_double_high_color
.import text_copy_row_double_high_color
.import text_clear_row_double_high_color
.import draw_pixel_double_high_color
.import draw_getpixel_double_high_color

.proc video_mode_double_high_color
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_color
	.word video_page_copy_double_high
	.word video_cls_double_high
	.word text_out_double_high_color
	.word text_copy_row_double_high_color
	.word text_clear_row_double_high_color
	.word draw_pixel_double_high_color
	.word draw_getpixel_double_high_color
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_color()
_video_mode_double_high_color = video_mode_double_high_color
