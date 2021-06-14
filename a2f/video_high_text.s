; video_high_text
;
; Text rendering for high resolution graphics modes.

.export text_out_high
.export text_copy_row_high
.export text_clear_row_high

.export text_row_addr_x_draw_ptr0_high
.export text_row_addr_y_draw_ptr1_high
.export draw_ptr1_high_addr_y_inc
.export text_out_high_prepare

.import video_rowpos0
.import video_rowpos1
.import draw_high_addr_y_inc

.import video_text_xr
.import video_text_w
.import video_page_w
.import text_inverse
.import text_fontset
.import text_fontset_offset
.importzp a2f_temp
.importzp draw_ptr0
.importzp draw_ptr1
blit_read_y = a2f_temp+4
text_high_inverse = a2f_temp+5

text_row_addr_x_draw_ptr0_high: ; X = row to draw_ptr0, clobbers A
	lda video_page_w
	and #$60
	eor #$20
	ora video_rowpos1, X
	sta draw_ptr0+1
	lda video_rowpos0, X
	sta draw_ptr0+0
	rts

text_row_addr_y_draw_ptr1_high: ; Y = row to draw_ptr1, clobbers A
	lda video_page_w
	and #$60
	eor #$20
	ora video_rowpos1, Y
	sta draw_ptr1+1
	lda video_rowpos0, Y
	sta draw_ptr1+0
	rts

.proc draw_ptr1_high_addr_y_inc
	; advance by 1 line
	lda draw_ptr1+1
	clc
	adc #$04
	sta draw_ptr1+1
	and #$1C
	bne :+
		; gone past bottom, roll back and advance line group
		lda draw_ptr1+1
		sec
		sbc #$20
		sta draw_ptr1+1
		lda draw_ptr1+0
		clc
		adc #<$80
		sta draw_ptr1+0
		lda draw_ptr1+1
		adc #>$80
		sta draw_ptr1+1
		and #$04
		beq :+
		; into next 1/3 group, roll back and advance 1/3
		lda draw_ptr1+1
		sec
		sbc #$04
		sta draw_ptr1+1
		lda draw_ptr1+0
		clc
		adc #40
		sta draw_ptr1+0
	:
	rts
.endproc

text_out_high_prepare: ; A = value, X/Y = coordinate
	; 1. draw_ptr1 = video write position
	pha
	jsr text_row_addr_y_draw_ptr1_high
	txa
	clc
	adc draw_ptr1+0
	sta draw_ptr1+0
	pla
	; 2. draw_ptr0 = glyph data
	sec
	sbc text_fontset_offset
	sta draw_ptr0+0
	lda #0
	ldx #3
	:
		asl draw_ptr0+0
		rol
		dex
		bne :-
	sta draw_ptr0+1 ; glyph * 8 bytes
	lda text_fontset+0
	clc
	adc draw_ptr0+0
	sta draw_ptr0+0
	lda text_fontset+1
	adc draw_ptr0+1
	sta draw_ptr0+1
	; 3. text_high_inverse is XOR mask for inverse text
	lda #0
	bit text_inverse
	bmi :+
		lda #$7F
	:
	sta text_high_inverse
	rts

text_out_high:
	; A = value
	; X/Y = coordinate
	jsr text_out_high_prepare
	; 4. copy glyph
	ldy #0
	sty blit_read_y
	ldx #8
	:
		ldy blit_read_y
		lda (draw_ptr0), Y
		eor text_high_inverse
		ldy #0
		sta (draw_ptr1), Y
		dex
		beq :+
		jsr draw_ptr1_high_addr_y_inc
		inc blit_read_y
		jmp :-
	:
	rts

text_copy_row_high:
	; X = copy from
	; Y = copy to
	jsr text_row_addr_x_draw_ptr0_high
	jsr text_row_addr_y_draw_ptr1_high
	ldx #8
@line:
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		lda (draw_ptr0), Y
		sta (draw_ptr1), Y
		iny
		jmp :-
	:
	dex
	beq :+
	jsr draw_high_addr_y_inc ; advance draw_ptr0 by 1 line
	jsr draw_ptr1_high_addr_y_inc
	jmp @line
:
	rts

text_clear_row_high:
	; X = row to clear
	jsr text_row_addr_x_draw_ptr0_high
	ldx #8
@line:
	lda #0
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		sta (draw_ptr0), Y
		iny
		jmp :-
	:
	dex
	beq :+
	jsr draw_high_addr_y_inc ; advance draw_ptr0 by 1 line
	jmp @line
:
	rts
