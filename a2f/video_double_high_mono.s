; video_double_high_mono
;
; Video driver for double high resolution monochrome

.include "../a2f.inc"

.export video_mode_double_high_mono
.export _video_mode_double_high_mono

.export draw_pixel_double_high_mono
.export draw_getpixel_double_high_mono

.import video_page_copy_double_high
.import video_page_apply
.import video_cls_double_high
.import draw_high_addr_y

.import text_out_double_high_mono
.import text_copy_row_double_high_mono
.import text_clear_row_double_high_mono

.import video_div7
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.importzp video_double_read_aux
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.import draw_xh
.importzp draw_ptr
.importzp a2f_temp

draw_high_color = a2f_temp+2
draw_high_phase = a2f_temp+3

.proc video_mode_double_high_mono
	lda #<table
	ldx #>table
	jsr video_mode_setup
	asl video_text_w ; 40 << 1 = 80
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_high_mono
	.word video_page_copy_double_high
	.word video_cls_double_high
	.word text_out_double_high_mono
	.word text_copy_row_double_high_mono
	.word text_clear_row_double_high_mono
	.word draw_pixel_double_high_mono
	.word draw_getpixel_double_high_mono
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_double_high_mono()
_video_mode_double_high_mono = video_mode_double_high_mono

.proc video_mode_set_double_high_mono
	sta $C050 ; graphics mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C057 ; high-res (HIRES)
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00C
	sta $C05E ; RGB 00 = mono
	sta $C05F
	sta $C05E
	sta $C05F
	sta $C05E ; double-hires on (AN3/DHIRES)
	sta $C00D ; 80 columns (80COL)
	jmp video_page_apply
.endproc

.proc draw_double_high_mono_addr_x ; draw_xh:X pixel address to draw_ptr, sub-pixel in draw_high_phase
	; draw_xh:X/Y = coordinate, A = value
	; split into quadrants: 000,140,280,420
	lda draw_xh
	bne :+ ; xh = 0
		cpx #140
		bcs @x140
		bcc @x000
	:
	cmp #2
	bcs @x420 ; xh = 2, >= 512
	cpx #<280
	bcc @x140 ; xh = 1, < 280
	cpx #<420
	bcs @x420 ; xh = 1, >= 420
	bcc @x280 ; xh = 1, >= 280, < 420
@x000:
	jsr @div
	php
	jmp @x_finish
@x140:
	txa
	sec
	sbc #140
	tax
	jsr @div
	php
	clc
	adc #10
	jmp @x_finish
@x280:
	txa
	sec
	sbc #<280
	tax
	jsr @div
	php
	clc
	adc #20
	jmp @x_finish
@x420:
	txa
	sec
	sbc #<420
	tax
	jsr @div
	php
	clc
	adc #30
	;jmp @x_finish
@x_finish:
	clc
	adc draw_ptr+0
	sta draw_ptr+0
	lda #0
	plp ; recover C to place even/odd parity in high bit of draw_high_phase
	ror
	eor draw_high_phase
	sta draw_high_phase
	rts
@div:
	lda video_div7, X
	and #7
	sta draw_high_phase
	lda video_div7, X
	lsr
	lsr
	lsr
	lsr ; even/odd parity in C
	rts
.endproc

.proc draw_pixel_double_high_mono
	; draw_xh:X/Y = coordinate, A = value
	sta draw_high_color ; save value
	jsr draw_high_addr_y
	jsr draw_double_high_mono_addr_x
	ldy #0
	lda draw_high_phase
	and #7
	tax
	lda #1 ; inverse mask for pixel
	cpx #0
	beq :++
	:
		asl
		asl draw_high_color
		dex
		bne :-
	:
	eor #$FF ; and-mask
	bit draw_high_phase
	bpl @aux
@main:
	and (draw_ptr), Y
	ora draw_high_color
	sta (draw_ptr), Y
	rts
@aux:
	sta draw_high_phase
	jsr video_double_read_aux
	and draw_high_phase
	ora draw_high_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	rts
.endproc

.proc draw_getpixel_double_high_mono
	; draw_xy:X/Y = coordinate
	jsr draw_high_addr_y
	jsr draw_double_high_mono_addr_x
	ldy #0
	lda draw_high_phase
	bpl @aux
@main:
	lda (draw_ptr), Y
	pha
	lda draw_high_phase
	and #7
	tax
	pla
	cpx #0
	jmp @finish
@aux:
	jsr video_double_read_aux
	ldx draw_high_phase
	;jmp @finish
@finish:
	beq :++
	:
		lsr
		dex
		bne :-
	:
	and #1
	rts
.endproc
