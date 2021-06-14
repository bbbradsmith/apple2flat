; video_double_high_color_text
;
; Text rendering for double-high resolution colour mode (40 columns)

.export text_out_double_high_color
.export text_copy_row_double_high_color
.export text_clear_row_double_high_color

.import video_rowpos0
.import video_rowpos1
.import draw_high_addr_y_inc
.importzp video_double_read_aux

.import text_copy_row_high
.import text_clear_row_high
.import text_row_addr_x_draw_ptr0_high
.import text_row_addr_y_draw_ptr1_high
.import draw_ptr1_high_addr_y_inc
.import text_out_high_prepare

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
line_count = a2f_temp+6

pixel_doubling:
.byte %00000000
.byte %00000011
.byte %00001100
.byte %00001111
.byte %00110000
.byte %00110011
.byte %00111100
.byte %00111111
.byte %11000000
.byte %11000011
.byte %11001100
.byte %11001111
.byte %11110000
.byte %11110011
.byte %11111100
.byte %11111111

text_out_double_high_color:
	; A = value
	; X/Y = coordinate
	jsr text_out_high_prepare
	; copy glyph, doubling pixels
	ldy #0
	sty blit_read_y
	ldx #8
	stx line_count
	:
		ldy blit_read_y
		lda (draw_ptr0), Y
		pha
		and #$0F
		tax
		lda pixel_doubling, X
		and #%01111111
		eor text_high_inverse
		ldy #0
		sta $C005 ; aux (RAMWRT)
		sta (draw_ptr1), Y
		sta $C004 ; main (RAMWRT)
		pla
		lsr
		lsr
		lsr
		and #$0F
		tax
		lda pixel_doubling, X
		lsr
		eor text_high_inverse
		sta (draw_ptr1), Y
		dec line_count
		beq :+
		jsr draw_ptr1_high_addr_y_inc
		inc blit_read_y
		jmp :-
	:
	rts

text_copy_row_double_high_color:
	; X = copy from
	; Y = copy to
	txa
	pha
	tya
	pha
	jsr text_copy_row_high ; odd columns
	pla
	tay
	pla
	tax
	; even columns
	jsr text_row_addr_x_draw_ptr0_high
	jsr text_row_addr_y_draw_ptr1_high
	ldx #8
	sta $C005 ; aux (RAMWRT)
@line:
	ldy video_text_xr
	:
		cpy video_text_w
		bcs :+
		jsr video_double_read_aux
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
	sta $C004 ; main (RAMWRT)
	rts

text_clear_row_double_high_color:
	; X = row to clear
	txa
	pha
	jsr text_clear_row_high ; odd columns
	pla
	tax
	sta $C005 ; aux (RAMWRT)
	jsr text_clear_row_high ; even columns
	sta $C004 ; main (RAMWRT)
	rts
