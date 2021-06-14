; video_high_mono_notext
;
; Video driver for high resolution monochrome with no text support

.include "../a2f.inc"

.export video_mode_high_mono_notext
.export _video_mode_high_mono_notext

.export video_mode_set_high_mono
.export draw_pixel_high_mono
.export draw_getpixel_high_mono
.export draw_vline_high_mono

.import video_page_copy_high
.import video_page_apply
.import video_cls_high
.import draw_high_addr_y
.import draw_high_addr_y_inc

.import video_null
.import video_div7
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import draw_hline_generic
.import draw_fillbox_generic

.import draw_xh
.importzp draw_ptr
.importzp a2f_temp

draw_high_color = a2f_temp+2
draw_high_phase = a2f_temp+3

.proc video_mode_high_mono_notext
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_mode_set_high_mono
	.word video_page_copy_high
	.word video_cls_high
	.word video_null ; text_out
	.word video_null ; text_copy_row
	.word video_null ; text_clear_row
	.word draw_pixel_high_mono
	.word draw_getpixel_high_mono
	.word draw_hline_generic
	.word draw_vline_high_mono
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_mono_notext()
_video_mode_high_mono_notext = video_mode_high_mono_notext

.proc video_mode_set_high_mono
	; set mode
	sta $C050 ; graphics mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C057 ; high-res (HIRES)
	; double/RGB settings
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00C ; 40 columns (80COL)
	sta $C05E ; RGB 00 = mono
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	jmp video_page_apply
.endproc

.proc draw_high_mono_addr_x ; draw_xh:X pixel address to draw_ptr, sub-pixel in draw_high_phase
	lda draw_xh
	bne @x_right
	txa
	cmp #140
	bcs @x_right
@x_left:
	lda video_div7, X
	and #7
	sta draw_high_phase
	lda video_div7, X
	lsr
	lsr
	lsr
	jmp @x_finish
@x_right:
	txa
	sec
	sbc #140
	tax
	lda video_div7, X
	and #7
	sta draw_high_phase
	lda video_div7, X
	lsr
	lsr
	lsr
	clc
	adc #20
@x_finish:
	clc
	adc draw_ptr+0
	sta draw_ptr+0
	rts
.endproc

.proc draw_pixel_high_mono
	; draw_xh:X/Y = coordinate, A = value
	sta draw_high_color ; save value
	jsr draw_high_addr_y
	jsr draw_high_mono_addr_x
	; draw_high_phase = sub-pixel X location
	ldy #0
	lda #1 ; inverse mask for pixel
	ldx draw_high_phase
	beq :++
	:
		asl
		asl draw_high_color
		dex
		bne :-
	:
	eor #$FF ; and-mask
	and (draw_ptr), Y
	ora draw_high_color
	sta (draw_ptr), Y
	rts
.endproc

.proc draw_getpixel_high_mono
	; draw_xh:X/Y = coordinate
	jsr draw_high_addr_y
	jsr draw_high_mono_addr_x
	; draw_high_phase = sub-pixel X location
	ldy #0
	lda (draw_ptr), Y
	ldx draw_high_phase
	beq :++
	:
		lsr
		dex
		bne :-
	:
	and #1
	rts
.endproc

.proc draw_vline_high_mono
	sta draw_high_color ; save value
	ldx draw_x0+0
	ldy draw_y0
	jsr draw_high_addr_y
	jsr draw_high_mono_addr_x
	lda #1
	ldx draw_high_phase
	beq :++
	:
		asl
		asl draw_high_color ; rotated value
		dex
		bne :-
	:
	eor #$FF
	sta draw_high_phase ; temporarily: rotated mask
	ldy #0
@loop:
	; stop when y0 >= y1
	lda draw_y0
	cmp draw_y1
	bcc :+
		rts
	:
	; draw the pixel
	lda (draw_ptr), Y
	and draw_high_phase ; rotated mask
	ora draw_high_color
	sta (draw_ptr), Y
	; next pixel
	jsr draw_high_addr_y_inc
	inc draw_y0
	jmp @loop
.endproc
