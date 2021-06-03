; video_high_mono
;
; Video driver for high resolution monochrome

.include "../a2f.inc"

.export video_mode_high_mono
.export _video_mode_high_mono

.export draw_pixel_high_mono
.export draw_getpixel_high_mono
.export draw_vline_high_mono

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
.import draw_fillbox_generic

.import draw_xh
.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1

.proc video_mode_high_mono
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_page_high
	.word video_page_copy_high
	.word video_cls_high
	.word video_null ; TODO out_text_high
	.word video_null ; TODO scroll_text_high
	.word draw_pixel_high_mono
	.word draw_getpixel_high_mono
	.word draw_hline_generic
	.word draw_vline_high_mono
	.word draw_fillbox_generic
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_high_mono()
_video_mode_high_mono = video_mode_high_mono

.proc draw_high_mono_addr_x ; draw_xh:X pixel address to draw_ptr0, sub-pixel in draw_ptr1+1
	lda draw_xh
	bne @x_right
	txa
	cmp #140
	bcs @x_right
@x_left:
	lda video_div7, X
	and #7
	sta draw_ptr1+1
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
	sta draw_ptr1+1
	lda video_div7, X
	lsr
	lsr
	lsr
	clc
	adc #20
@x_finish:
	clc
	adc draw_ptr0+0
	sta draw_ptr0+0
	rts
.endproc

.proc draw_pixel_high_mono
	; draw_xh:X/Y = coordinate, A = value
	sta draw_ptr1+0 ; save value
	jsr draw_high_addr_y
	jsr draw_high_mono_addr_x
	; draw_ptr1+1 = sub-pixel X location
	ldy #0
	lda #1 ; inverse mask for pixel
	ldx draw_ptr1+1
	beq :++
	:
		asl
		asl draw_ptr1+0
		dex
		bne :-
	:
	eor #$FF ; and-mask
	and (draw_ptr0), Y
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
.endproc

.proc draw_getpixel_high_mono
	; draw_xh:X/Y = coordinate
	jsr draw_high_addr_y
	jsr draw_high_mono_addr_x
	; draw_ptr1+1 = sub-pixel X location
	ldy #0
	lda (draw_ptr0), Y
	ldx draw_ptr1+1
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
	sta draw_ptr1+0 ; save value
	ldx draw_x0+0
	ldy draw_y0
	jsr draw_high_addr_y
	jsr draw_high_mono_addr_x
	lda #1
	ldx draw_ptr1+1
	beq :++
	:
		asl
		asl draw_ptr1+0 ; rotated value
		dex
		bne :-
	:
	eor #$FF
	sta draw_ptr1+1 ; rotated mask
	ldy #0
@loop:
	; stop when y0 >= y1
	lda draw_y0
	cmp draw_y1
	bcc :+
		rts
	:
	; draw the pixel
	lda (draw_ptr0), Y
	and draw_ptr1+1
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	; next pixel
	jsr draw_high_addr_y_inc
	inc draw_y0
	jmp @loop
.endproc
