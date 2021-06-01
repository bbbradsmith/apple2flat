; video_low
;
; Video driver for low resolution

.include "../a2f.inc"

.export video_mode_low
.export _video_mode_low

.export draw_pixel_low
.export draw_getpixel_low

.import video_page_copy_low
.import video_page_apply

.import video_rowpos0
.import video_rowpos1
.import video_null
.import video_mode_setup
.import VIDEO_FUNCTION_MAX
.import draw_hline_generic
.import draw_vline_generic
.import draw_fillbox_generic

.importzp draw_ptr
.importzp draw_ptr0
.importzp draw_ptr1

.proc video_mode_low
	lda #<table
	ldx #>table
	jmp video_mode_setup
table:
	.word video_page_low
	.word video_page_copy_low
	.word video_cls_low
	.word video_null ; out_text
	.word video_null ; out_text
	.word draw_pixel_low
	.word draw_getpixel_low
	.word draw_hline_generic
	.word draw_vline_generic
	.word draw_fillbox_generic
	.word video_null ; blit_coarse
	.word video_null ; blit_fine
	.word video_null ; blit_mask
	.assert *-table = ((VIDEO_FUNCTION_MAX*2)/3), error, "table entry count incorrect"
.endproc

; void video_mode_low()
_video_mode_low = video_mode_low

.proc video_page_low
	; TODO IIe stuff?
	sta $C052 ; non-mixed (MIXED)
	sta $C050 ; graphics mode (TEXT)
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

.proc draw_pixel_low
	; X/Y = coordinate, A = value
	sta draw_ptr1+0 ; store value
	tya
	lsr
	tay ; Y = Y/2
	lda #0
	rol
	sta draw_ptr1+1 ; store low bit of Y for parity select
	; calculate video address
	lda video_page_w
	and #$0C
	eor #$04 ; $04 or $08
	ora video_rowpos1, Y
	sta draw_ptr0+1
	txa
	clc
	adc video_rowpos0, Y
	sta draw_ptr0+0
	; write either top or bottom half of bits
	ldy #0
	lda draw_ptr1+1 ; parity
	bne @bottom
@top:
	lda (draw_ptr0), Y
	and #$F0
	ora draw_ptr1+0
	sta (draw_ptr0), Y
	rts
@bottom:
	lda (draw_ptr0), Y
	and #$0F
	sta draw_ptr1+1 ; top half
	lda draw_ptr1+0
	asl
	asl
	asl
	asl
	ora draw_ptr1+1
	sta (draw_ptr0), Y
	rts
.endproc

.proc draw_getpixel_low
	; X/Y = coordinate
	tya
	lsr
	tay
	lda #0
	rol
	sta draw_ptr1+1
	lda video_page_w
	and #$0C
	eor #$04
	ora video_rowpos1, Y
	sta draw_ptr0+1
	txa
	clc
	adc video_rowpos0, Y
	sta draw_ptr0+0
	ldy #0
	lda draw_ptr1+1
	bne @bottom
@top:
	lda (draw_ptr0), Y
	and #$0F
	rts
@bottom:
	lda (draw_ptr0), Y
	lsr
	lsr
	lsr
	lsr
	rts
.endproc
