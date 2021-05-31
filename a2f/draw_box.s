; draw_box
;
; Draws box of 4 lines

.export draw_box

.import draw_x0
.import draw_y0
.import draw_x1
.import draw_y1

.import draw_hline
.import draw_vline

draw_box: ; draw A
	tax
	lda draw_y0
	pha ; y0
	txa
	pha ; c
	jsr draw_vline ; sets y0 to y1
	pla
	tax
	pla
	sta draw_y0 ; reset y0
	lda draw_x0+0
	pha
	lda draw_x0+1
	pha
	txa
	pha ; c
	jsr draw_hline ; sets x0 to x1
	pla
	tax
	lda draw_x0+0
	bne :+
		dec draw_x1+0
	:
	dec draw_x0+0 ;
	txa
	pha ; c
	jsr draw_vline ; vline at x1-1, sets y0 to y1
	pla
	tax
	pla
	sta draw_x0+1 ; reset x0
	pla
	sta draw_x0+0
	dec draw_y0
	txa
	jmp draw_hline ; hline at x0,y1-1
