; video_low
;
; Video driver for low resolution

.include "../a2f.inc"

.export video_mode_low
.export _video_mode_low

.export draw_pixel_low
.export draw_getpixel_low
.export draw_pixel_low_addr
.export draw_pixel_low_addr_2y
.export blit_low

.import video_page_copy_low
.import video_page_apply

.import video_rowpos0
.import video_rowpos1
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_TABLE_SIZE
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp a2f_temp
.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1
draw_low_color = a2f_temp+2
draw_low_phase = a2f_temp+3
blit_w = a2f_temp+4
blit_h = a2f_temp+5
blit_temp = a2f_temp+6

.proc video_mode_low
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_mode_set_low
	.word video_page_copy_low
	.word video_cls_low
	.word video_null ; text_out
	.word video_null ; text_copy_row
	.word video_null ; text_clear_row
	.word draw_pixel_low
	.word draw_getpixel_low
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word blit_low
	.word 40
	.byte 24
	.assert *-table = VIDEO_FUNCTION_TABLE_SIZE, error, "table entry count incorrect"
.endproc

; void video_mode_low()
_video_mode_low = video_mode_low

.proc video_mode_set_low
	; set mode
	sta $C050 ; graphics mode (TEXT)
	sta $C052 ; non-mixed (MIXED)
	sta $C056 ; low-res (HIRES)
	; double/RGB settings
	sta $C07E ; enable DHIRES switch (IOUDIS)
	sta $C00D ; RGB 11 = color
	sta $C05E
	sta $C05F
	sta $C05E
	sta $C05F ; double-hires off (AN3/DHIRES)
	sta $C00C ; 40 columns (80COL)
	jmp video_page_apply
.endproc

.proc video_cls_low
	lda video_page_w
	and #1
	eor #CLS_LOW0
	tax
	lda #0
	jmp video_cls_page
.endproc

draw_pixel_low_addr: ; X/Y = coordinate, clobbers A, sets draw_ptr, draw_low_phase stores parity
	tya
	lsr
	tay ; Y = Y/2
	lda #0
	rol
	sta draw_low_phase ; store low bit of Y for parity select
draw_pixel_low_addr_2y: ; X = 0-39, Y = 0-24 (address but Y is a double-row, no "phase")
	; calculate video address
	lda video_page_w
	and #$0C
	eor #$04 ; $04 or $08
	ora video_rowpos1, Y
	sta draw_ptr+1
	txa
	clc
	adc video_rowpos0, Y
	sta draw_ptr+0
	rts

.proc draw_pixel_low
	; X/Y = coordinate, A = value
	sta draw_low_color ; store value
	jsr draw_pixel_low_addr
	; write either top or bottom half of bits
	ldy #0
	lda draw_low_phase ; parity
	bne @bottom
@top:
	lda (draw_ptr), Y
	and #$F0
	ora draw_low_color
	sta (draw_ptr), Y
	rts
@bottom:
	lda (draw_ptr), Y
	and #$0F
	sta draw_low_phase ; top half
	lda draw_low_color
	asl
	asl
	asl
	asl
	ora draw_low_phase ; top half
	sta (draw_ptr), Y
	rts
.endproc

.proc draw_getpixel_low
	; X/Y = coordinate
	jsr draw_pixel_low_addr
	ldy #0
	lda draw_low_phase
	bne @bottom
@top:
	lda (draw_ptr), Y
	and #$0F
	rts
@bottom:
	lda (draw_ptr), Y
	lsr
	lsr
	lsr
	lsr
	rts
.endproc

.proc blit_low
	; X/2Y = coordinate, draw_ptr1 = data
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
	ldx #0
	dec blit_h
	bne @loop
	rts
.endproc
