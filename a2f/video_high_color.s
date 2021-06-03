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
.import video_page_high
.import video_cls_high
.import draw_high_addr_y
.import draw_high_addr_y_inc

.import video_div7
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_MAX
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1

.proc video_mode_high_color
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_page_high
	.word video_page_copy_high
	.word video_cls_high
	.word video_null ; TODO out_text_high
	.word video_null ; TODO scroll_text_high
	.word draw_pixel_high_color
	.word draw_getpixel_high_color
	.word draw_hline_generic
	.word draw_vline_high_color
	.word draw_fillbox_generic
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_high_color()
_video_mode_high_color = video_mode_high_color

.proc draw_high_color_addr_x ; draw_xh:X pixel address to draw_ptr0, sub-pixel in draw_ptr1+1
	lda video_div7, X
	and #7
	sta draw_ptr1+1
	lda video_div7, X
	lsr
	lsr
	and #%11111110 ; (X/7)*2 = byte pair this pixel is in
	clc
	adc draw_ptr0+0
	sta draw_ptr0+0
	rts
.endproc

.proc draw_pixel_high_color
	; draw_xh:X/Y = coordinate, A = value
	sta draw_ptr1+0 ; save value
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
	; draw_ptr1+1 = sub-pixel X location
	ldx draw_ptr1+1
	beq @x0
	cpx #4
	bcs @x456
	cpx #2
	beq @x2
	bcc @x1
	bcs @x3
@x0:
	ldy #0
	lda (draw_ptr0), Y
	and #%01111100
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@x1:
	lda draw_ptr1+0
	tax
	asl
	asl
	sta draw_ptr1+0
	txa
	and #%10000000
	ora draw_ptr1+0
	sta draw_ptr1+0
	ldy #0
	lda (draw_ptr0), Y
	and #%01110011
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@x2:
	lda draw_ptr1+0
	tax
	asl
	asl
	asl
	asl
	sta draw_ptr1+0
	txa
	and #%10000000
	ora draw_ptr1+0
	sta draw_ptr1+0
	ldy #0
	lda (draw_ptr0), Y
	and #%01001111
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@x3:
	lda draw_ptr1+0
	pha
	tax
	lsr
	ror
	ror
	and #%01000000
	sta draw_ptr1+0
	txa
	and #%10000000
	tax
	ora draw_ptr1+0
	sta draw_ptr1+0
	ldy #0
	lda (draw_ptr0), Y
	and #%00111111
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	pla
	lsr
	lsr
	txa
	adc #0
	and #%10000001
	sta draw_ptr1+0
	iny
	lda (draw_ptr0), Y
	and #%01111110
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@x456:
	beq @x4
	cpx #5
	beq @x5
	bne @x6
@x4:
	lda draw_ptr1+0
	tax
	asl
	sta draw_ptr1+0
	txa
	and #%10000000
	ora draw_ptr1+0
	sta draw_ptr1+0
	ldy #1
	lda (draw_ptr0), Y
	and #%01111001
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@x5:
	lda draw_ptr1+0
	tax
	asl
	asl
	asl
	sta draw_ptr1+0
	txa
	and #%10000000
	ora draw_ptr1+0
	sta draw_ptr1+0
	ldy #1
	lda (draw_ptr0), Y
	and #%01100111
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@x6:
	lda draw_ptr1+0
	tax
	asl
	asl
	asl
	asl
	asl
	sta draw_ptr1+0
	txa
	and #%10000000
	ora draw_ptr1+0
	sta draw_ptr1+0
	ldy #1
	lda (draw_ptr0), Y
	and #%00011111
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
.endproc

.proc draw_getpixel_high_color
	; draw_xh:X/Y = coordinate
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
	; draw_ptr1+1 = sub-pixel X location
	lda draw_ptr1+1
	asl
	tax
	inx ; X = 2 * bits to rotate + 1
	; load two bytes into draw_ptr1
	ldy #0
	lda (draw_ptr0), Y
	asl ; rotate left to delete color phase bit (+1 rotation will undo this)
	sta draw_ptr1+0
	iny
	lda (draw_ptr0), Y
	sta draw_ptr1+1
	lda draw_ptr1+0
	:
		lsr draw_ptr1+1
		ror
		dex
		bne :-
	and #3
	sta draw_ptr1+0 ; store colour without phase
	dey
	lda (draw_ptr0), Y
	and #%10000000
	ora draw_ptr1+0 ; combine with phase
	rts
.endproc

.proc draw_vline_high_color
	jmp draw_vline_generic ; TODO?
.endproc
