; video_high_text
;
; Text rendering for high resolution graphics modes

.export text_out_high
.export text_out_high_prepare

.import text_row_addr_y_draw_ptr1_high
.import draw_ptr1_high_addr_y_inc
.import draw_high_addr_y_inc
.import text_out_high_glyph

.import text_inverse
.import text_fontset_offset
.importzp a2f_temp
.importzp draw_ptr0
.importzp draw_ptr1
blit_read_y = a2f_temp+4
text_high_inverse = a2f_temp+5

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
	jsr text_out_high_glyph
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
