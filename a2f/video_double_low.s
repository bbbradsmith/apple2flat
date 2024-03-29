; video_double_low
;
; Video driver for double low resolution

.include "../a2f.inc"

.export video_mode_double_low
.export _video_mode_double_low

.export draw_pixel_double_low
.export draw_getpixel_double_low
.export blit_double_low

.import video_page_copy_double_low
.import video_page_apply

.import video_rowpos0
.import video_rowpos1
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import video_double_rw_aux_setup
.importzp video_double_read_aux
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.import draw_pixel_low
.import draw_getpixel_low
.import draw_pixel_low_addr
.import draw_pixel_low_addr_2y

.importzp a2f_temp
.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1
draw_low_color = a2f_temp+2
draw_low_phase = a2f_temp+3
blit_w = a2f_temp+4
blit_h = a2f_temp+5

.proc video_mode_double_low
	lda #<table
	ldx #>table
	jsr video_mode_setup
	jmp video_double_rw_aux_setup
table:
	.word video_mode_set_double_low
	.word video_page_copy_double_low
	.word video_cls_double_low
	.word video_null
	.word video_null
	.word video_null
	.word draw_pixel_double_low
	.word draw_getpixel_double_low
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word blit_double_low
	.word 80
	.byte 48
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_low()
_video_mode_double_low = video_mode_double_low

.proc video_mode_set_double_low
	sta $C050 ; graphics mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C056 ; low-res (HIRES)
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00D ; 80 columns (80COL)
	sta $C05E ; RGB 11 = colour
	sta $C05F
	sta $C05E
	sta $C05F
	sta $C05E ; double-hires on (AN3/DHIRES)
	jmp video_page_apply
.endproc

.proc video_cls_double_low
	lda video_page_w
	and #1
	eor #CLS_DLOW0
	tax
	lda #0
	jmp video_cls_page
.endproc

.proc draw_pixel_double_low ; A = value, X/Y = coordinate
	sta draw_low_color
	txa
	lsr
	tax
	bcc :+
		lda draw_low_color
		jmp draw_pixel_low
	:
	jsr draw_pixel_low_addr
	; aux memory colours are remapped (barrel rotate nibble right)
	lsr draw_low_color
	bcc :+
		lda draw_low_color
		ora #$08
		sta draw_low_color
	:
	; write either top or bottom half of bits
	ldy #0
	lda draw_low_phase ; parity
	bne @bottom
@top:
	jsr video_double_read_aux
	and #$F0
	ora draw_low_color
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	rts
@bottom:
	jsr video_double_read_aux
	and #$0F
	sta draw_low_phase ; top half
	lda draw_low_color
	asl
	asl
	asl
	asl
	ora draw_low_phase ; top half
	sta $C005 ; aux (RAMWRT)
	sta (draw_ptr), Y
	sta $C004 ; main (RAMWRT)
	rts
.endproc

.proc draw_getpixel_double_low ; X/Y = coordinate
	txa
	lsr
	tax
	bcc :+
		jmp draw_getpixel_low
	:
	jsr draw_pixel_low_addr
	ldy #0
	lda draw_low_phase
	bne @bottom
@top:
	jsr video_double_read_aux
	and #$0F
	jmp @unscramble
@bottom:
	jsr video_double_read_aux
	lsr
	lsr
	lsr
	lsr
@unscramble: ; undo the aux memory colour mapping (barrel rotate nibble left)
	asl
	cmp #$10
	bcc :+
		eor #$11
	:
	rts
.endproc

.proc blit_double_low
	; X/2Y = coordinate, draw_ptr1 = data
	txa
	lsr
	tax
	; TODO store low bit of X as parity
	jsr draw_pixel_low_addr_2y ; draw_ptr0 = address
	ldy #0
	lda (draw_ptr1), Y
	sta blit_w
	iny
	lda (draw_ptr1), Y
	sta blit_h
	iny
	ldx #0
@loop:
	lda (draw_ptr1), Y
	; TODO alternate store / aux store by parity (aux store needs to nibble rotate right)
	;sta (draw_ptr0), X
	; TODO don't use X to index draw ptr, instead increment
	iny
	bne :+
		inc draw_ptr1+1
	:
	inx
	cpx blit_w
	bcc @loop
	lda draw_ptr0+0
	clc
	adc #<128
	sta draw_ptr0+0
	bcc :+
		inc draw_ptr0+1
		lda draw_ptr0+1
		and #$03
		bne :+ ; past end of page, go to next group of 8 lines
		lda draw_ptr0+0
		sec
		sbc #<($400-40)
		sta draw_ptr0+0
		lda draw_ptr0+1
		sbc #>($400-40)
		sta draw_ptr0+1
	:
	dec blit_h
	bne @loop
	rts
.endproc
