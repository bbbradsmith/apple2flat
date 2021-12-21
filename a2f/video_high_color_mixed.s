; video_high_color_mixed
;
; Video driver for high resolution color + mixed text

.include "../a2f.inc"

.export video_mode_high_color_mixed
.export _video_mode_high_color_mixed

.import video_mode_setup
.import video_mode_mixed_setup
.import VIDEO_FUNCTION_TABLE_SIZE

.import video_page_copy_high_mixed
.import video_page_apply
.import video_cls_high_mixed
.import text_out_text
.import text_copy_row_text
.import text_clear_row_text
.import draw_pixel_high_color
.import draw_getpixel_high_color
.import draw_hline_generic
.import draw_vline_high_color
.import draw_fillbox_generic
.import blit_high_color

.proc video_mode_high_color_mixed
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_mode_mixed_setup
table:
	.word video_mode_set_high_color_mixed
	.word video_page_copy_high_mixed
	.word video_cls_high_mixed
	.word text_out_text
	.word text_copy_row_text
	.word text_clear_row_text
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.word blit_high_color
	.word 140
	.byte 160
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_color_mixed()
_video_mode_high_color_mixed = video_mode_high_color_mixed

.proc video_mode_set_high_color_mixed
	; set mode
	sta $C050 ; graphics mode (TEXT)
	sta $C057 ; high-res (HIRES)
	; double/RGB settings
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C052
	sta $C00D ; RGB 11 = color
	sta $C05E
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	sta $C00C ; 40 columns (80COL)
	; set mixed
	sta $C053 ; mixed (MIXED)
	jmp video_page_apply
.endproc
