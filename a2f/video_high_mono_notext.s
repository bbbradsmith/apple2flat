; video_high_mono_notext
;
; Video driver for high resolution monochrome with no text support

.export video_mode_high_mono_notext
.export _video_mode_high_mono_notext

.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE

.import video_mode_set_high_mono
.import video_page_copy_high
.import video_cls_high
.import video_null
.import draw_pixel_high_mono
.import draw_getpixel_high_mono
.import draw_vline_high_mono
.import draw_hline_generic
.import draw_fillbox_generic
.import blit_high_mono

.proc video_mode_high_mono_notext
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_mode_set_high_mono
	.word video_page_copy_high
	.word video_cls_high
	.word video_null ; text_out
	.word video_null ; text_copy_row
	.word video_null ; text_clear_row
	.word draw_pixel_high_mono
	.word draw_getpixel_high_mono
	.word draw_hline_generic
	.word draw_vline_high_mono
	.word draw_fillbox_generic
	.word blit_high_mono
	.word 280
	.byte 192
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_mono_notext()
_video_mode_high_mono_notext = video_mode_high_mono_notext
