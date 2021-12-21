; video_high
;
; Common routines for high resolution grpahics

.include "../a2f.inc"

.export video_cls_high
.export draw_high_addr_y
.export draw_high_addr_y_inc
.export video_page_copy_high
.export blit_high_mono

.import video_rowpos0
.import video_rowpos1

.importzp a2f_temp
.importzp draw_ptr0
.importzp draw_ptr1
blit_w = a2f_temp+4
blit_h = a2f_temp+5
blit_temp = a2f_temp+6

.proc video_page_copy_high
	; TODO copy page_r to page_w
	rts
.endproc

.proc video_cls_high
	lda video_page_w
	and #1
	eor #CLS_HIGH0
	tax
	lda #0
	jmp video_cls_page
.endproc

.proc draw_high_addr_y ; Y pixel address to draw_ptr0
	lda video_page_w
	and #$60
	eor #$20 ; $20 or $40
	sta draw_ptr0+1
	tya
	pha
	lsr
	lsr
	lsr
	tay ; Y/=8 to find row group
	pla
	and #7 ; Y%8 sub-row group
	asl
	asl
	ora draw_ptr0+1
	ora video_rowpos1, Y
	sta draw_ptr0+1
	lda video_rowpos0, Y
	sta draw_ptr0+0 ; draw_ptr0 = pointer to row
	rts
.endproc

.proc draw_high_addr_y_inc ; clobbers A
	; advance by 1 line
	lda draw_ptr0+1
	clc
	adc #$04
	sta draw_ptr0+1
	and #$1C
	bne :+
		; gone past bottom, roll back and advance line group
		lda draw_ptr0+0
		sec
		sbc #<($2000-$80)
		sta draw_ptr0+0
		lda draw_ptr0+1
		sbc #>($2000-$80)
		sta draw_ptr0+1
		and #$03
		bne :+
		lda draw_ptr0+0
		bmi :+
		; TODO remove this equivalent? code:
		;lda draw_ptr0+1
		;sec
		;sbc #$20
		;sta draw_ptr0+1
		;lda draw_ptr0+0
		;clc
		;adc #<$80
		;sta draw_ptr0+0
		;lda draw_ptr0+1
		;adc #>$80
		;sta draw_ptr0+1
		;and #$04 ; is this the right test??
		;beq :+
		; into next 1/3 group, roll back and advance 1/3
		lda draw_ptr0+0
		sec
		sbc #<($400-40)
		sta draw_ptr0+0
		lda draw_ptr0+1
		sbc #>($400-40)
		sta draw_ptr0+1
		; TODO remove this equivalent code
		;lda draw_ptr0+1
		;sec
		;sbc #$04
		;sta draw_ptr0+1
		;lda draw_ptr0+0
		;clc
		;adc #40
		;sta draw_ptr0+0
	:
	rts
.endproc

.proc blit_high_mono
	; X/Y = coordinate (2X for color), draw_ptr1 = data
	jsr draw_high_addr_y
	txa
	clc
	adc draw_ptr0+1
	sta draw_ptr0+1
	ldy #0
	lda (draw_ptr1), Y
	sta blit_w
	iny
	lda (draw_ptr1), Y
	sta blit_h
	iny
	ldx #0
@loop:
	sty blit_temp
	lda (draw_ptr1), Y
	pha
	txa
	tay
	pla
	sta (draw_ptr0), Y
	ldy blit_temp
	iny
	bne :+
		inc draw_ptr1+1
	:
	inc draw_ptr0
	inx
	cpx blit_w
	bcc @loop
	jsr draw_high_addr_y_inc
	ldx #0
	dec blit_h
	bne @loop
	rts
.endproc
