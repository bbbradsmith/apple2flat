; video_low
;
; Video driver for low resolution

.include "../a2f.inc"

.export video_mode_low
.export _video_mode_low

.export draw_pixel_low
.export draw_getpixel_low

.import video_page_copy_low
.import video_page_apply

.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_MAX
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.proc video_mode_low
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_page_low
	.word video_page_copy_low
	.word video_cls_low
	.word video_null ; out_text
	.word video_null ; out_text
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

; void video_mode_low()
_video_mode_low = video_mode_low

.proc video_page_low
	; TODO IIe stuff?
	sta $C052 ; non-mixed (MIXED)
	sta $C050 ; graphics mode (TEXT)
	jmp video_page_apply
.endproc

.proc video_cls_low
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #0
	jmp video_cls_page
.endproc

.proc draw_pixel_low
	; TODO
	rts
.endproc

.proc draw_getpixel_low
	; TODO
	rts
.endproc
