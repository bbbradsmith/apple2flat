; video_high_color
;
; Video driver for high resolution colour

.include "../a2f.inc"

.export video_mode_high_color
.export _video_mode_high_color

.export draw_pixel_high_color
.export draw_getpixel_high_color
.export draw_vline_high_color

.import video_page_copy_high
.import video_page_apply
.import video_cls_high
.import draw_high_addr_y
.import draw_high_addr_y_inc

.import video_div7
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp a2f_temp
.importzp draw_ptr
draw_high_color = a2f_temp+2
draw_high_phase = a2f_temp+3

.proc video_mode_high_color
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_page_high_color
	.word video_page_copy_high
	.word video_cls_high
	.word video_null ; TODO out_text
	.word video_null ; TODO text_copy_row
	.word video_null ; TODO text_clear_row
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_high_color()
_video_mode_high_color = video_mode_high_color

.proc video_page_high_color
	; set mode
	sta $C050 ; graphics mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C057 ; high-res (HIRES)
	; double/RGB settings
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00D ; RGB 11 = color
	sta $C05E
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	sta $C00C ; 40 columns (80COL)
	jmp video_page_apply
.endproc

.proc draw_high_color_addr_x ; draw_xh:X pixel address to draw_ptr, sub-pixel 0-6 in draw_high_phase
	lda video_div7, X
	and #7
	sta draw_high_phase
	lda video_div7, X
	lsr
	lsr
	and #%11111110 ; (X/7)*2 = byte pair this pixel is in
	clc
	adc draw_ptr+0
	sta draw_ptr+0
	rts
.endproc

draw_pixel_high_color:
	; draw_xh:X/Y = coordinate, A = value
	sta draw_high_color ; save value
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
draw_pixel_high_color_addr: ; ready: draw_ptr, draw_high_color, draw_high_phase
	ldx draw_high_phase
	beq @x0
	cpx #4
	bcs @x456
	cpx #2
	beq @x2
	bcc @x1
	bcs @x3
@x0:
	ldy #0
	lda (draw_ptr), Y
	and #%01111100
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x1:
	lda draw_high_color
	tax
	asl
	asl
	sta draw_high_color
	txa
	and #%10000000
	ora draw_high_color
	sta draw_high_color
	ldy #0
	lda (draw_ptr), Y
	and #%01110011
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x2:
	lda draw_high_color
	tax
	asl
	asl
	asl
	asl
	sta draw_high_color
	txa
	and #%10000000
	ora draw_high_color
	sta draw_high_color
	ldy #0
	lda (draw_ptr), Y
	and #%01001111
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x3:
	lda draw_high_color
	pha
	tax
	lsr
	ror
	ror
	and #%01000000
	sta draw_high_color
	txa
	and #%10000000
	tax
	ora draw_high_color
	sta draw_high_color
	ldy #0
	lda (draw_ptr), Y
	and #%00111111
	ora draw_high_color
	sta (draw_ptr), Y
	pla
	lsr
	lsr
	txa
	adc #0
	and #%10000001
	sta draw_high_color
	iny
	lda (draw_ptr), Y
	and #%01111110
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x456:
	beq @x4
	cpx #5
	beq @x5
	bne @x6
@x4:
	lda draw_high_color
	tax
	asl
	sta draw_high_color
	txa
	and #%10000000
	ora draw_high_color
	sta draw_high_color
	ldy #1
	lda (draw_ptr), Y
	and #%01111001
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x5:
	lda draw_high_color
	tax
	asl
	asl
	asl
	sta draw_high_color
	txa
	and #%10000000
	ora draw_high_color
	sta draw_high_color
	ldy #1
	lda (draw_ptr), Y
	and #%01100111
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x6:
	lda draw_high_color
	tax
	asl
	asl
	asl
	asl
	asl
	sta draw_high_color
	txa
	and #%10000000
	ora draw_high_color
	sta draw_high_color
	ldy #1
	lda (draw_ptr), Y
	and #%00011111
	ora draw_high_color
	sta (draw_ptr), Y
	rts

.proc draw_getpixel_high_color
	; draw_xh:X/Y = coordinate
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
	; draw_high_phase = sub-pixel X location
	lda draw_high_phase
	asl
	tax
	inx ; X = 2 * bits to rotate + 1
	; load two bytes into draw_ptr1
	ldy #0
	lda (draw_ptr), Y
	asl ; rotate left to delete color phase bit (+1 rotation will undo this)
	sta draw_high_color
	iny
	lda (draw_ptr), Y
	sta draw_high_phase ; temporary high bits of color
	lda draw_high_color
	:
		lsr draw_high_phase ; high bits
		ror
		dex
		bne :-
	and #3
	sta draw_high_color ; store colour without phase
	dey
	lda (draw_ptr), Y
	and #%10000000
	ora draw_high_color ; combine with phase
	rts
.endproc

.proc draw_vline_high_color
	pha ; save value
	ldx draw_x0+0
	ldy draw_y0
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
@loop:
	; stop when y0 >= y1
	lda draw_y0
	cmp draw_y1
	bcc :+
		pla
		rts
	:
	; draw the pixel
	pla
	pha
	sta draw_high_color ; restore value
	jsr draw_pixel_high_color_addr
	; next pixel
	jsr draw_high_addr_y_inc
	inc draw_y0
	jmp @loop
.endproc
