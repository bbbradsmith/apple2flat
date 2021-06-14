; video_double_high_color
;
; Video driver for double high resolution colour

.include "../a2f.inc"

.export video_mode_double_high_color
.export _video_mode_double_high_color

.export draw_pixel_double_high_color
.export draw_getpixel_double_high_color

.import video_page_copy_double_high
.import video_page_apply
.import video_cls_double_high
.import draw_high_addr_y
.import draw_high_color_addr_x

.import text_out_double_high_color
.import text_copy_row_double_high_color
.import text_clear_row_double_high_color

.import video_div7
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.importzp video_double_read_aux
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp a2f_temp
.importzp draw_ptr
draw_high_color = a2f_temp+2
draw_high_phase = a2f_temp+3

.proc video_mode_double_high_color
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_color
	.word video_page_copy_double_high
	.word video_cls_double_high
	.word text_out_double_high_color
	.word text_copy_row_double_high_color
	.word text_clear_row_double_high_color
	.word draw_pixel_double_high_color
	.word draw_getpixel_double_high_color
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_color()
_video_mode_double_high_color = video_mode_double_high_color

.proc video_mode_set_double_high_color
	sta $C050 ; graphics mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C057 ; high-res (HIRES)
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00D ; 80 columns (80COL)
	sta $C05E ; RGB 11 = color
	sta $C05F
	sta $C05E
	sta $C05F
	sta $C05E ; double-hires on (AN3/DHIRES)
	jmp video_page_apply
.endproc

.proc draw_pixel_double_high_color
	; X/Y = coordinate, A = value
	sta draw_high_color ; save value
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
	ldx draw_high_phase
	beq @x0
	cpx #4
	bcs @x456
	cpx #2
	beq @x2
	bcc @x1
	bcs @x3
@x0: ; 1M.xxxxxxx 1A.xxxxxxx 0M.xxxxxxx 0A.xxx----
	ldy #0
	jsr video_double_read_aux
	and #%1110000
	ora draw_high_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	rts
@x1: ; 1M.xxxxxxx 1A.xxxxxxx 0M.xxxxxx- 0A.---xxxx
	lda draw_high_color
	tax
	asl
	asl
	asl
	asl
	and #%01110000
	sta draw_high_color
	ldy #0
	jsr video_double_read_aux
	and #%00001111
	ora draw_high_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	txa
	lsr
	lsr
	lsr
	sta draw_high_color
	lda (draw_ptr), Y
	and #%01111110
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x2: ; 1M.xxxxxxx 1A.xxxxxxx 0M.xx----x 0A.xxxxxxx
	lda draw_high_color
	asl
	sta draw_high_color
	ldy #0
	lda (draw_ptr), Y
	and #%01100001
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x456:
	beq @x4
	cpx #5
	beq @x5
	bne @x6
@x3: ; 1M.xxxxxxx 1A.xxxxx-- 0M.--xxxxx 0A.xxxxxxx
	lda draw_high_color
	tax
	lsr
	ror
	ror
	ror
	and #%01100000
	sta draw_high_color
	ldy #0
	lda (draw_ptr), Y
	and #%00011111
	ora draw_high_color
	sta (draw_ptr), Y
	txa
	lsr
	lsr
	sta draw_high_color
	iny
	jsr video_double_read_aux
	and #%01111100
	ora draw_high_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	rts
@x4: ; 1M.xxxxxxx 1A.x----xx 0M.xxxxxxx 0A.xxxxxxx
	lda draw_high_color
	asl
	asl
	sta draw_high_color
	ldy #1
	jsr video_double_read_aux
	and #%01000011
	ora draw_high_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	rts
@x5: ; 1M.xxxx--- 1A.-xxxxxx 0M.xxxxxxx 0A.xxxxxxx
	lda draw_high_color
	tax
	lsr
	ror
	ror
	and #%01000000
	sta draw_high_color
	ldy #1
	jsr video_double_read_aux
	and #%00111111
	ora draw_high_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	txa
	lsr
	sta draw_high_color
	lda (draw_ptr), Y
	and #%01111000
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@x6: ; 1M.----xxx 1A.xxxxxxx 0M.xxxxxxx 0A.xxxxxxx
	lda draw_high_color
	asl
	asl
	asl
	and #%01111000
	sta draw_high_color
	ldy #1
	lda (draw_ptr), Y
	and #%00000111
	ora draw_high_color
	sta (draw_ptr), Y
	rts
.endproc

.proc draw_getpixel_double_high_color
	; X/Y = coordinate
	jsr draw_high_addr_y
	jsr draw_high_color_addr_x
	; read 4-bytes to stack
	ldy #1
	:
		lda (draw_ptr), Y
		pha
		jsr video_double_read_aux
		pha
		dey
		bpl :-
	ldx draw_high_phase
	; unpack stack to a2f_temp (overwrites draw_ptr, draw_high_color, draw_high_phase)
	; eliminating gaps at bit 7
	pla
	asl
	sta a2f_temp+0 ; 0000000.
	pla
	lsr
	ror a2f_temp+0 ; 10000000
	asl
	asl
	sta a2f_temp+1 ; 111111.. 10000000
	pla
	lsr
	ror a2f_temp+1
	lsr
	ror a2f_temp+1
	asl
	asl
	asl
	sta a2f_temp+2 ; 22222... 22111111 1000000
	pla
	lsr
	ror a2f_temp+2
	lsr
	ror a2f_temp+2
	lsr
	ror a2f_temp+2
	sta a2f_temp+3 ; ....3333 33322222 22111111 1000000
	; 32-bit rotate to isolate pixel
	lda a2f_temp+0
	cpx #0
	beq @found
	@rotate:
		ldy #4
		:
			lsr a2f_temp+3
			ror a2f_temp+2
			ror a2f_temp+1
			ror
			dey
			bne :-
		dex
		bne @rotate
	@found:
	and #%00001111
	rts
.endproc
