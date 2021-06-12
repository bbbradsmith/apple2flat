; video_low_mixed
;
; Video driver for low resolution + mixed text

.include "../a2f.inc"

.export video_mode_low_mixed
.export _video_mode_low_mixed

.import video_page_copy_low
.import video_page_apply
.import text_out_text
.import text_copy_row_text
.import text_clear_row_text
.import draw_pixel_low
.import draw_getpixel_low

.import video_mode_setup
.import video_mode_mixed_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp draw_ptr

.proc video_mode_low_mixed
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_mode_mixed_setup
table:
	.word video_mode_set_low_mixed
	.word video_page_copy_low
	.word video_cls_low_mixed
	.word text_out_text
	.word text_copy_row_text
	.word text_clear_row_text
	.word draw_pixel_low
	.word draw_getpixel_low
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_low_mixed()
_video_mode_low_mixed = video_mode_low_mixed

.proc video_mode_set_low_mixed
	; set mode
	sta $C050 ; graphics mode (TEXT)
	sta $C056 ; low-res (HIRES)
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

.proc video_cls_low_mixed
	; reset cursor
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	; clear graphics
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #0
	jsr video_cls_page ; NOTE: mixed text area will be briefly filled with @ (0)
	; clear mixed text
	lda video_page_w
	and #1
	eor #CLS_MIXED0
	tax
	lda #$A0 ; space, normal
	jmp video_cls_page
.endproc
