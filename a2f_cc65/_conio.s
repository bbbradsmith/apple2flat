; _conio
;
; C interface for conio.h
;
; Caveats:
;   cpeekc - will be invalid if current X position is past the edge of screen, only valid in text mode
;   cpeeks - only valid across a single line, maximum length <=40, only valid in text mode
; Unimplemented:
;   cpeekcolor
;   cursor
;   textcolor
;   bgcolor
;   bordercolor
;   chline
;   cvline
;   chlinexy
;   cvlinexy
;   cclear
;   cclearxy
;   screensize

.include "../a2f.inc"

.export _clrscr
.export _kbhit
.export _gotox
.export _gotoy
.export gotoxy
.export _gotoxy
.export _wherex
.export _wherey
.export _cputc
.export _cputcxy
.export _cgetc
.export _cpeekc
.export _cpeekrevers
.export _cpeeks
.export _revers

.import video_cls
.import draw_getpixel
.import text_out

.import text_inverse
.import video_text_x
.import video_text_y

.import popa
.import popptr1
.importzp ptr1
.importzp tmp1
.importzp tmp2
.importzp tmp3

; void clrscr (void)
_clrscr = video_cls

; unsigned char kbhit (void)
_kbhit:
	lda KBDATA
	rol
	lda #0
	tax
	rol
	rts

; internal gotoxy: X,Y on C-stack
gotoxy:
	jsr popa ; cc65 internal gotoxy expects Y on stack
; void gotoxy (unsigned char x, unsigned char y)
_gotoxy:
	sta video_text_y
	jsr popa
; void gotox (unsigned char x)
_gotox:
	sta video_text_x
	rts

; void gotoy (unsigned char y)
.proc _gotoy
	sta video_text_y
	rts
.endproc

; unsigned char wherex (void)
.proc _wherex
	ldx #0
	lda video_text_x
	rts
.endproc

; unsigned char wherey (void)
.proc _wherey
	ldx #0
	lda video_text_y
	rts
.endproc

; void cputc (char c)
_cputc = text_out

; void cputcxy (unsigned char x, unsigned char y, char c)
.proc _cputcxy
	pha
	jsr popa
	sta video_text_y
	jsr popa
	sta video_text_x
	pla
	jmp text_out
.endproc

; char cgetc (void)
_cgetc:
:
	lda KBDATA
	bpl :- ; wait until new keypress
	bit KBSTAT ; clear new key flag
	ldx #0
	and #$7F ; return low 7 data bits as keypress
	rts

; char cpeekc (void)
.proc _cpeekc
	ldx video_text_x
	ldy video_text_y
	jsr draw_getpixel
	and #$7F
	ldx #0
	rts
.endproc

; unsigned char cpeekrevers (void)
.proc _cpeekrevers
	ldx video_text_x
	ldy video_text_y
	jsr draw_getpixel
	ldx #0
	rol
	rol
	eor #1
	and #1 ; high bit clear indicates reverse or flashing
	rts
.endproc

;void cpeeks (char* s, unsigned int length)
.proc _cpeeks
	; ptr1 = s
	; tmp1 = length
	; tmp3 = current position
	; tmp2 = current X
	sta tmp1
	jsr popptr1
	lda video_text_x
	sta tmp2
	lda tmp1
	beq :++
	ldy #0
	:
		sty tmp3
		ldx tmp2
		ldy video_text_y
		jsr draw_getpixel
		and #$7F
		ldy tmp3
		sta (ptr1), Y
		inc tmp2
		iny
		cpy tmp1
		bcc :-
	:
	lda #0
	sta (ptr1), Y
	rts
.endproc

;unsigned char revers (unsigned char onoff)
.proc _revers
	pha
	lda text_inverse
	eor #$80
	rol
	pla
	beq :+
		lda #$80
	:
	eor #$80
	sta text_inverse
	lda #0
	tax
	rol
	rts
.endproc
