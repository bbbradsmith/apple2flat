; video_double_high_mono
;
; Video driver for double high resolution monochrome

.include "../a2f.inc"

.export video_mode_double_high_mono
.export _video_mode_double_high_mono

.import video_page_apply
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.import video_mode_set_double_high_mono
.import video_page_copy_double_high
.import video_cls_double_high
.import text_out_double_high_mono
.import text_copy_row_double_high_mono
.import text_clear_row_double_high_mono
.import draw_pixel_double_high_mono
.import draw_getpixel_double_high_mono

.proc video_mode_double_high_mono
	lda #<table
	ldx #>table
	jsr video_mode_setup
	asl video_text_w+0 ; 40 << 1 = 80
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_mono
	.word video_page_copy_double_high
	.word video_cls_double_high
	.word text_out_double_high_mono
	.word text_copy_row_double_high_mono
	.word text_clear_row_double_high_mono
	.word draw_pixel_double_high_mono
	.word draw_getpixel_double_high_mono
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word 560
	.byte 192
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_mono()
_video_mode_double_high_mono = video_mode_double_high_mono
