; video
;
; A shared interface for video functions.
; Contains a jump network for dispatching subroutines to various video mode drivers.

.include "../a2f.inc"

.export video_cls_page
.export text_out

.export video_cls
.export text_out_
.export text_scroll
.export draw_pixel
.export draw_getpixel
.export draw_hline
.export draw_vline
.export draw_box
.export draw_fillbox
.export blit_tile
.export blit_coarse
.export blit_fine
.export blit_mask

.export video_rowpos0
.export video_rowpos1
.export video_null
.export video_function_table
.export video_function_table_copy
.export VIDEO_FUNCTION_MAX
.export video_rowpos0
.export video_rowpos1

.exportzp draw_ptr
.exportzp draw_ptr0
.exportzp draw_ptr1
.export text_inverse
.export draw_xh
.export draw_x0
.export draw_x1
.export draw_y0
.export draw_y1

.importzp a2f_temp

.segment "ZEROPAGE"
draw_ptr = a2f_temp+0
draw_ptr0 = draw_ptr
draw_ptr1 = a2f_temp+2

.segment "CODE"

video_text_x:  .byte 0
video_text_y:  .byte 0
video_text_w:  .byte 40
video_text_h:  .byte 24
video_text_xr: .byte 0
video_text_yr: .byte 0
video_page_w:  .byte 0
video_page_r:  .byte 0
text_inverse:  .byte $80
draw_x0: .byte 2 ; draw parameter / temporaries
draw_x1: .byte 2
draw_y0: .byte 1
draw_y1: .byte 1
draw_xh = draw_x0+1

video_function_table:
video_cls:     jmp a:video_null
text_out_:     jmp a:video_null
text_scroll:   jmp a:video_null
draw_pixel:    jmp a:video_null
draw_getpixel: jmp a:video_null
draw_hline:    jmp a:video_null
draw_vline:    jmp a:video_null
draw_box:      jmp a:video_null
draw_fillbox:  jmp a:video_null
blit_tile:     jmp a:video_null
blit_coarse:   jmp a:video_null
blit_fine:     jmp a:video_null
blit_mask:     jmp a:video_null
VIDEO_FUNCTION_MAX = *-video_function_table
.assert VIDEO_FUNCTION_MAX<256, error, "video_function_table too large?"
; TODO video_bound, video_bound_coarse to check screen bounds as a boolean?

.proc video_null ; empty function for unimplemented/unimplementable video functions
	rts
.endproc

.proc video_function_table_copy
	sta draw_ptr+0
	stx draw_ptr+1
	ldx #1
	ldy #0
	:
		lda (draw_ptr), Y
		sta video_function_table, X
		iny
		inx
		lda (draw_ptr), Y
		sta video_function_table, X
		iny
		inx
		inx
		cpx #VIDEO_FUNCTION_MAX
		bcc :-
	rts
.endproc

; lookup tables for Apple II video layout in 8 x 3-row groups
video_rowpos0:
	.repeat 24, I
		.byte <(((I .mod 8)*$80)+((I / 8)*40))
	.endrepeat
video_rowpos1:
	.repeat 24, I
		.byte >(((I .mod 8)*$80)+((I / 8)*40))
	.endrepeat

.proc video_cls_page
; A = fill value
; X = page select (CLS_LOW0, CLS_LOW1, CLS_HIGH0, etc.)
ptr = a2f_temp+0
	cpx #CLS_HIGH0
	bcc low
	cpx #CLS_HIGH1+1
	bcs high
	rts ; invalid page index
low:
	ldy #$04 ; LOW0 at $400
	cpx #CLS_LOW1
	bne :+
		ldy #$08 ; LOW1 at $800
	:
	ldx #(24/3) ; count of 3 row groupings
	jmp clear
high:
	ldy #$20 ; HIGH0 at $2000
	cpx #CLS_HIGH1
	bne :+
		ldy #$40 ; HIGH1 at $4000
	:
	ldx #((24*4)/3) ; count of 3 row groupings
clear:
	sty ptr+1
	ldy #0
	sty ptr+0
@group:
	ldy #(40*3)-1 ; 3 rows in a group
@row:
	sta (ptr), Y
	dey
	bpl @row
	dex
	bne :+
		rts
	:
	pha
	lda #<$80 ; groups are $80 bytes apart
	clc
	adc ptr+0
	sta ptr+0
	lda #>$80
	adc ptr+1
	sta ptr+1
	pla
	jmp @group
.endproc

.proc text_out
	; A = ASCII character to print
	;     13 = newline
	;     14 = shift to normal
	;     15 = shift to inverse
	; Advances text out position.
	cmp #$20 ; first 32 values are considered control codes
	bcs ready
	cmp #13 ; newline
	bne :+
		lda video_text_xr
		sta video_text_x
		inc video_text_y
		rts
	:
	cmp #14 ; normal
	bne :+
		lda #$80
		sta text_inverse
		rts
	:
	cmp #15 ; inverse
	bne :+
		lda #$00
		sta text_inverse
		rts
	:
	; allow other control codes to pass through?
ready:
	ldx video_text_x
	cpx video_text_w
	bcc :+ ; wrap to next line
		ldx video_text_xr
		inc video_text_y
	:
	ldy video_text_y
	cpy video_text_h
	bcc :+ ; wrap to top
		ldy video_text_yr
		sty video_text_y
	:
	jsr text_out_
	inc video_text_x
	rts
.endproc
