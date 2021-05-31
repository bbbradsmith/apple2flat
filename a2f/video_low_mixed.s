; video_low_mixed
;
; Video driver for low resolution + mixed text

.include "../a2f.inc"

.export video_mode_low_mixed
.export _video_mode_low_mixed

.import video_page_copy_low
.import video_page_apply
.import text_out_text
.import text_scroll_text
.import draw_pixel_low
.import draw_getpixel_low

.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_MAX
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.proc video_mode_low_mixed
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
	.word video_page_low_mixed
	.word video_page_copy_low
	.word video_cls_low_mixed
	.word text_out_text
	.word text_scroll_text
	.word draw_pixel_low
	.word draw_getpixel_low
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word video_null ; blit_coarse
	.word video_null ; blit_fine
	.word video_null ; blit_mask
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_low_mixed()
_video_mode_low_mixed = video_mode_low_mixed

.proc video_page_low_mixed
	; TODO IIe stuff?
	sta $C053 ; mixed (MIXED)
	sta $C050 ; graphics mode (TEXT)
	jmp video_page_apply
.endproc

.proc video_cls_low_mixed
	; TODO clear text separately
	rts
.endproc
