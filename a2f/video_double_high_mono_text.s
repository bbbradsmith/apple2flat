; video_double_high_mono_text
;
; Text rendering for double-high resolution mono mode (80 columns)

.export text_out_double_high_mono
.export text_copy_row_double_high_mono
.export text_clear_row_double_high_mono

.import video_rowpos0
.import video_rowpos1
.import draw_high_addr_y_inc
.importzp video_double_read_aux

.import text_out_high
.import text_copy_row_high
.import text_clear_row_high
.import text_row_addr_x_draw_ptr0_high
.import text_row_addr_y_draw_ptr1_high
.import draw_ptr1_high_addr_y_inc

.import video_text_xr
.import video_text_w
.importzp a2f_temp
.importzp draw_ptr0
.importzp draw_ptr1
blit_read_y = a2f_temp+4
text_high_inverse = a2f_temp+5

text_out_double_high_mono:
	; A = value
	; X/Y = coordinate
	pha
	txa
	lsr
	tax
	bcc :+
		; odd columns
		pla
		jmp text_out_high
	:
		; even columns
		pla
		sta $C005 ; aux (RAMWRT)
		jsr text_out_high
		sta $C004 ; main (RAMWRT)
		rts
	;

text_copy_row_double_high_mono:
	; X = copy from
	; Y = copy to
	; odd columns
	lda video_text_xr+0
	pha
	lsr
	sta video_text_xr+0
	lda video_text_w+0
	pha
	lsr
	sta video_text_w+0
	txa
	pha
	tya
	pha
	jsr text_copy_row_high
	pla
	tay
	tsx
	lda $102, X
	lsr
	adc #0
	sta video_text_w+0
	lda $103, X
	lsr
	adc #0
	sta video_text_xr+0
	pla
	tax
	jsr text_row_addr_x_draw_ptr0_high
	jsr text_row_addr_y_draw_ptr1_high
	ldx #8
	sta $C005 ; aux (RAMWRT)
@line:
	ldy video_text_xr+0
	:
		cpy video_text_w+0
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
text_row_double_high_mono_restore_window:
	pla
	sta video_text_w+0
	pla
	sta video_text_xr+0
	rts

text_clear_row_double_high_mono:
	; X = row to clear
	; even columns
	lda video_text_xr+0
	pha
	lsr
	adc #0
	sta video_text_xr+0
	lda video_text_w+0
	pha
	lsr
	adc #0
	sta video_text_w+0
	txa
	pha
	sta $C005 ; aux (RAMWRT)
	jsr text_clear_row_high
	sta $C004 ; main (RAMWRT)
	; odd columns
	tsx
	lda $102, X
	lsr
	sta video_text_w+0
	lda $103, X
	sta video_text_xr+0
	pla
	tax
	jsr text_clear_row_high
	jmp text_row_double_high_mono_restore_window
