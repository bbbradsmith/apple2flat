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

.importzp a2f_temp

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
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_low_mixed()
_video_mode_low_mixed = video_mode_low_mixed

.proc video_page_low_mixed
	; TODO IIe stuff?
	sta $C053 ; mixed (MIXED)
	sta $C050 ; graphics mode (TEXT)
	sta $C056 ; low-res (HIRES)
	jmp video_page_apply
.endproc

; TODO
; this seems unnecessary, as there is no clean single-buffered transition from mixed to non-mixed
; (will always see a page of @ or vice versa)
; instead just call cls_page with CLS_LOW0/1 and then add another cls_page with CLS_TEXT,
; which text modes can call afterward, which will be fine for double-buffered modes
.proc video_cls_low_mixed
	; reset cursor
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	; divided page clear
	lda video_page_w
	and #$0C
	eor #$04
	sta a2f_temp+1 ; $400 or $800
	lda #0
	sta a2f_temp+0
	; 20 lines of 0
	ldx #20
	jsr @clear ; A = 0, X = 20
	; 4 lines of space character
	ldx #4
	lda #$A0 ; space, normal
	;jmp @clear ; A = $A0, X = 4
@clear:
	; clear line
	ldy #0
	:
		sta (a2f_temp), Y
		iny
		cpy #40
		bcc :-
	; advance to next line, $80 bytes
	tay ; store clear colour
	lda a2f_temp+0
	clc
	adc #<$80
	sta a2f_temp+0
	bcc :+
	lda a2f_temp+1
	adc #0
	sta a2f_temp+1
	and #$03
	bne :+
		; group exceeded, move to next segment of group
		lda a2f_temp+1
		sec
		sbc #$04
		sta a2f_temp+1 ; back to top of area
		lda a2f_temp+0
		clc
		adc #40
		sta a2f_temp+0 ; advance by 40 bytes
	:
	tya
	; next line
	dex
	bne :+
		rts
	:
	jmp @clear
.endproc
