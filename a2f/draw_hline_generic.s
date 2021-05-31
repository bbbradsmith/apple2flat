; draw_hline_generic
;
; Inefficient but generic horizontal line using draw_pixel

.export draw_hline_generic

.import draw_x0
.import draw_y0
.import draw_x1

.import draw_pixel

draw_hline_generic: ; draw A to pixels x0 to x1-1, y0
	pha ; store color
@loop:
	; stop when x0 >= x1
	lda draw_x0+0
	cmp draw_x1+0
	lda draw_x0+1
	sbc draw_x1+1
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
	inc draw_x0+0
	bne :+
		inc draw_x0+1
	:
	jmp @loop
