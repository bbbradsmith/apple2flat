; video_high_mono_double_mixed
;
; Video driver for high resolution mono + double (80 column) mixed text

.include "../a2f.inc"

.export video_mode_high_mono_double_mixed
.export _video_mode_high_mono_double_mixed

.import video_mode_setup
.import video_mode_mixed_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup

.import video_page_copy_high_double_mixed
.import video_page_apply
.import video_cls_high_double_mixed
.import text_out_double_text
.import text_copy_row_double_text
.import text_clear_row_double_text
.import draw_pixel_high_mono
.import draw_getpixel_high_mono
.import draw_hline_generic
.import draw_vline_high_mono
.import draw_fillbox_generic
.import blit_high_mono

.proc video_mode_high_mono_double_mixed
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jsr video_mode_mixed_setup
	asl video_text_w+0 ; 40 << 1 = 80
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_high_mono_double_mixed
	.word video_page_copy_high_double_mixed
	.word video_cls_high_double_mixed
	.word text_out_double_text
	.word text_copy_row_double_text
	.word text_clear_row_double_text
	.word draw_pixel_high_mono
	.word draw_getpixel_high_mono
	.word draw_hline_generic
	.word draw_vline_high_mono
	.word draw_fillbox_generic
	.word blit_high_mono
	.word 280
	.byte 160
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_mono_double_mixed()
_video_mode_high_mono_double_mixed = video_mode_high_mono_double_mixed

.proc video_mode_set_high_mono_double_mixed
	sta $C050 ; graphics mode (TEXT)
	sta $C057 ; high-res (HIRES)
	sta $C052
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00C
	sta $C05E ; RGB 00 = mono
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	sta $C00D ; 80 columns (80COL)
	sta $C053 ; mixed (MIXED)
	jmp video_page_apply
.endproc
