; draw_vline_generic
;
; Inefficient but generic vertical line using draw_pixel

.export draw_vline_generic

.import draw_x0
.import draw_y0
.import draw_y1

.import draw_pixel

draw_vline_generic: ; draw A to pixels x0, y0 to y1-1
	pha ; store color
@loop:
	; stop when y0 >= y1
	lda draw_y0
	cmp draw_y1
	bcc :+
		pla
		rts
	:
	; draw pixel
	pla ; color
	pha
	ldx draw_x0+0
	ldy draw_y0
	jsr draw_pixel
	; next pixel
	inc draw_y0
	jmp @loop
