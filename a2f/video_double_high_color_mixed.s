; video_double_high_color_mixed
;
; Video driver for double high resolution color + mixed text

.include "../a2f.inc"

.export video_mode_double_high_color_mixed
.export _video_mode_double_high_color_mixed

.import video_mode_setup
.import video_mode_mixed_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.importzp video_double_read_aux

.import video_page_copy_double_high_mixed
.import video_page_apply
.import video_cls_double_high_mixed
.import text_out_double_text
.import text_copy_row_double_text
.import text_clear_row_double_text
.import draw_pixel_double_high_color
.import draw_getpixel_double_high_color
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.proc video_mode_double_high_color_mixed
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jsr video_mode_mixed_setup
	asl video_text_w ; 40 << 1 = 80
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_color_mixed
	.word video_page_copy_double_high_mixed
	.word video_cls_double_high_mixed
	.word text_out_double_text
	.word text_copy_row_double_text
	.word text_clear_row_double_text
	.word draw_pixel_double_high_color
	.word draw_getpixel_double_high_color
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_color_mixed()
_video_mode_double_high_color_mixed = video_mode_double_high_color_mixed

.proc video_mode_set_double_high_color_mixed
	sta $C050 ; graphics mode (TEXT)
	sta $C057 ; high-res (HIRES)
	sta $C052
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00D ; 80 columns (80COL)
	sta $C05E ; RGB 11 = color
	sta $C05F
	sta $C05E
	sta $C05F
	sta $C05E ; double-hires off (AN3/DHIRES)
	sta $C053 ; mixed (MIXED)
	jmp video_page_apply
.endproc
