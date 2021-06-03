; video_high_mono_mixed
;
; Video driver for high resolution mono + mixed text

.include "../a2f.inc"

.export video_mode_high_mono_mixed
.export _video_mode_high_mono_mixed

.import video_mode_setup
.import VIDEO_FUNCTION_MAX

.import video_page_high
.import video_page_copy_high
.import video_page_apply
.import text_out_text
.import text_scroll_text
.import draw_pixel_high_mono
.import draw_getpixel_high_mono
.import draw_hline_generic
.import draw_vline_high_mono
.import draw_fillbox_generic

.proc video_mode_high_mono_mixed
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
	.word draw_pixel_high_mono
	.word draw_getpixel_high_mono
	.word draw_hline_generic
	.word draw_vline_high_mono
	.word draw_fillbox_generic
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_high_mono_mixed()
_video_mode_high_mono_mixed = video_mode_high_mono_mixed

.proc video_page_high_mixed
	; TODO IIe stuff?
	sta $C053 ; mixed (MIXED)
	sta $C050 ; graphics mode (TEXT)
	sta $C057 ; high-res (HIRES)
	jmp video_page_apply
.endproc

.proc video_page_copy_high_mixed
	; TODO
	rts
.endproc

.proc video_cls_high_mixed ; TODO make common and more succinct
	lda video_page_w
	and #1
	eor #CLS_HIGH0
	tax
	lda #0
	jsr video_cls_page
	; TODO TEXT0
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #$A0
	jmp video_cls_page
.endproc
