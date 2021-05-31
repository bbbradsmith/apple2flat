; draw_fillbox_generic
;
; Inefficient but generic filled box using draw_vline

.export draw_fillbox_generic

.import draw_x0
.import draw_y0
.import draw_x1
.import draw_y1

.import draw_vline

draw_fillbox_generic:
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
	; draw vline
	pla
	tax
	lda draw_y0
	pha
	txa
	pha
	jsr draw_vline ; clobbers y0
	pla
	tax
	pla
	sta draw_y0
	txa
	pha
	; next column
	inc draw_x0+0
	bne :+
		inc draw_x0+1
	:
	jmp @loop
