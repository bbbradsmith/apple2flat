; _text_font_vwf
;
; C access to text_font_vwf

.export _text_fontset_width
.export _text_set_font_vwf

.import _text_set_font
.import popax

.import text_fontset_width

_text_fontset_width = text_fontset_width

; void text_set_font_vwf(const uint8* width, const uint8* fontset, uint8 offset)
_text_set_font_vwf:
	jsr _text_set_font
	jsr popax
	sta text_fontset_width+0
	stx text_fontset_width+1
	rts
