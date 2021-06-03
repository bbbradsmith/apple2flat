; video_high_color_mixed
;
; Video driver for high resolution color + mixed text

.include "../a2f.inc"

.export video_mode_high_color_mixed
.export _video_mode_high_color_mixed

.import video_mode_setup
.import VIDEO_FUNCTION_MAX

.import video_page_high_mixed
.import video_page_copy_high_mixed
.import video_cls_high_mixed
.import text_out_text
.import text_scroll_text
.import draw_pixel_high_color
.import draw_getpixel_high_color
.import draw_hline_generic
.import draw_vline_high_color
.import draw_fillbox_generic

.proc video_mode_high_color_mixed
	lda #40
	sta video_text_w
	lda #24
	sta video_text_h
	lda #<table
	ldx #>table
	jsr video_mode_setup
	lda #20
	sta video_text_y
	sta video_text_yr
	rts
table:
	.word video_page_high_mixed
	.word video_page_copy_high_mixed
	.word video_cls_high_mixed
	.word text_out_text
	.word text_scroll_text
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_high_color_mixed()
_video_mode_high_color_mixed = video_mode_high_color_mixed
