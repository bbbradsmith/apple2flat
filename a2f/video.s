; video
;
; A shared interface for video functions.
; Contains a jump network for dispatching subroutines to various video mode drivers.

.include "../a2f.inc"

.export video_page_apply
.export video_cls_page

.export video_cls
.export text_out_
.export text_copy_row
.export text_clear_row
.export draw_pixel
.export draw_getpixel
.export draw_hline
.export draw_vline
.export draw_fillbox

.export video_rowpos0
.export video_rowpos1
.export video_null
.export video_function_table
.export video_mode_setup
.export VIDEO_FUNCTION_TABLE_SIZE

.exportzp draw_ptr
.exportzp draw_ptr0
.exportzp draw_ptr1
.export video_page_w
.export video_page_r
.export draw_x0
.export draw_x1
.export draw_y0
.export draw_y1
.export draw_xh

.importzp a2f_temp

.segment "ZEROPAGE"
draw_ptr = a2f_temp+0
draw_ptr0 = draw_ptr
draw_ptr1 = a2f_temp+2

.segment "CODE"

video_page_w:  .byte 0
video_page_r:  .byte 0

draw_x0: .byte 0,0 ; draw parameter / temporaries
draw_x1: .byte 0,0
draw_y0: .byte 0
draw_y1: .byte 0
draw_xh = draw_x0+1 ; alias

video_function_table:
video_mode_set:  jmp a:video_null
video_page_copy: jmp a:video_null
video_cls:       jmp a:video_null
text_out_:       jmp a:video_null
text_copy_row:   jmp a:video_null
text_clear_row:  jmp a:video_null
draw_pixel:      jmp a:video_null
draw_getpixel:   jmp a:video_null
draw_hline:      jmp a:video_null
draw_vline:      jmp a:video_null
draw_fillbox:    jmp a:video_null
VIDEO_FUNCTION_MAX = *-video_function_table
.assert VIDEO_FUNCTION_MAX<256, error, "video_function_table too large?"
VIDEO_FUNCTION_TABLE_SIZE = (VIDEO_FUNCTION_MAX*2)/3

.proc video_null ; empty function for unimplemented/unimplementable video functions
	rts
.endproc

; sets up common video mode stuff:
; 1. copies function table
; 2. resets text window and text position to 0,0 (but not w/h)
; 3. calls video_page to display the page
.proc video_mode_setup ; X:A = pointer to function table
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
	; default text window
	lda #0
	sta video_text_x
	sta video_text_y
	sta video_text_xr
	sta video_text_yr
	lda #40
	sta video_text_w
	lda #24
	sta video_text_h
	jmp video_mode_set
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

.proc video_page_apply
	lda video_page_r
	and #1
	tax
	sta $C054, X ; (PAGE2)
	rts
.endproc

.proc video_cls_page
; A = fill value
; X = page select (CLS_LOW0, CLS_LOW1, CLS_HIGH0, etc.)
ptr   = a2f_temp+0
xtemp = a2f_temp+2
	cpx #CLS_DLOW0
	bcs double
	cpx #CLS_MIXED0
	bcs mixed
	cpx #CLS_HIGH0
	bcs high
low:
	ldy #$04 ; LOW0 at $400
	cpx #CLS_LOW1
	bne :+
		ldy #$08 ; LOW1 at $800
	:
	ldx #(24/3) ; count of 3 row groupings
	jmp clear
mixed:
	ldy #$50
	sty ptr+0
	ldy #$06 ; MIXED0 at $650
	cpx #CLS_MIXED1
	bne :+
		ldy #$0A ; MIXED1 at $A50
	:
	sty ptr+1
	jsr mixed_line
	jsr mixed_line
	jsr mixed_line
mixed_line:
	ldy #40-1
	ldx #1
	jsr row
	jmp next_group
high:
	ldy #$20 ; HIGH0 at $2000
	cpx #CLS_HIGH1
	bne :+
		ldy #$40 ; HIGH1 at $4000
	:
	ldx #((24*8)/3) ; count of 3 row groupings
clear:
	sty ptr+1
	ldy #0
	sty ptr+0
clear_group:
	ldy #(40*3)-1 ; 3 rows in a group
row:
	sta (ptr), Y
	dey
	bpl row
	dex
	bne :+
		rts
	:
	jsr next_group
	jmp clear_group
next_group:
	pha
	lda #<$80 ; groups are $80 bytes apart
	clc
	adc ptr+0
	sta ptr+0
	lda #>$80
	adc ptr+1
	sta ptr+1
	pla
	rts
double:
	; NOTE: double modes work by clearing aux page then main using the single versions,
	;       so they may not rely on variable writes to RAM outside of ZP/stack.
	cpx #CLS_DMIXED1+1
	bcc :+
		rts ; invalid entry
	:
	pha
	txa
	sec
	sbc #CLS_DLOW0-CLS_LOW0
	tax
	stx xtemp
	pla
	pha
	sta $C005 ; aux (RAMWRT)
	jsr video_cls_page
	sta $C004 ; main (RAMWRT)
	ldx xtemp
	pla
	jmp video_cls_page
.endproc

.proc video_page_flip
	lda video_page_w
	eor #$FF
	sta video_page_w
	lda video_page_r
	eor #$FF
	sta video_page_r
	jmp video_page_apply
.endproc
