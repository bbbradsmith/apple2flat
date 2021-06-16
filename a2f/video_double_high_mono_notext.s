; video_double_high_mono_notext
;
; Video driver for double high resolution monochrome with no text support

.export video_mode_double_high_mono_notext
.export _video_mode_double_high_mono_notext

.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup

.import video_mode_set_double_high_mono
.import video_page_copy_double_high
.import video_cls_double_high
.import video_null
.import draw_pixel_double_high_mono
.import draw_getpixel_double_high_mono
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.proc video_mode_double_high_mono_notext
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_mono
	.word video_page_copy_double_high
	.word video_cls_double_high
	.word video_null ; text_out
	.word video_null ; text_copy_row
	.word video_null ; text_clear_row
	.word draw_pixel_double_high_mono
	.word draw_getpixel_double_high_mono
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word 560
	.byte 192
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_mono_notext()
_video_mode_double_high_mono_notext = video_mode_double_high_mono_notext
