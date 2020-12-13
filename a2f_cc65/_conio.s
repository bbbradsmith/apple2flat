; _conio

; C interface for conio.h
; TODO very incomplete

.export _clrscr
.export _gotox
.export _gotoy
.export gotoxy
.export _gotoxy
.export _wherex
.export _wherey
.export _cputc
.export _cputcxy

.import video_cls
.import text_out

.import video_text_x
.import video_text_y

.import popa

; void clrscr (void)
_clrscr = video_cls

; unsigned char kbhit (void)
; TODO

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

	jmp _gotox

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
; TODO

; char cpeekc (void)
; TODO ?
; Return the character from the current cursor position

; unsigned char cpeekcolor (void)
.proc _cpeekcolor
	ldx #0
	txa
	rts
.endproc

; unsigned char cpeekrevers (void)
; TODO ?

;void __fastcall__ cpeeks (char* s, unsigned int length);
; Return a string of the characters that start at the current cursor position.
; Put the string into the buffer to which "s" points.  The string will have
; "length" characters, then will be 0-terminated.

;unsigned char __fastcall__ cursor (unsigned char onoff);
; If onoff is 1, a cursor is displayed when waiting for keyboard input. If
; onoff is 0, the cursor is hidden when waiting for keyboard input. The
; function returns the old cursor setting.
; TODO "_cursor" is implemented in a shared lib, "cursor" is a data byte to store the state

;unsigned char __fastcall__ revers (unsigned char onoff);
; Enable/disable reverse character display. This may not be supported by
; the output device. Return the old setting.

;unsigned char __fastcall__ textcolor (unsigned char color);
; Set the color for text output. The old color setting is returned.

;unsigned char __fastcall__ bgcolor (unsigned char color);
; Set the color for the background. The old color setting is returned.

;unsigned char __fastcall__ bordercolor (unsigned char color);
; Set the color for the border. The old color setting is returned.

;void __fastcall__ chline (unsigned char length);
; Output a horizontal line with the given length starting at the current
; cursor position.

;void __fastcall__ chlinexy (unsigned char x, unsigned char y, unsigned char length);
; Same as gotoxy (x, y); chline (length);

;void __fastcall__ cvline (unsigned char length);
; Output a vertical line with the given length at the current cursor
; position.

;void __fastcall__ cvlinexy (unsigned char x, unsigned char y, unsigned char length);
; Same as gotoxy (x, y); cvline (length);

;void __fastcall__ cclear (unsigned char length);
; Clear part of a line (write length spaces).

;void __fastcall__ cclearxy (unsigned char x, unsigned char y, unsigned char length);
; Same as gotoxy (x, y); cclear (length);

;void __fastcall__ screensize (unsigned char* x, unsigned char* y);
; Return the current screen size.

; Macros (see comment in conio.h about these?)
;#ifdef _textcolor
;#  define textcolor(color)      _textcolor(color)
;#endif
;#ifdef _bgcolor
;#  define bgcolor(color)        _bgcolor(color)
;#endif
;#ifdef _bordercolor
;#  define bordercolor(color)    _bordercolor(color)
;#endif
;#ifdef _cpeekcolor
;#  define cpeekcolor()          _cpeekcolor()
;#endif
;#ifdef _cpeekrevers
;#  define cpeekrevers()         _cpeekrevers()
;#endif
