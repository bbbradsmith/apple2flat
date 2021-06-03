; video_high
;
; Common routines for high resolution grpahics

.include "../a2f.inc"

.export video_page_high
.export video_cls_high
.export draw_high_addr_y
.export draw_high_addr_y_inc
.export video_page_copy_high

.import video_rowpos0
.import video_rowpos1

.import video_page_apply

.importzp draw_ptr0
.importzp draw_ptr1

.proc video_page_high
	; TODO IIe stuff?
	sta $C052 ; non-mixed (MIXED)
	sta $C050 ; graphics mode (TEXT)
	sta $C057 ; high-res (HIRES)
	jmp video_page_apply
.endproc

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

.proc draw_high_addr_y_inc
	; advance by 1 line
	lda draw_ptr0+1
	clc
	adc #$04
	sta draw_ptr0+1
	and #$1C
	bne :+
		; gone past bottom, roll back and advance line group
		lda draw_ptr0+1
		sec
		sbc #$20
		sta draw_ptr0+1
		lda draw_ptr0+0
		clc
		adc #<$80
		sta draw_ptr0+0
		lda draw_ptr0+1
		adc #>$80
		sta draw_ptr0+1
		and #$04
		beq :+
		; into next 1/3 group, roll back and advance 1/3
		lda draw_ptr0+1
		sec
		sbc #$04
		sta draw_ptr0+1
		lda draw_ptr0+0
		clc
		adc #40
		sta draw_ptr0+0
	:
	rts
.endproc
