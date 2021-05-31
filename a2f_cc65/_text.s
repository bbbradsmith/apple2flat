; _text
;
; C access for text

.export _video_text_x
.export _video_text_y
.export _video_text_w
.export _video_text_h
.export _video_text_xr
.export _video_text_yr
.export _text_inverse

.export _text_out
.export _text_outs
.export _text_printf
.export _text_vprintf
.export _text_scroll
.export _text_charset
.export _text_xy
.export _text_window

.import popa
.import _cprintf ; from conio
.import _vcprintf ; from conio
.import text_out
.import text_outs
.import text_scroll
.import text_charset

.import video_text_x
.import video_text_y
.import video_text_w
.import video_text_h
.import video_text_xr
.import video_text_yr
.import video_page_w
.import video_page_r
.import text_inverse

_video_text_x = video_text_x
_video_text_y = video_text_y
_video_text_w = video_text_w
_video_text_h = video_text_h
_video_text_xr = video_text_xr
_video_text_yr = video_text_yr
_text_inverse = text_inverse

; void text_out(char c)
_text_out = text_out

; void text_outs(const char* s)
_text_outs = text_outs

; void text_printf(const char* format, ...)
; void text_vprintf(const char* format, va_list ap)
_text_printf = _cprintf
_text_vprintf = _vcprintf
; cprintf/vcprintf is borrowed from conio, but bypasses the need for conio.h

; void text_scroll(sint8 lines)
_text_scroll = text_scroll

; void text_charset(char alt)
_text_charset = text_charset

; void text_xy(uint8 x, uint8 y)
_text_xy:
	sta video_text_y
	jsr popa
	sta video_text_x
	rts

; void text_window(uint8 x0, uint8 y0, uint8 x1, uint8 y1)
.proc _text_window
	sta video_text_h
	jsr popa
	sta video_text_w
	jsr popa
	sta video_text_yr
	jsr popa
	sta video_text_xr
	; make sure within bounds
	lda video_text_x
	cmp video_text_xr
	bcc reset_position
	cmp video_text_w
	bcs reset_position
	lda video_text_y
	cmp video_text_yr
	bcc reset_position
	cmp video_text_h
	bcs reset_position
	rts
reset_position:
	lda video_text_xr
	sta video_text_x
	lda video_text_yr
	sta video_text_y
	rts
.endproc
