; video_high_text_vwf
;
; Variable-width font text rendering for high resolution graphics modes

.export text_out_high_vwf
.export text_copy_row_high_vwf
.export text_clear_row_high_vwf

.export text_fontset_width

.import text_scroll
.import text_copy_row_high
.import text_clear_row_high
.import text_out_high_glyph
.import text_row_addr_y_draw_ptr1_high
.import draw_ptr1_high_addr_y_inc

.import video_div7

.import video_text_x
.import video_text_xr
.import video_text_w
.import video_text_y
.import video_text_h
.import text_inverse
.import text_fontset
.import text_fontset_offset
.import draw_xh
.importzp a2f_temp
.importzp draw_ptr0
.importzp draw_ptr1
vwf_w       = a2f_temp+4
vwf_glyph   = a2f_temp+5
vwf_inverse = a2f_temp+6
vwf_temp    = a2f_temp+7

; pointer to table of VWF widths, nibble packed  (stored value is width-1)
text_fontset_width: .word 0

.proc div7_mono ; X:A = pixel X 0-279, result: byte in A, phase in X
	cpx #0
	bne @x_right
	cmp #140
	bcs @x_right
@x_left:
	tax
	lda video_div7, X
	pha
	and #7
	tax
	pla
	lsr
	lsr
	lsr
	rts
@x_right:
	sec
	sbc #140
	tax
	lda video_div7, X
	pha
	and #7
	tax
	pla
	lsr
	lsr
	lsr
	clc
	adc #20
	rts
.endproc

bits_copy: ; mask of 0-6 bits remaining (+ 1 attribute)
.byte %10000000
.byte %11000000
.byte %11100000
.byte %11110000
.byte %11111000
.byte %11111100
.byte %11111110

.proc text_out_high_vwf
	; A = value
	; draw_xh:X,Y = coordinate (duplicate of video_text_x/video_text_y)
	sec
	sbc text_fontset_offset
	pha
	; 1. get glyph width (each nibble contains 2 width entries)
	lsr
	tay
	lda text_fontset_width+0
	sta draw_ptr0+0
	lda text_fontset_width+1
	sta draw_ptr0+1
	lda (draw_ptr0), Y
	bcs :+
		and #$0F
		jmp :++
	:
		lsr
		lsr
		lsr
		lsr
	:
	sta vwf_w ; glyph pixel column count -1
	; 2. check for wrap (i.e. will current glyph fit on line)
	lda video_text_x+0
	sec ; +1
	adc vwf_w
	tax
	lda video_text_x+1
	adc #0
	cpx video_text_w+0
	sbc video_text_w+1
	bcc :+ ; no horizontal wrap, just proceed
		inc video_text_y
		lda video_text_xr+0
		sta video_text_x+0
		lda video_text_xr+1
		sta video_text_x+1
		;sta draw_xh ; not needed
		lda video_text_y
		cmp video_text_h
		bcc :+
		; vertical wrap: scroll text
		dec video_text_y
		lda vwf_w
		pha
		lda #1
		jsr text_scroll
		pla
		sta vwf_w
	:
	; 3. draw_ptr0 = glyph data
	pla
	jsr text_out_high_glyph
	; 4. draw_ptr1 = video write position
	ldy video_text_y
	jsr text_row_addr_y_draw_ptr1_high
	lda video_text_x+0
	ldx video_text_x+1
	jsr div7_mono
	clc
	adc draw_ptr1+0
	sta draw_ptr1+0
	txa
	eor #$FF
	sec
	adc #7
	sta vwf_line_phase ; 7 - starting pixel
	; 5. advance text position by width-1 (the last +1 is done in text.s::text_out)
	lda video_text_x+0
	clc
	adc vwf_w ; width-1
	sta video_text_x+0
	lda video_text_x+1
	adc #0
	sta video_text_x+1
	inc vwf_w ; width
	lda vwf_w
	sta vwf_line_w
	; 6. draw line by line
	lda text_inverse
	eor #$80
	sta vwf_inverse ; flip incoming bits if inverse
	lda #0
	sta vwf_line
line:
	lda vwf_line_w
	sta vwf_w
	ldx vwf_line_phase
	ldy vwf_line
	lda (draw_ptr0), Y
	sta vwf_glyph ; line buffer for glyph
	ldy #0
	lda (draw_ptr1), Y
	; prefill A with left pixels
	cpx #0 ; X = vwf_phase (7 - staring pixel)
	beq :++
	:
		asl
		dex
		bne :-
	asl
	ldx vwf_line_phase
byte:
	; copy X bits from glyph buffer into A, stop when X or vwf_w counts down to 0
	:
		cpx #0
		beq :+
		lsr vwf_glyph
		ror
		eor vwf_inverse
		dex
		dec vwf_w
		bne :-
	:
	; fill remaining bits with 0
	stx vwf_temp
	cpx #0
	beq :++
	:
		lsr
		dex
		bne :-
	:
	lsr ; attribute bit
	; copy remaining bits + attribute from original byte
	ldx vwf_temp
	sta vwf_temp
	lda bits_copy, X
	and (draw_ptr1), Y
	ora vwf_temp
	sta (draw_ptr1), Y
	lda vwf_w
	beq next_line
	lda #0 ; reset bit buffer
	iny ; next byte
	ldx #7 ; 7 pixels to fill
	jmp byte
next_line:
	inc vwf_line
	lda vwf_line
	cmp #8
	bcs :+
		jsr draw_ptr1_high_addr_y_inc
		jmp line
	:
	rts
vwf_line:       .byte 0
vwf_line_w:     .byte 0
vwf_line_phase: .byte 0
.endproc

.proc window_vwf_byte
	lda video_text_xr+0
	sta a2f_temp+4
	ldx video_text_xr+1
	jsr div7_mono
	sta video_text_xr+0
	lda video_text_w+0
	sta a2f_temp+5
	ldx video_text_w+1
	jsr div7_mono
	sta video_text_w+0
	cpx #0
	beq :+
		inc video_text_w+0 ; round up
	:
	rts
.endproc

.proc window_vwf_restore
	lda a2f_temp+4
	sta video_text_xr+0
	lda a2f_temp+5
	sta video_text_w+0
	rts
.endproc

text_copy_row_high_vwf:
	; X = copy from
	; Y = copy to
	txa
	pha
	jsr window_vwf_byte
	pla
	tax
	jsr text_copy_row_high
	jmp window_vwf_restore

text_clear_row_high_vwf:
	; X = row to clear
	txa
	pha
	jsr window_vwf_byte
	pla
	tax
	jsr text_clear_row_high
	jmp window_vwf_restore
